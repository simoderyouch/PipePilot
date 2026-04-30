#!/usr/bin/env bash
# Step 2 - Lint / Static Code Analysis.
#
# This file checks syntax and static quality based on PROJECT_TYPE. It supports
# Shell, Python, C, Node.js, custom lint tools, skip mode, and strict mode.

stage_lint() {
    if [[ "$SKIP_LINT" -eq 1 ]]; then
        log_info "[LINT] Skipped by --skip-lint"
        return "$OK"
    fi

    log_info "[LINT] Starting static analysis"

    if [[ -n "$LINT_TOOL" ]]; then
        require_command "$LINT_TOOL" "$ERR_DEPENDENCY"
        run_in_project "$LINT_TOOL" . || return "$ERR_LINT"
        log_info "[LINT] Custom lint tool completed: $LINT_TOOL"
        return "$OK"
    fi

    case "$PROJECT_TYPE" in
        shell)
            local shell_file
            while IFS= read -r shell_file; do
                bash -n "$shell_file" || return "$ERR_LINT"
                if command -v shellcheck >/dev/null 2>&1; then
                    shellcheck "$shell_file" || return "$ERR_LINT"
                elif [[ "$STRICT" -eq 1 ]]; then
                    return "$ERR_DEPENDENCY"
                fi
            done < <(find "$PROJECT_PATH" -type f -name "*.sh")
            ;;
        python)
            local py_file
            while IFS= read -r py_file; do
                python3 -m py_compile "$py_file" || return "$ERR_LINT"
                if command -v pylint >/dev/null 2>&1; then
                    pylint "$py_file" || return "$ERR_LINT"
                fi
            done < <(find "$PROJECT_PATH" -type f -name "*.py")
            ;;
        c)
            local c_file
            require_command gcc "$ERR_DEPENDENCY"
            while IFS= read -r c_file; do
                gcc -Wall -fsyntax-only "$c_file" || return "$ERR_LINT"
            done < <(find "$PROJECT_PATH" -type f -name "*.c")
            ;;
        node)
            if [[ -f "$PROJECT_PATH/package.json" ]] && command -v npm >/dev/null 2>&1; then
                if run_shell_in_project "npm run | grep -q '^  lint'"; then
                    run_shell_in_project "npm run lint" || return "$ERR_LINT"
                else
                    log_info "[LINT] package.json has no lint script; skipping"
                fi
            else
                [[ "$STRICT" -eq 0 ]] || return "$ERR_DEPENDENCY"
            fi
            ;;
        *)
            log_info "[LINT] No known lint strategy for generic project; skipping"
            ;;
    esac

    log_info "[LINT] No syntax errors detected"
    return "$OK"
}

