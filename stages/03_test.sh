#!/usr/bin/env bash
# Step 3 - Test / Unit Testing.
#
# This file discovers and runs tests according to the detected project type.
# It demonstrates loops, pattern filtering, fail-fast behavior, and optional
# coverage arguments for Python projects.

stage_test() {
    if [[ "$SKIP_TESTS" -eq 1 ]]; then
        log_info "[TEST] Skipped by --skip-tests"
        return "$OK"
    fi

    log_info "[TEST] Starting unit tests"
    local passed=0
    local failed=0

    case "$PROJECT_TYPE" in
        shell|frontend)
            local test_file
            while IFS= read -r test_file; do
                [[ -z "$TEST_PATTERN" || "$test_file" == *"$TEST_PATTERN"* ]] || continue
                if bash "$test_file"; then
                    passed=$((passed + 1))
                else
                    failed=$((failed + 1))
                    [[ "$FAIL_FAST" -eq 0 ]] || return "$ERR_TEST"
                fi
            done < <(find "$PROJECT_PATH" -type f \( -path "*/tests/test_*.sh" -o -name "test_*.sh" \))
            ;;
        python)
            if command -v pytest >/dev/null 2>&1; then
                local coverage_arg=""
                [[ "$COVERAGE" -eq 0 ]] || coverage_arg="--cov=."
                run_shell_in_project "pytest $coverage_arg" || return "$ERR_TEST"
                passed=1
            else
                local test_py
                while IFS= read -r test_py; do
                    [[ -z "$TEST_PATTERN" || "$test_py" == *"$TEST_PATTERN"* ]] || continue
                    if python3 "$test_py"; then
                        passed=$((passed + 1))
                    else
                        failed=$((failed + 1))
                        [[ "$FAIL_FAST" -eq 0 ]] || return "$ERR_TEST"
                    fi
                done < <(find "$PROJECT_PATH" -type f -name "test_*.py")
            fi
            ;;
        node)
            if command -v npm >/dev/null 2>&1; then
                run_shell_in_project "npm test" || return "$ERR_TEST"
                passed=1
            fi
            ;;
    esac

    [[ "$failed" -eq 0 ]] || return "$ERR_TEST"
    log_info "[TEST] $passed tests passed successfully"
    return "$OK"
}
