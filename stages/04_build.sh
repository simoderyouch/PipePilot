#!/usr/bin/env bash
# Step 4 - Build / Compilation or Packaging.
#
# This file creates the deployable artifact. It supports custom build commands,
# clean builds, dependency installation, build.sh, Makefile, Node.js frontends
# or backends, Python backends, and frontend projects that do not need
# compilation.

stage_build() {
    if [[ "$SKIP_BUILD" -eq 1 ]]; then
        log_info "[BUILD] Skipped by --skip-build"
        status_line "[BUILD] skipped by --skip-build"
        return "$OK"
    fi

    log_info "[BUILD] Starting build"
    status_line "[BUILD] project_type=$PROJECT_TYPE"

    if [[ "$CLEAN" -eq 1 ]]; then
        run_shell_in_project "rm -rf build dist out target" || return "$ERR_BUILD"
        log_info "[BUILD] Cleaned old build directories"
    fi

    if [[ "$INSTALL_DEPS" -eq 1 ]]; then
        case "$PROJECT_TYPE" in
            node)
                require_command npm "$ERR_DEPENDENCY"
                run_shell_in_project "npm install" || return "$ERR_BUILD"
                ;;
            python)
                if [[ -f "$PROJECT_PATH/requirements.txt" ]]; then
                    if [[ "$REMOTE_MODE" -eq 1 && "$(effective_app_kind)" == "backend" ]]; then
                        log_info "[BUILD] Python backend dependencies will be installed on the remote host"
                        status_line "[BUILD] remote backend dependencies deferred to setup"
                    else
                    require_command python3 "$ERR_DEPENDENCY"
                    run_shell_in_project "python3 -m pip install -r requirements.txt" || return "$ERR_BUILD"
                    fi
                fi
                ;;
        esac
    fi

    if [[ -n "$BUILD_CMD" ]]; then
        run_shell_in_project "$BUILD_CMD" || return "$ERR_BUILD"
    elif [[ -x "$PROJECT_PATH/build.sh" ]]; then
        run_shell_in_project "./build.sh" || return "$ERR_BUILD"
    elif [[ -f "$PROJECT_PATH/Makefile" || -f "$PROJECT_PATH/makefile" ]]; then
        run_shell_in_project "make" || return "$ERR_BUILD"
    else
        case "$PROJECT_TYPE" in
            node)
                require_command npm "$ERR_DEPENDENCY"
                if [[ -f "$PROJECT_PATH/package-lock.json" ]]; then
                    status_line "[BUILD] installing dependencies with npm ci"
                    run_shell_in_project "npm ci" || return "$ERR_BUILD"
                else
                    status_line "[BUILD] installing dependencies with npm install"
                    run_shell_in_project "npm install" || return "$ERR_BUILD"
                fi
                if package_json_has_script "build"; then
                    status_line "[BUILD] running npm run build"
                    run_shell_in_project "npm run build" || return "$ERR_BUILD"
                else
                    log_info "[BUILD] package.json has no build script; using project files as deploy artifact"
                fi
                ;;
            python)
                if [[ -f "$PROJECT_PATH/requirements.txt" ]]; then
                    if [[ "$REMOTE_MODE" -eq 1 && "$(effective_app_kind)" == "backend" ]]; then
                        log_info "[BUILD] Python backend dependencies will be installed on the remote host"
                        status_line "[BUILD] remote backend dependencies deferred to setup"
                    else
                    run_shell_in_project "python3 -m pip install -r requirements.txt" || return "$ERR_BUILD"
                    fi
                fi
                ;;
            *)
                log_info "[BUILD] No build command needed for this project type"
                ;;
        esac
    fi

    log_info "[BUILD] Build successful -- artifact generated"
    status_line "[BUILD] artifact ready"
    return "$OK"
}
