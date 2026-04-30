#!/usr/bin/env bash
# Step 1 - Pull / Source Recovery.
#
# This file contains only the first CI/CD step. It prepares the source code by
# cloning a missing project, pulling an existing Git repository, optionally
# checking out a branch/commit, and detecting the project type for later steps.

detect_project_type() {
    # Detection is kept with the pull step because it happens immediately after
    # source recovery and prepares shared PROJECT_TYPE state for lint/test/build.
    if [[ -f "$PROJECT_PATH/package.json" ]]; then
        PROJECT_TYPE="node"
    elif find "$PROJECT_PATH" -maxdepth 2 -name "*.py" -print -quit | grep -q .; then
        PROJECT_TYPE="python"
    elif find "$PROJECT_PATH" -maxdepth 2 -name "*.sh" -print -quit | grep -q .; then
        PROJECT_TYPE="shell"
    else
        PROJECT_TYPE="frontend"
    fi
    log_info "[DETECT] Project type detected: $PROJECT_TYPE"
}

stage_pull() {
    log_info "[GIT] Starting source recovery"
    require_command git "$ERR_GIT"

    if [[ ! -d "$PROJECT_PATH" ]]; then
        [[ -n "$REPO_URL" ]] || die "$ERR_PROJECT_NOT_FOUND" "[GIT] Project directory not found: $PROJECT_PATH"
        run_cmd "[GIT] Clone repository" git clone --branch "$BRANCH" "$REPO_URL" "$PROJECT_PATH" || return "$ERR_GIT"
    fi

    if [[ -d "$PROJECT_PATH/.git" ]]; then
        run_in_project git fetch --all --prune || return "$ERR_GIT"
        run_in_project git checkout "$BRANCH" || return "$ERR_GIT"
        run_in_project git pull --ff-only || return "$ERR_GIT"
        if [[ -n "$COMMIT_HASH" ]]; then
            run_in_project git checkout "$COMMIT_HASH" || return "$ERR_GIT"
        fi
        local current_branch commit_hash author
        current_branch="$(run_in_project git branch --show-current || true)"
        commit_hash="$(run_in_project git rev-parse --short HEAD || true)"
        author="$(run_in_project git log -1 --pretty=format:'%an' || true)"
        log_info "[GIT] Pull OK -- branch ${current_branch:-detached} -- commit ${commit_hash:-unknown} -- author ${author:-unknown}"
    else
        log_info "[GIT] No git repository found; using existing local project files"
    fi

    detect_project_type
    return "$OK"
}
