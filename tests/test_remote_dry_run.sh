#!/usr/bin/env bash
# Extra scenario - Remote deployment dry run.
# This test proves that the new SSH deployment options are parsed and validated
# without needing a real VPS, school server, or cloud VM. A temporary fake key is
# enough because --dry-run prevents actual ssh/scp/rsync execution. It also
# exercises smart fresh-server setup with --setup-server.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/remote_frontend_project"
BACKEND_DIR="$ROOT_DIR/tests/tmp/remote_backend_project"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/remote"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/remote"
KEY_PATH="$ROOT_DIR/tests/tmp/fake_remote_key.pem"

rm -rf "$WORK_DIR" "$BACKEND_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR/dist" "$BACKEND_DIR/tests" "$(dirname "$KEY_PATH")"

cat > "$WORK_DIR/dist/index.html" <<'HTML'
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>PipePilot Remote Dry Run</title>
  </head>
  <body>
    <h1>PipePilot remote deployment test</h1>
  </body>
</html>
HTML

cat > "$KEY_PATH" <<'KEY'
-----BEGIN OPENSSH PRIVATE KEY-----
fake-key-used-only-for-pipepilot-dry-run-validation
-----END OPENSSH PRIVATE KEY-----
KEY

chmod 600 "$KEY_PATH"

cat > "$BACKEND_DIR/app.py" <<'PY'
try:
    from fastapi import FastAPI
except Exception:
    FastAPI = None

app = FastAPI() if FastAPI else None


def health():
    return {"status": "ok"}


if __name__ == "__main__":
    print(health()["status"])
PY

cat > "$BACKEND_DIR/requirements.txt" <<'REQ'
fastapi
uvicorn
REQ

cat > "$BACKEND_DIR/tests/test_app.py" <<'PY'
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app import health


def test_health():
    assert health() == {"status": "ok"}
PY

"$ROOT_DIR/pipepilot" \
    -d \
    -p "$WORK_DIR" \
    -e production \
    --remote \
    --setup-server \
    --app-kind frontend \
    --host example.com \
    --user deploy \
    --key "$KEY_PATH" \
    --ssh-port 2222 \
    --target /var/www/pipepilot-remote \
    --deploy-dir dist \
    --domain example.com \
    --package-manager apt \
    --setup-cmd "echo custom setup ok" \
    --transfer scp \
    --remote-cmd "echo remote command ok" \
    --restart pipepilot-demo \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

"$ROOT_DIR/pipepilot" \
    -d \
    -p "$BACKEND_DIR" \
    -e production \
    --skip-build \
    --remote \
    --setup-server \
    --app-kind backend \
    --backend-runtime python \
    --host api.example.com \
    --user deploy \
    --key "$KEY_PATH" \
    --target /srv/pipepilot-backend \
    --domain api.example.com \
    --app-port 8000 \
    --service-name pipepilot-backend-demo \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

echo "[SCENARIO] Remote deployment dry run completed"
