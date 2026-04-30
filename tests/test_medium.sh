#!/usr/bin/env bash
# Scenario 2 - Medium project.
# Creates a Python project and exercises subshell mode. The project uses plain
# Python assertions so it works even when pytest is not installed.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/medium_python_project"
DEPLOY_DIR="$ROOT_DIR/tests/tmp/deploy/medium"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/medium"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/medium"

rm -rf "$WORK_DIR" "$DEPLOY_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR/tests"

cat > "$WORK_DIR/app.py" <<'PY'
"""Tiny application module used by the PipePilot medium scenario."""


def add(left: int, right: int) -> int:
    """Return the sum of two integers."""
    return left + right


def multiply(left: int, right: int) -> int:
    """Return the product of two integers."""
    return left * right


if __name__ == "__main__":
    print(add(2, 3))
PY

cat > "$WORK_DIR/tests/test_app.py" <<'PY'
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import add, multiply


assert add(2, 3) == 5
assert multiply(4, 5) == 20
PY

"$ROOT_DIR/pipepilot" \
    -s \
    -p "$WORK_DIR" \
    -e staging \
    --target "$DEPLOY_DIR" \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

echo "[SCENARIO] Medium Python project completed"

