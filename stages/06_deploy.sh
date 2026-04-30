#!/usr/bin/env bash
# Step 6 - Deploy / Local or Remote Deployment.
#
# This file moves the build output to the target environment. It supports both
# local deployment and explicit SSH remote deployment with --remote, --host,
# --user, --key, --target, --deploy-dir, --remote-cmd, --restart, and
# --transfer.

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
