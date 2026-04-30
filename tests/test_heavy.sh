#!/usr/bin/env bash
# Scenario 3 - Backend project.
# Creates a Python backend-style project and runs PipePilot in thread-simulation
# mode. Production is executed with --dry-run so the scenario demonstrates the
# production command safely without requiring root or a remote server.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/backend_python_project"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/heavy"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/heavy"

rm -rf "$WORK_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR/tests"

cat > "$WORK_DIR/app.py" <<'PY'
"""Small backend module used by the PipePilot backend scenario."""


def health() -> dict[str, str]:
    """Return a simple health payload like a backend API would."""
    return {"status": "ok"}


def add_job(name: str) -> str:
    """Pretend to enqueue a backend job."""
    return f"job:{name}:queued"


if __name__ == "__main__":
    print(health()["status"])
PY

cat > "$WORK_DIR/tests/test_app.py" <<'PY'
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import add_job, health


def test_health():
    assert health() == {"status": "ok"}


def test_add_job():
    assert add_job("deploy") == "job:deploy:queued"
PY

"$ROOT_DIR/pipepilot" \
    -t \
    -d \
    -p "$WORK_DIR" \
    -e production \
    -b main \
    -v \
    --app-kind backend \
    --backend-runtime python \
    --app-port 8000 \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

echo "[SCENARIO] Backend Python project completed"
