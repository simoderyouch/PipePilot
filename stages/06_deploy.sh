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

docker_compose_file() {
    if [[ -n "$COMPOSE_FILE" ]]; then
        if [[ "$COMPOSE_FILE" = /* ]]; then
            if [[ -f "$COMPOSE_FILE" ]]; then
                echo "$COMPOSE_FILE"
                return 0
            fi
        else
            if [[ -f "$PROJECT_PATH/$COMPOSE_FILE" ]]; then
                echo "$PROJECT_PATH/$COMPOSE_FILE"
                return 0
            fi
        fi
        return 1
    fi

    local candidate
    for candidate in compose.yaml compose.yml docker-compose.yml docker-compose.yaml; do
        if [[ -f "$PROJECT_PATH/$candidate" ]]; then
            echo "$PROJECT_PATH/$candidate"
            return 0
        fi
    done

    return 1
}

relative_compose_file() {
    local compose_path="$1"
    if [[ "$compose_path" == "$PROJECT_PATH/"* ]]; then
        echo "${compose_path#"$PROJECT_PATH/"}"
    else
        echo "$compose_path"
    fi
}

project_uses_docker() {
    [[ "$PROJECT_TYPE" == "docker-compose" || "$PROJECT_TYPE" == "docker" ]] && return 0
    docker_compose_file >/dev/null 2>&1 && return 0
    [[ -f "$PROJECT_PATH/Dockerfile" || -f "$PROJECT_PATH/dockerfile" ]]
}

deployment_source() {
    # --deploy-dir lets users upload a specific build output such as dist/,
    # build/, out/, public/, or any custom folder created by the build step.
    if [[ -n "$DEPLOY_DIR" ]]; then
        if [[ "$DEPLOY_DIR" = /* ]]; then
            echo "$DEPLOY_DIR"
        else
            echo "$PROJECT_PATH/$DEPLOY_DIR"
        fi
        return 0
    fi

    if project_uses_docker; then
        echo "$PROJECT_PATH"
        return 0
    fi

    local candidate
    for candidate in dist build out public; do
        if [[ -d "$PROJECT_PATH/$candidate" && -f "$PROJECT_PATH/$candidate/index.html" ]]; then
            echo "$PROJECT_PATH/$candidate"
            return 0
        fi
    done

    for candidate in dist build out public; do
        if [[ -d "$PROJECT_PATH/$candidate" ]]; then
            echo "$PROJECT_PATH/$candidate"
            return 0
        fi
    done

    echo "$PROJECT_PATH"
}

copy_local() {
    local source_dir="$1"
    mkdir -p "$TARGET_PATH"
    if command -v rsync >/dev/null 2>&1; then
        if [[ "$VERBOSE" -eq 1 ]]; then
            rsync -a --delete "$source_dir"/ "$TARGET_PATH"/
        else
            raw_log_command rsync -a --delete "$source_dir"/ "$TARGET_PATH"/
            rsync -a --delete "$source_dir"/ "$TARGET_PATH"/ >> "$RAW_LOG_FILE" 2>&1
        fi
    else
        if [[ "$VERBOSE" -eq 1 ]]; then
            cp -a "$source_dir"/. "$TARGET_PATH"/
        else
            raw_log_command cp -a "$source_dir"/. "$TARGET_PATH"/
            cp -a "$source_dir"/. "$TARGET_PATH"/ >> "$RAW_LOG_FILE" 2>&1
        fi
    fi
}

copy_remote() {
    local source_dir="$1"
    local remote="${REMOTE_USER}@${REMOTE_HOST}"

    ssh_remote "mkdir -p '$TARGET_PATH'" || return "$ERR_DEPLOY"

    if [[ "$TRANSFER_TOOL" == "rsync" ]]; then
        require_command rsync "$ERR_DEPENDENCY"
        if [[ "$VERBOSE" -eq 1 ]]; then
            rsync -avz --delete -e "ssh -i $REMOTE_KEY -p $SSH_PORT" "$source_dir"/ "$remote:$TARGET_PATH"/
        else
            raw_log_command rsync -avz --delete -e "ssh -i $REMOTE_KEY -p $SSH_PORT" "$source_dir"/ "$remote:$TARGET_PATH"/
            rsync -avz --delete -e "ssh -i $REMOTE_KEY -p $SSH_PORT" "$source_dir"/ "$remote:$TARGET_PATH"/ >> "$RAW_LOG_FILE" 2>&1
        fi
    else
        require_command scp "$ERR_DEPENDENCY"
        if [[ "$VERBOSE" -eq 1 ]]; then
            scp -i "$REMOTE_KEY" -P "$SSH_PORT" -r "$source_dir"/. "$remote:$TARGET_PATH"/
        else
            raw_log_command scp -i "$REMOTE_KEY" -P "$SSH_PORT" -r "$source_dir"/. "$remote:$TARGET_PATH"/
            scp -i "$REMOTE_KEY" -P "$SSH_PORT" -r "$source_dir"/. "$remote:$TARGET_PATH"/ >> "$RAW_LOG_FILE" 2>&1
        fi
    fi
}

ssh_remote() {
    # Helper for all remote commands. The remote command is passed as a single
    # string so users can provide normal shell commands through --remote-cmd.
    local command_text="$1"
    require_command ssh "$ERR_DEPENDENCY"
    if [[ "$VERBOSE" -eq 1 ]]; then
        ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "$command_text"
    else
        raw_log_command ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "$command_text"
        ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "$command_text" >> "$RAW_LOG_FILE" 2>&1
    fi
}

ssh_remote_script() {
    # Send a multi-line Bash script through SSH.
    local script_text="$1"
    require_command ssh "$ERR_DEPENDENCY"
    if [[ "$VERBOSE" -eq 1 ]]; then
        ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "bash -s" <<< "$script_text"
    else
        raw_log_command ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "bash -s"
        ssh -i "$REMOTE_KEY" -p "$SSH_PORT" "${REMOTE_USER}@${REMOTE_HOST}" "bash -s" <<< "$script_text" >> "$RAW_LOG_FILE" 2>&1
    fi
}

remote_setup_helper() {
    echo "$SCRIPT_DIR/helpers/remote_setup.sh"
}

validate_remote_config() {
    [[ "$REMOTE_MODE" -eq 1 ]] || return "$OK"

    [[ -n "$REMOTE_HOST" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --host"
    [[ -n "$REMOTE_USER" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --user"
    [[ -n "$REMOTE_KEY" ]] || die "$ERR_MISSING_PARAMETER" "[REMOTE] Missing --key"
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

is_ip_host() {
    local host="$1"
    [[ "$host" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ || "$host" =~ ^[0-9A-Fa-f:]+$ ]]
}

safe_path_name() {
    local raw="$1"
    local safe
    safe="$(printf '%s' "$raw" | tr -c 'A-Za-z0-9_.-' '-' | sed 's/^-*//; s/-*$//')"
    echo "${safe:-pipepilot-app}"
}

effective_server_name() {
    if [[ -n "$DOMAIN_NAME" ]]; then
        echo "$DOMAIN_NAME"
    elif [[ -n "$REMOTE_HOST" ]]; then
        echo "$REMOTE_HOST"
    else
        echo "_"
    fi
}

smart_remote_target() {
    local kind="$1"
    local name

    if [[ "$kind" == "backend" || "$kind" == "stack" ]]; then
        name="$(safe_path_name "$(basename "$PROJECT_PATH")")"
        echo "/srv/$name"
        return 0
    fi

    if [[ -n "$DOMAIN_NAME" ]]; then
        name="$(safe_path_name "$DOMAIN_NAME")"
    elif [[ -n "$REMOTE_HOST" ]] && ! is_ip_host "$REMOTE_HOST"; then
        name="$(safe_path_name "$REMOTE_HOST")"
    else
        name="$(safe_path_name "$(basename "$PROJECT_PATH")")"
    fi

    echo "/var/www/$name"
}

relative_deploy_source() {
    local source_dir="$1"
    if [[ "$source_dir" == "$PROJECT_PATH" ]]; then
        echo "."
    elif [[ "$source_dir" == "$PROJECT_PATH/"* ]]; then
        echo "${source_dir#"$PROJECT_PATH/"}"
    else
        echo "$source_dir"
    fi
}

apply_smart_remote_defaults() {
    [[ "$REMOTE_MODE" -eq 1 ]] || return "$OK"

    local kind source_dir
    kind="$(effective_app_kind)"

    if [[ "$CLI_DOMAIN_SET" -eq 0 && -z "$DOMAIN_NAME" && -n "$REMOTE_HOST" ]] && ! is_ip_host "$REMOTE_HOST"; then
        DOMAIN_NAME="$REMOTE_HOST"
        log_info "[SMART] Domain inferred from remote host: $DOMAIN_NAME"
        status_line "[SMART] Domain: $DOMAIN_NAME"
    fi

    if [[ "$CLI_TARGET_SET" -eq 0 ]]; then
        TARGET_PATH="$(smart_remote_target "$kind")"
        log_info "[SMART] Remote target inferred: $TARGET_PATH"
        status_line "[SMART] target=$TARGET_PATH"
    fi

    if [[ "$CLI_DEPLOY_DIR_SET" -eq 0 ]]; then
        source_dir="$(deployment_source)"
        log_info "[SMART] Deploy source inferred: $(relative_deploy_source "$source_dir")"
        status_line "[SMART] deploy_source=$(relative_deploy_source "$source_dir")"
    fi

    if [[ "$CLI_SETUP_SERVER_SET" -eq 0 && "$SETUP_SERVER" -eq 0 ]]; then
        SETUP_SERVER=1
        log_info "[SMART] Remote server setup enabled automatically"
        status_line "[SMART] setup=enabled"
    fi
}

effective_app_kind() {
    # `auto` turns the local project detection into a deployment-oriented kind.
    # For example, a Node project that uploads dist/ is usually a frontend,
    # while a project with an app port is usually a backend service.
    if [[ "$APP_KIND" != "auto" ]]; then
        echo "$APP_KIND"
        return 0
    fi

    if project_uses_docker; then
        echo "stack"
    elif [[ -n "$DEPLOY_DIR" && "$DEPLOY_DIR" =~ (^|/)(dist|build|public)$ ]]; then
        echo "frontend"
    elif [[ -n "$APP_PORT" || "$PROJECT_TYPE" == "python" ]]; then
        echo "backend"
    elif [[ "$PROJECT_TYPE" == "node" ]]; then
        echo "frontend"
    else
        echo "frontend"
    fi
}

effective_backend_runtime() {
    if [[ "$BACKEND_RUNTIME" != "auto" ]]; then
        echo "$BACKEND_RUNTIME"
    elif docker_compose_file >/dev/null 2>&1; then
        echo "compose"
    elif [[ "$PROJECT_TYPE" == "docker" ]]; then
        echo "docker"
    elif [[ "$PROJECT_TYPE" == "python" ]]; then
        echo "python"
    elif [[ "$PROJECT_TYPE" == "node" ]]; then
        echo "node"
    else
        echo "node"
    fi
}

effective_app_port() {
    local runtime
    runtime="$(effective_backend_runtime)"
    if [[ -n "$APP_PORT" ]]; then
        echo "$APP_PORT"
    elif [[ "$runtime" == "python" ]]; then
        echo "8000"
    else
        echo "3000"
    fi
}

detect_node_start_command() {
    if [[ -n "$START_CMD" ]]; then
        echo "$START_CMD"
    elif [[ -f "$PROJECT_PATH/package.json" ]] && grep -q '"start"[[:space:]]*:' "$PROJECT_PATH/package.json"; then
        echo "npm start"
    elif [[ -f "$PROJECT_PATH/server.js" ]]; then
        echo "node server.js"
    elif [[ -f "$PROJECT_PATH/app.js" ]]; then
        echo "node app.js"
    elif [[ -f "$PROJECT_PATH/index.js" ]]; then
        echo "node index.js"
    elif [[ -f "$PROJECT_PATH/main.js" ]]; then
        echo "node main.js"
    else
        echo "npm start"
    fi
}

detect_python_start_command() {
    local port module file
    port="$(effective_app_port)"

    if [[ -n "$START_CMD" ]]; then
        echo "$START_CMD"
        return 0
    fi

    for file in "$PROJECT_PATH/main.py" "$PROJECT_PATH/app.py"; do
        [[ -f "$file" ]] || continue
        module="$(basename "$file" .py)"
        if grep -q "FastAPI(" "$file"; then
            echo ".venv/bin/python -m uvicorn ${module}:app --host 0.0.0.0 --port $port"
            return 0
        fi
        if grep -q "Flask(" "$file"; then
            echo ".venv/bin/python -m flask --app ${module} run --host 0.0.0.0 --port $port"
            return 0
        fi
    done

    if [[ -f "$PROJECT_PATH/app.py" ]]; then
        echo ".venv/bin/python app.py"
    elif [[ -f "$PROJECT_PATH/main.py" ]]; then
        echo ".venv/bin/python main.py"
    else
        echo ".venv/bin/python app.py"
    fi
}

detect_backend_start_command() {
    case "$(effective_backend_runtime)" in
        python) detect_python_start_command ;;
        node) detect_node_start_command ;;
    esac
}

effective_service_name() {
    local raw_name
    if [[ -n "$SERVICE_NAME" ]]; then
        raw_name="$SERVICE_NAME"
    else
        raw_name="pipepilot-$(basename "$PROJECT_PATH")"
    fi
    printf '%s' "$raw_name" | tr -c 'A-Za-z0-9_.-' '-'
}

setup_package_list() {
    local kind="$1"
    local runtime="$2"
    case "$kind" in
        frontend)
            echo "nginx rsync curl"
            ;;
        backend)
            if [[ "$runtime" == "compose" || "$runtime" == "docker" ]]; then
                echo "docker.io nginx rsync curl"
            elif [[ "$runtime" == "python" ]]; then
                echo "python3 python3-pip python3-venv nginx rsync curl"
            else
                echo "nodejs npm nginx rsync curl"
            fi
            ;;
        stack)
            echo "docker.io rsync curl"
            ;;
    esac
}

setup_remote_server() {
    [[ "$SETUP_SERVER" -eq 1 ]] || return "$OK"

    local kind runtime packages server_name proxy_port setup_cmd target_path package_manager remote_user helper_path setup_env
    local kind_q runtime_q packages_q server_name_q proxy_port_q setup_cmd_q target_path_q package_manager_q remote_user_q
    kind="$(effective_app_kind)"
    if [[ "$kind" == "backend" || "$kind" == "stack" ]]; then
        runtime="$(effective_backend_runtime)"
    else
        runtime="none"
    fi
    packages="$(setup_package_list "$kind" "$runtime")"
    server_name="$(effective_server_name)"
    if [[ "$kind" == "backend" ]]; then
        proxy_port="$(effective_app_port)"
    elif [[ "$kind" == "stack" ]]; then
        if [[ -n "$APP_PORT" ]]; then
            proxy_port="$APP_PORT"
        elif docker_compose_file >/dev/null 2>&1; then
            proxy_port=""
        else
            proxy_port="$(effective_app_port)"
        fi
    else
        proxy_port="$APP_PORT"
    fi
    setup_cmd="$SETUP_CMD"
    target_path="$TARGET_PATH"
    package_manager="$PACKAGE_MANAGER"
    remote_user="$REMOTE_USER"

    printf -v kind_q '%q' "$kind"
    printf -v runtime_q '%q' "$runtime"
    printf -v packages_q '%q' "$packages"
    printf -v server_name_q '%q' "$server_name"
    printf -v proxy_port_q '%q' "$proxy_port"
    printf -v setup_cmd_q '%q' "$setup_cmd"
    printf -v target_path_q '%q' "$target_path"
    printf -v package_manager_q '%q' "$package_manager"
    printf -v remote_user_q '%q' "$remote_user"
    helper_path="$(remote_setup_helper)"
    [[ -f "$helper_path" ]] || die "$ERR_PROJECT_NOT_FOUND" "[SETUP] Remote setup helper not found: $helper_path"

    setup_env="$(cat <<SETUP_ENV
APP_KIND=$kind_q
BACKEND_RUNTIME_VALUE=$runtime_q
PACKAGES=$packages_q
TARGET_PATH=$target_path_q
REMOTE_USER_NAME=$remote_user_q
SERVER_NAME=$server_name_q
APP_PORT_VALUE=$proxy_port_q
PACKAGE_MANAGER_CHOICE=$package_manager_q
EXTRA_SETUP_CMD=$setup_cmd_q
SETUP_ENV
)"

    log_info "[SETUP] Fresh-server setup started -- kind $kind -- runtime $runtime -- packages: $packages"
    status_line "[SETUP] app_kind=$kind runtime=$runtime packages=\"$packages\""
    status_line "[SETUP] target=$target_path server_name=$server_name"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] [SETUP] Would install packages on $REMOTE_HOST: $packages"
        log_info "[DRY-RUN] [SETUP] Would create target directory: $target_path"
        if [[ "$kind" == "frontend" || -n "$proxy_port" ]]; then
            log_info "[DRY-RUN] [SETUP] Would configure nginx for ${server_name}"
            status_line "[SETUP] dry-run: would install packages, create target, and configure nginx"
        else
            status_line "[SETUP] dry-run: would install packages and create target"
        fi
        [[ -z "$setup_cmd" ]] || log_info "[DRY-RUN] [SETUP] Extra setup command: $setup_cmd"
        return "$OK"
    fi

    ssh_remote_script "$setup_env"$'\n'"$(< "$helper_path")" || return "$ERR_DEPLOY"

    log_info "[SETUP] Fresh-server setup completed -- kind $kind"
    status_ok "Remote setup completed"
    return "$OK"
}

configure_docker_runtime() {
    [[ "$REMOTE_MODE" -eq 1 ]] || return "$OK"
    project_uses_docker || return "$OK"

    local runtime compose_path compose_file service_name target_path port
    local runtime_q compose_file_q service_name_q target_path_q port_q
    runtime="$(effective_backend_runtime)"
    compose_path="$(docker_compose_file || true)"
    if [[ -n "$compose_path" ]]; then
        runtime="compose"
        compose_file="$(relative_compose_file "$compose_path")"
    else
        runtime="docker"
        compose_file=""
    fi
    service_name="$(effective_service_name)"
    target_path="$TARGET_PATH"
    port="$(effective_app_port)"

    printf -v runtime_q '%q' "$runtime"
    printf -v compose_file_q '%q' "$compose_file"
    printf -v service_name_q '%q' "$service_name"
    printf -v target_path_q '%q' "$target_path"
    printf -v port_q '%q' "$port"

    if [[ "$runtime" == "compose" ]]; then
        log_info "[DOCKER] Runtime detected -- compose -- file: $compose_file"
        status_line "[DOCKER] runtime=compose file=$compose_file"
    else
        log_info "[DOCKER] Runtime detected -- dockerfile -- image/service: $service_name -- port: $port"
        status_line "[DOCKER] runtime=dockerfile service=$service_name port=$port"
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        if [[ "$runtime" == "compose" ]]; then
            log_info "[DRY-RUN] [DOCKER] Would run docker compose up -d --build in $target_path"
        else
            log_info "[DRY-RUN] [DOCKER] Would build Dockerfile and restart container $service_name on port $port"
        fi
        return "$OK"
    fi

    ssh_remote_script "$(cat <<DOCKER
set -euo pipefail

DOCKER_RUNTIME_VALUE=$runtime_q
COMPOSE_FILE_VALUE=$compose_file_q
SERVICE_NAME_VALUE=$service_name_q
TARGET_PATH=$target_path_q
APP_PORT_VALUE=$port_q

if [ "\$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

cd "\$TARGET_PATH"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is not installed on the remote host" >&2
    exit 113
fi

\$SUDO systemctl enable docker >/dev/null 2>&1 || true
\$SUDO systemctl start docker >/dev/null 2>&1 || true

compose_cmd() {
    if docker compose version >/dev/null 2>&1; then
        echo "docker compose"
    elif command -v docker-compose >/dev/null 2>&1; then
        echo "docker-compose"
    else
        return 1
    fi
}

if [ "\$DOCKER_RUNTIME_VALUE" = "compose" ]; then
    COMPOSE_CMD="\$(compose_cmd)" || {
        echo "Docker Compose is not installed on the remote host" >&2
        exit 113
    }
    \$SUDO \$COMPOSE_CMD -f "\$COMPOSE_FILE_VALUE" up -d --build --remove-orphans
else
    DOCKERFILE="Dockerfile"
    if [ ! -f "\$DOCKERFILE" ] && [ -f dockerfile ]; then
        DOCKERFILE="dockerfile"
    fi
    \$SUDO docker build -f "\$DOCKERFILE" -t "\$SERVICE_NAME_VALUE:latest" .
    \$SUDO docker rm -f "\$SERVICE_NAME_VALUE" >/dev/null 2>&1 || true
    \$SUDO docker run -d \\
        --name "\$SERVICE_NAME_VALUE" \\
        --restart unless-stopped \\
        -p "\$APP_PORT_VALUE:\$APP_PORT_VALUE" \\
        -e PORT="\$APP_PORT_VALUE" \\
        "\$SERVICE_NAME_VALUE:latest"
fi
DOCKER
)" || return "$ERR_DEPLOY"

    log_info "[DOCKER] Docker runtime configured and restarted"
    return "$OK"
}

configure_backend_runtime() {
    local kind runtime port start_cmd service_name target_path remote_user
    local runtime_q port_q start_cmd_q service_name_q target_path_q remote_user_q
    kind="$(effective_app_kind)"
    [[ "$REMOTE_MODE" -eq 1 && "$kind" == "backend" ]] || return "$OK"
    project_uses_docker && return "$OK"

    runtime="$(effective_backend_runtime)"
    port="$(effective_app_port)"
    start_cmd="$(detect_backend_start_command)"
    service_name="$(effective_service_name)"
    target_path="$TARGET_PATH"
    remote_user="$REMOTE_USER"

    printf -v runtime_q '%q' "$runtime"
    printf -v port_q '%q' "$port"
    printf -v start_cmd_q '%q' "$start_cmd"
    printf -v service_name_q '%q' "$service_name"
    printf -v target_path_q '%q' "$target_path"
    printf -v remote_user_q '%q' "$remote_user"

    log_info "[BACKEND] Runtime detected -- $runtime -- command: $start_cmd -- service: $service_name"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DRY-RUN] [BACKEND] Would install production dependencies in $target_path"
        log_info "[DRY-RUN] [BACKEND] Would create/restart systemd service $service_name on port $port"
        return "$OK"
    fi

    ssh_remote_script "$(cat <<BACKEND
set -euo pipefail

BACKEND_RUNTIME_VALUE=$runtime_q
APP_PORT_VALUE=$port_q
START_COMMAND=$start_cmd_q
SERVICE_NAME_VALUE=$service_name_q
TARGET_PATH=$target_path_q
REMOTE_USER_NAME=$remote_user_q

if [ "\$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

cd "\$TARGET_PATH"

if [ "\$BACKEND_RUNTIME_VALUE" = "node" ]; then
    if [ -f package-lock.json ]; then
        npm ci --omit=dev
    elif [ -f package.json ]; then
        npm install --omit=dev
    fi
else
    python3 -m venv .venv
    .venv/bin/python -m pip install --upgrade pip
    if [ -f requirements.txt ]; then
        .venv/bin/pip install -r requirements.txt
    fi
fi

if command -v systemctl >/dev/null 2>&1; then
    SERVICE_FILE="/etc/systemd/system/\$SERVICE_NAME_VALUE.service"
    \$SUDO tee "\$SERVICE_FILE" >/dev/null <<SERVICE
[Unit]
Description=PipePilot backend service \$SERVICE_NAME_VALUE
After=network.target

[Service]
Type=simple
User=\$REMOTE_USER_NAME
WorkingDirectory=\$TARGET_PATH
Environment=PORT=\$APP_PORT_VALUE
Environment=NODE_ENV=production
Environment=PYTHONUNBUFFERED=1
ExecStart=/bin/bash -lc '\$START_COMMAND'
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE
    \$SUDO systemctl daemon-reload
    \$SUDO systemctl enable "\$SERVICE_NAME_VALUE"
    \$SUDO systemctl restart "\$SERVICE_NAME_VALUE"
else
    nohup bash -lc "cd '\$TARGET_PATH' && PORT='\$APP_PORT_VALUE' \$START_COMMAND" > "\$TARGET_PATH/pipepilot-backend.log" 2>&1 &
fi
BACKEND
)" || return "$ERR_DEPLOY"

    log_info "[BACKEND] Backend service configured and restarted -- $service_name"
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
        apply_smart_remote_defaults
        validate_remote_config
        log_info "[DEPLOY] Remote mode enabled -- ${REMOTE_USER}@${REMOTE_HOST}:$TARGET_PATH via $TRANSFER_TOOL"
        status_line "[DEPLOY] remote=${REMOTE_USER}@${REMOTE_HOST} transfer=$TRANSFER_TOOL"
        setup_remote_server || return "$ERR_DEPLOY"
    fi

    run_hook "pre-deploy.sh" || return "$ERR_HOOK"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DEPLOY] Dry-run deployment from $source_dir to $TARGET_PATH"
        if [[ "$REMOTE_MODE" -eq 1 ]]; then
            configure_docker_runtime || return "$ERR_DEPLOY"
            configure_backend_runtime || return "$ERR_DEPLOY"
        fi
    elif [[ "$REMOTE_MODE" -eq 1 ]]; then
        copy_remote "$source_dir" || return "$ERR_DEPLOY"
        configure_docker_runtime || return "$ERR_DEPLOY"
        configure_backend_runtime || return "$ERR_DEPLOY"
    else
        copy_local "$source_dir" || return "$ERR_DEPLOY"
    fi

    if [[ "$REMOTE_MODE" -eq 1 && "$DRY_RUN" -eq 1 ]]; then
        log_info "[DEPLOY] Dry-run remote upload simulated for $REMOTE_HOST:$TARGET_PATH"
    elif [[ "$REMOTE_MODE" -eq 1 ]]; then
        log_info "[DEPLOY] Files uploaded to $REMOTE_HOST:$TARGET_PATH"
        status_ok "Uploaded files to $REMOTE_HOST:$TARGET_PATH"
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
