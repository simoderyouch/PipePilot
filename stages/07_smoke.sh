#!/usr/bin/env bash
# Step 7 - Smoke Test / Post-Deployment Verification.
#
# This file verifies the deployed app with a URL or port check. If verification
# fails, it asks the rollback system in the main orchestrator to restore the
# latest archive.

smoke_url() {
    if [[ -n "$SMOKE_URL" ]]; then
        echo "$SMOKE_URL"
    elif [[ -n "$REMOTE_HOST" ]]; then
        local host path
        host="${DOMAIN_NAME:-$REMOTE_HOST}"
        path="$HEALTH_PATH"
        if [[ -z "$path" || "$path" == "/" ]]; then
            echo "http://$host"
        elif [[ "$path" == /* ]]; then
            echo "http://$host$path"
        else
            echo "http://$host/$path"
        fi
    else
        echo ""
    fi
}

stage_smoke() {
    log_info "[SMOKE] Starting post-deployment verification"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        log_info "[SMOKE] Dry-run smoke test skipped"
        return "$OK"
    fi

    local attempt url
    url="$(smoke_url)"
    [[ -z "$url" ]] || status_line "[SMOKE] url=$url retries=$RETRIES timeout=${TIMEOUT}s"
    [[ -z "$SMOKE_PORT" ]] || status_line "[SMOKE] port=$SMOKE_PORT retries=$RETRIES timeout=${TIMEOUT}s"

    if [[ -z "$url" && -z "$SMOKE_PORT" ]]; then
        log_info "[SMOKE] No URL or port configured; smoke test considered informational"
        return "$OK"
    fi

    for ((attempt=1; attempt<=RETRIES; attempt++)); do
        if [[ -n "$url" ]]; then
            if command -v curl >/dev/null 2>&1 && curl -fsS --max-time "$TIMEOUT" "$url" >/dev/null; then
                log_info "[SMOKE] URL reachable: $url"
                status_ok "Smoke URL reachable: $url"
                return "$OK"
            fi
        fi

        if [[ -n "$SMOKE_PORT" ]]; then
            local host="${REMOTE_HOST:-localhost}"
            if command -v nc >/dev/null 2>&1 && nc -z -w "$TIMEOUT" "$host" "$SMOKE_PORT"; then
                log_info "[SMOKE] Port reachable: $host:$SMOKE_PORT"
                status_ok "Smoke port reachable: $host:$SMOKE_PORT"
                return "$OK"
            fi
        fi

        log_info "[SMOKE] Attempt $attempt/$RETRIES failed; retrying"
        sleep 1
    done

    log_error "[SMOKE] Verification failed"
    rollback_after_failure
    return "$ERR_SMOKE"
}
