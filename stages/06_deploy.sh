#!/usr/bin/env bash
# Step 6 - Deploy / Local or Remote Deployment.
#
# This file moves the build output to the target environment. It supports both
# local deployment, explicit SSH remote deployment, and optional fresh-server
# provisioning with --setup-server.

run_hook() {
    local hook_name="$1"
    local hook_path="$SCRIPT_DIR/hooks/$hook_name"
    if [[ -x "$hook_path" ]]; then
        run_cmd "[HOOK] Running $hook_name" "$hook_path" || return "$ERR_HOOK"
    else
        log_info "[HOOK] $hook_name not executable or not present; skipping"
    fi
}

deployment_source() {
    # --deploy-dir lets users upload a specific build output such as dist/,
    # build/, public/, or any custom folder created by the build step.
    if [[ -n "$DEPLOY_DIR" ]]; then
        if [[ "$DEPLOY_DIR" = /* ]]; then
            echo "$DEPLOY_DIR"
        else
            echo "$PROJECT_PATH/$DEPLOY_DIR"
        fi
        return 0
    fi

    if [[ -d "$PROJECT_PATH/build" ]]; then
        echo "$PROJECT_PATH/build"
    elif [[ -d "$PROJECT_PATH/dist" ]]; then
        echo "$PROJECT_PATH/dist"
    elif [[ -d "$PROJECT_PATH/public" ]]; then
        echo "$PROJECT_PATH/public"
    else
        echo "$PROJECT_PATH"
    fi
}

copy_local() {
    local source_dir="$1"
    mkdir -p "$TARGET_PATH"
    if command -v rsync >/dev/null 2>&1; then
        rsync -a --delete "$source_dir"/ "$TARGET_PATH"/
    else
        cp -a "$source_dir"/. "$TARGET_PATH"/
    fi
}

copy_remote() {
    local source_dir="$1"
    local remote="${REMOTE_USER}@${REMOTE_HOST}"

    ssh_remote "mkdir -p '$TARGET_PATH'" || return "$ERR_DEPLOY"

    if [[ "$TRANSFER_TOOL" == "rsync" ]]; then
        require_command rsync "$ERR_DEPENDENCY"
        rsync -avz --delete -e "ssh -i $REMOTE_KEY -p $SSH_PORT" "$source_dir"/ "$remote:$TARGET_PATH"/
    else
        require_command scp "$ERR_DEPENDENCY"
        scp -i "$REMOTE_KEY" -P "$SSH_PORT" -r "$source_dir"/. "$remote:$TARGET_PATH"/
    fi
}

ssh_remote() {
    # Helper for all remote commands. The remote command is passed as a single
    # string so users can provide normal shell commands through --remote-cmd.
    local command_text="$1"
    require_command ssh "$ERR_DEPENDENCY"
    ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "$command_text"
}

ssh_remote_script() {
    # Send a multi-line Bash script through SSH. This is used for fresh-server
    # setup because package-manager detection and conditional nginx setup are
    # easier to read as a script than as one long command line.
    local script_text="$1"
    require_command ssh "$ERR_DEPENDENCY"
    ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "bash -s" <<< "$script_text"
}

validate_remote_config() {
    [[ "$REMOTE_MODE" -eq 1 ]] || return "$OK"

    [[ -n "$REMOTE_HOST" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --host"
    [[ -n "$REMOTE_USER" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --user"
    [[ -n "$REMOTE_KEY" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --key"
    [[ "$CLI_TARGET_SET" -eq 1 ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --target"
    [[ -n "$TARGET_PATH" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --target"

    [[ -f "$REMOTE_KEY" ]] || die "$ERR_PROJECT_NOT_FOUND" "[REMOTE] SSH key not found: $REMOTE_KEY"

    if [[ "$TRANSFER_TOOL" != "rsync" && "$TRANSFER_TOOL" != "scp" ]]; then
        die "$ERR_UNKNOWN_OPTION" "[REMOTE] Invalid transfer tool: $TRANSFER_TOOL"
    fi

    if [[ -n "$DEPLOY_DIR" ]]; then
        local source_dir
        source_dir="$(deployment_source)"
        [[ -d "$source_dir" ]] || die "$ERR_DEPLOY" "[REMOTE] Deploy directory not found: $source_dir"
    fi
}

effective_app_kind() {
    # `auto` turns the local project detection into a deployment-oriented kind.
    # For example, a Node project that uploads dist/ is usually a frontend,
    # while a Node project with an app port is usually a backend service.
    if [[ "$APP_KIND" != "auto" ]]; then
        echo "$APP_KIND"
        return 0
    fi

    if [[ -n "$DEPLOY_DIR" && "$DEPLOY_DIR" =~ (^|/)(dist|build|public)$ ]]; then
        echo "frontend"
    elif [[ -n "$APP_PORT" && "$PROJECT_TYPE" == "node" ]]; then
        echo "node"
    elif [[ "$PROJECT_TYPE" == "node" ]]; then
        echo "frontend"
    elif [[ "$PROJECT_TYPE" == "python" ]]; then
        echo "python"
    elif [[ "$PROJECT_TYPE" == "c" ]]; then
        echo "c"
    elif [[ "$PROJECT_TYPE" == "shell" || "$PROJECT_TYPE" == "generic" ]]; then
        echo "generic"
    else
        echo "generic"
    fi
}

setup_package_list() {
    local kind="$1"
    case "$kind" in
        static|frontend)
            echo "nginx rsync curl"
            ;;
        node)
            echo "nodejs npm rsync curl"
            ;;
        python)
            echo "python3 python3-pip python3-venv rsync curl"
            ;;
        c)
            echo "build-essential make gcc rsync curl"
            ;;
        generic)
            echo "rsync curl"
            ;;
    esac
}

setup_remote_server() {
    [[ "$SETUP_SERVER" -eq 1 ]] || return "$OK"

    local kind packages server_name proxy_port setup_cmd target_path package_manager remote_user
    local kind_q packages_q server_name_q proxy_port_q setup_cmd_q target_path_q package_manager_q remote_user_q
    kind="$(effective_app_kind)"
    packages="$(setup_package_list "$kind")"
    server_name="${DOMAIN_NAME:-_}"
    proxy_port="$APP_PORT"
    setup_cmd="$SETUP_CMD"
    target_path="$TARGET_PATH"
    package_manager="$PACKAGE_MANAGER"
    remote_user="$REMOTE_USER"

    printf -v kind_q '%q' "$kind"
    printf -v packages_q '%q' "$packages"
    printf -v server_name_q '%q' "$server_name"
    printf -v proxy_port_q '%q' "$proxy_port"
    printf -v setup_cmd_q '%q' "$setup_cmd"
    printf -v target_path_q '%q' "$target_path"
    printf -v package_manager_q '%q' "$package_manager"
    printf -v remote_user_q '%q' "$remote_user"

    log_info "[SETUP] Fresh-server setup started -- kind $kind -- packages: $packages"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] [SETUP] Would install packages on $REMOTE_HOST: $packages"
        log_info "[DRY-RUN] [SETUP] Would create target directory: $target_path"
        if [[ "$kind" == "static" || "$kind" == "frontend" || -n "$proxy_port" ]]; then
            log_info "[DRY-RUN] [SETUP] Would configure nginx for ${server_name}"
        fi
        [[ -z "$setup_cmd" ]] || log_info "[DRY-RUN] [SETUP] Extra setup command: $setup_cmd"
        return "$OK"
    fi

    ssh_remote_script "$(cat <<SETUP
set -euo pipefail

APP_KIND=$kind_q
PACKAGES=$packages_q
TARGET_PATH=$target_path_q
REMOTE_USER_NAME=$remote_user_q
SERVER_NAME=$server_name_q
APP_PORT_VALUE=$proxy_port_q
PACKAGE_MANAGER_CHOICE=$package_manager_q
EXTRA_SETUP_CMD=$setup_cmd_q

if [ "\$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

detect_pm() {
    if [ "\$PACKAGE_MANAGER_CHOICE" != "auto" ]; then
        echo "\$PACKAGE_MANAGER_CHOICE"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v dnf >/dev/null 2>&1; then
        echo "dnf"
    elif command -v yum >/dev/null 2>&1; then
        echo "yum"
    elif command -v apk >/dev/null 2>&1; then
        echo "apk"
    else
        echo "unknown"
    fi
}

install_packages() {
    pm="\$(detect_pm)"
    case "\$APP_KIND:\$pm" in
        c:apt) PACKAGES="build-essential make gcc rsync curl" ;;
        c:dnf|c:yum) PACKAGES="gcc gcc-c++ make rsync curl" ;;
        c:apk) PACKAGES="build-base rsync curl" ;;
        python:apk) PACKAGES="python3 py3-pip py3-virtualenv rsync curl" ;;
    esac

    case "\$pm" in
        apt)
            \$SUDO apt-get update -y
            DEBIAN_FRONTEND=noninteractive \$SUDO apt-get install -y \$PACKAGES
            ;;
        dnf)
            \$SUDO dnf install -y \$PACKAGES
            ;;
        yum)
            \$SUDO yum install -y \$PACKAGES
            ;;
        apk)
            \$SUDO apk add --no-cache \$PACKAGES
            ;;
        *)
            echo "No supported package manager found" >&2
            exit 113
            ;;
    esac
}

configure_nginx() {
    if ! command -v nginx >/dev/null 2>&1; then
        return 0
    fi

    if [ -n "\$APP_PORT_VALUE" ]; then
        NGINX_BODY="server {
    listen 80;
    server_name \$SERVER_NAME;

    location / {
        proxy_pass http://127.0.0.1:\$APP_PORT_VALUE;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \\\$host;
        proxy_cache_bypass \\\$http_upgrade;
    }
}"
    elif [ "\$APP_KIND" = "static" ] || [ "\$APP_KIND" = "frontend" ]; then
        NGINX_BODY="server {
    listen 80;
    server_name \$SERVER_NAME;
    root \$TARGET_PATH;
    index index.html;

    location / {
        try_files \\\$uri \\\$uri/ /index.html;
    }
}"
    else
        return 0
    fi

    if [ -d /etc/nginx/sites-available ]; then
        CONF_NAME="pipepilot-\$(echo "\$SERVER_NAME" | tr -c 'A-Za-z0-9_.-' '_')"
        echo "\$NGINX_BODY" | \$SUDO tee "/etc/nginx/sites-available/\$CONF_NAME" >/dev/null
        \$SUDO ln -sf "/etc/nginx/sites-available/\$CONF_NAME" "/etc/nginx/sites-enabled/\$CONF_NAME"
        \$SUDO nginx -t
        \$SUDO systemctl reload nginx || \$SUDO service nginx reload || true
    elif [ -d /etc/nginx/conf.d ]; then
        CONF_NAME="pipepilot-\$(echo "\$SERVER_NAME" | tr -c 'A-Za-z0-9_.-' '_').conf"
        echo "\$NGINX_BODY" | \$SUDO tee "/etc/nginx/conf.d/\$CONF_NAME" >/dev/null
        \$SUDO nginx -t
        \$SUDO systemctl reload nginx || \$SUDO service nginx reload || true
    fi
}

install_packages
\$SUDO mkdir -p "\$TARGET_PATH"
\$SUDO chown -R "\$REMOTE_USER_NAME":"\$REMOTE_USER_NAME" "\$TARGET_PATH" 2>/dev/null || true
configure_nginx

if [ -n "\$EXTRA_SETUP_CMD" ]; then
    bash -lc "\$EXTRA_SETUP_CMD"
fi
SETUP
)" || return "$ERR_DEPLOY"

    log_info "[SETUP] Fresh-server setup completed -- kind $kind"
    return "$OK"
}

stage_deploy() {
    log_info "[DEPLOY] Starting $ENVIRONMENT deployment"
    DEPLOY_STARTED=1

    local source_dir
    source_dir="$(deployment_source)"

    if [[ ! -d "$source_dir" ]]; then
        log_error "[DEPLOY] Deploy source not found: $source_dir"
        rollback_after_failure
        return "$ERR_DEPLOY"
    fi

    if [[ "$REMOTE_MODE" -eq 1 ]]; then
        validate_remote_config
        log_info "[DEPLOY] Remote mode enabled -- ${REMOTE_USER}@${REMOTE_HOST}:$TARGET_PATH via $TRANSFER_TOOL"
        setup_remote_server || return "$ERR_DEPLOY"
    fi

    run_hook "pre-deploy.sh" || return "$ERR_HOOK"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DEPLOY] Dry-run deployment from $source_dir to $TARGET_PATH"
    elif [[ "$REMOTE_MODE" -eq 1 ]]; then
        copy_remote "$source_dir" || return "$ERR_DEPLOY"
    else
        copy_local "$source_dir" || return "$ERR_DEPLOY"
    fi

    if [[ "$REMOTE_MODE" -eq 1 && "$DRY_RUN" -eq 1 ]]; then
        log_info "[DEPLOY] Dry-run remote upload simulated for $REMOTE_HOST:$TARGET_PATH"
    elif [[ "$REMOTE_MODE" -eq 1 ]]; then
        log_info "[DEPLOY] Files uploaded to $REMOTE_HOST:$TARGET_PATH"
    fi

    if [[ -n "$REMOTE_CMD" ]]; then
        if [[ "$DRY_RUN" -eq 1 ]]; then
            log_info "[DRY-RUN] [DEPLOY] Remote command: $REMOTE_CMD"
            log_info "[DEPLOY] Remote command simulated successfully"
        else
            ssh_remote "$REMOTE_CMD" || return "$ERR_DEPLOY"
            log_info "[DEPLOY] Remote command executed successfully"
        fi
    fi

    if [[ -n "$RESTART_SERVICE" ]]; then
        if [[ "$REMOTE_MODE" -eq 1 ]]; then
            if [[ "$DRY_RUN" -eq 1 ]]; then
                log_info "[DRY-RUN] [DEPLOY] Restart remote service: $RESTART_SERVICE"
            else
                ssh_remote "sudo systemctl restart '$RESTART_SERVICE' || pm2 restart '$RESTART_SERVICE'" || return "$ERR_DEPLOY"
            fi
            log_info "[DEPLOY] Service restarted: $RESTART_SERVICE"
        else
            run_cmd "[DEPLOY] Restart local service" systemctl restart "$RESTART_SERVICE" || return "$ERR_DEPLOY"
        fi
    fi

    run_hook "post-deploy.sh" || return "$ERR_HOOK"
    log_info "[DEPLOY] ${ENVIRONMENT^} deployment completed successfully"
    return "$OK"
}
