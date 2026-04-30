#!/usr/bin/env bash
# Scenario 1 - Light project.
# Creates a small Shell project, then runs PipePilot sequentially against it.
# This validates the basic path: pull/local source, lint, tests, build skip,
# archive, local deploy, and informational smoke test.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/light_project"
DEPLOY_DIR="$ROOT_DIR/tests/tmp/deploy/light"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/light"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/light"

rm -rf "$WORK_DIR" "$DEPLOY_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR/tests"

cat > "$WORK_DIR/app.sh" <<'APP'
#!/usr/bin/env bash
set -euo pipefail

name="${1:-PipePilot}"
echo "Hello, $name"
APP

cat > "$WORK_DIR/tests/test_app.sh" <<'TEST'
#!/usr/bin/env bash
set -euo pipefail

output="$(bash "$(dirname "$0")/../app.sh" Student)"
[[ "$output" == "Hello, Student" ]]
TEST

chmod +x "$WORK_DIR/app.sh" "$WORK_DIR/tests/test_app.sh"

"$ROOT_DIR/pipepilot" \
    -p "$WORK_DIR" \
    -e staging \
    -v \
    --target "$DEPLOY_DIR" \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

echo "[SCENARIO] Light Shell project completed"

