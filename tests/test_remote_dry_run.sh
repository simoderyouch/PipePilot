#!/usr/bin/env bash
# Extra scenario - Remote deployment dry run.
# This test proves that the new SSH deployment options are parsed and validated
# without needing a real VPS, school server, or cloud VM. A temporary fake key is
# enough because --dry-run prevents actual ssh/scp/rsync execution. It also
# exercises smart fresh-server setup with --setup-server.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/remote_frontend_project"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/remote"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/remote"
KEY_PATH="$ROOT_DIR/tests/tmp/fake_remote_key.pem"

rm -rf "$WORK_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR/dist" "$(dirname "$KEY_PATH")"

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

echo "[SCENARIO] Remote deployment dry run completed"
