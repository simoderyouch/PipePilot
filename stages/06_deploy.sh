#!/usr/bin/env bash
# Step 6 - Deploy / Local or Remote Deployment.
#
# This file moves the build output to the target environment. It supports local
# copies, rsync/scp remote deployment, pre/post hooks, restart commands, and
# dry-run simulations for safe production demonstrations.

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
    local remote_prefix=""
    [[ -n "$REMOTE_HOST" ]] || return "$ERR_DEPLOY"
    [[ -n "$REMOTE_USER" ]] && remote_prefix="${REMOTE_USER}@"

    if command -v rsync >/dev/null 2>&1; then
        rsync -az --delete "$source_dir"/ "${remote_prefix}${REMOTE_HOST}:$TARGET_PATH"/
    else
        scp -r "$source_dir"/. "${remote_prefix}${REMOTE_HOST}:$TARGET_PATH"/
    fi
}

stage_deploy() {
    log_info "[DEPLOY] Starting $ENVIRONMENT deployment"
    DEPLOY_STARTED=1

    run_hook "pre-deploy.sh" || return "$ERR_HOOK"

    local source_dir
    source_dir="$(deployment_source)"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[DEPLOY] Dry-run deployment from $source_dir to $TARGET_PATH"
    elif [[ -n "$REMOTE_HOST" ]]; then
        copy_remote "$source_dir" || return "$ERR_DEPLOY"
    else
        copy_local "$source_dir" || return "$ERR_DEPLOY"
    fi

    if [[ -n "$RESTART_SERVICE" ]]; then
        if [[ -n "$REMOTE_HOST" ]]; then
            local remote_prefix=""
            [[ -n "$REMOTE_USER" ]] && remote_prefix="${REMOTE_USER}@"
            run_cmd "[DEPLOY] Restart remote service" ssh "${remote_prefix}${REMOTE_HOST}" "systemctl restart $RESTART_SERVICE" || return "$ERR_DEPLOY"
        else
            run_cmd "[DEPLOY] Restart local service" systemctl restart "$RESTART_SERVICE" || return "$ERR_DEPLOY"
        fi
    fi

    run_hook "post-deploy.sh" || return "$ERR_HOOK"
    log_info "[DEPLOY] ${ENVIRONMENT^} deployment completed successfully"
    return "$OK"
}

