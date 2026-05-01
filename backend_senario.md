# Backend API Scenario

Date: 2026-05-01T19:02:50+01:00

Example app: `examples/exemples/python-backend-api`

Live URL:

```text
http://<REMOTE_HOST>/health
```

Use placeholders in this document before publishing:

- `<REMOTE_HOST>` - remote server hostname or IP
- `<SSH_KEY_PATH>` - local SSH private key path

## Goal

Create a small Python backend API example with four endpoints, clean the remote
instance, then deploy it with PipePilot using smart defaults plus an explicit
backend app port of `5000`.

## Example App

Created a FastAPI backend example in `examples/exemples/python-backend-api`.

Endpoints:

- `GET /`
- `GET /health`
- `GET /items`
- `GET /items/{item_id}`

Files:

- `app.py` - API application
- `requirements.txt` - FastAPI and uvicorn runtime dependencies
- `tests/test_api.py` - endpoint behavior tests
- `README.md` - example usage notes

## Manual Cleanup

This command removes the previous backend service, frontend deployment, backend
target directory, generated nginx config, and setup packages so the scenario
starts from a fresh server state.

```bash
REMOTE_HOST="<REMOTE_HOST>"
SSH_KEY="<SSH_KEY_PATH>"

ssh -i "$SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  "ubuntu@$REMOTE_HOST" '
set -e
sudo systemctl stop pipepilot-python-backend-api 2>/dev/null || true
sudo systemctl disable pipepilot-python-backend-api 2>/dev/null || true
sudo rm -f /etc/systemd/system/pipepilot-python-backend-api.service
sudo systemctl daemon-reload 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
sudo rm -rf /srv/python-backend-api /var/www/mohamededderyouch.me
sudo rm -f \
  /etc/nginx/sites-enabled/pipepilot \
  /etc/nginx/sites-available/pipepilot \
  /etc/nginx/conf.d/pipepilot.conf 2>/dev/null || true
sudo apt-get remove -y --purge \
  nginx nginx-common rsync curl python3-pip python3-venv \
  >/tmp/pipepilot-backend-cleanup.log 2>&1 || true
sudo apt-get autoremove -y \
  >/tmp/pipepilot-backend-autoremove.log 2>&1 || true

if command -v nginx >/dev/null 2>&1; then echo nginx_present; else echo nginx_absent; fi
if command -v rsync >/dev/null 2>&1; then echo rsync_present; else echo rsync_absent; fi
if command -v curl >/dev/null 2>&1; then echo curl_present; else echo curl_absent; fi
if command -v pip3 >/dev/null 2>&1; then echo pip3_present; else echo pip3_absent; fi
if systemctl list-unit-files pipepilot-python-backend-api.service --no-legend 2>/dev/null | grep -q pipepilot; then
  echo backend_service_present
else
  echo backend_service_absent
fi
if test -d /srv/python-backend-api; then echo backend_dir_present; else echo backend_dir_absent; fi
if timeout 5 bash -lc "</dev/tcp/127.0.0.1/80" >/dev/null 2>&1; then
  echo port80_reachable_after_cleanup
else
  echo port80_unreachable_after_cleanup
fi
'
```

Fresh-state verification before deployment:

```text
nginx_absent
rsync_absent
curl_absent
pip3_absent
backend_service_absent
backend_dir_absent
port80_unreachable_after_cleanup
```

This means the test started without the previous frontend app, without nginx,
without rsync, without curl, without pip3, without the backend service, and
without the backend target directory.

## Deploy Command

```bash
./pipepilot \
  -p examples/exemples/python-backend-api \
  -e production \
  --remote \
  --host <REMOTE_HOST> \
  --user ubuntu \
  --key <SSH_KEY_PATH> \
  --app-port 5000 \
  --url http://<REMOTE_HOST>/health
```

No manual `--target`, `--deploy-dir`, `--setup-server`, `--app-kind`,
`--backend-runtime`, `--domain`, build command, retries, or timeout options were
provided.

## Scenario Run Output

This is the clean PipePilot output from the deployment:

```text
PipePilot run
Project: /home/edder/Documents/PipePilot/examples/exemples/python-backend-api
Environment: production
Mode: sequential
Structured log: /home/edder/Documents/PipePilot/logs/history.log
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-19-02-12-83931.raw.log

[RUN] GIT - sync source and detect project
[GIT] using local project files
[DETECT] project_type=python
[OK]  GIT
[RUN] LINT - run static checks
[OK]  LINT
[RUN] TEST - run available tests
[TEST] passed=1 failed=0
[OK]  TEST
[RUN] BUILD - install dependencies and build artifact
[BUILD] project_type=python
[BUILD] remote backend dependencies deferred to setup
[BUILD] artifact ready
[OK]  BUILD
[RUN] ARCHIVE - create rollback archive
[ARCHIVE] created /home/edder/Documents/PipePilot/archives/python-backend-api-2026-05-01-19-02-13-v0.7.3.tar.gz
[OK]  ARCHIVE
[RUN] DEPLOY - prepare remote and upload artifact
[SMART] target=/srv/python-backend-api
[SMART] deploy_source=.
[SMART] setup=enabled
[DEPLOY] remote=ubuntu@<REMOTE_HOST> transfer=rsync
[SETUP] app_kind=backend runtime=python packages="python3 python3-pip python3-venv nginx rsync curl"
[SETUP] target=/srv/python-backend-api server_name=<REMOTE_HOST>
[OK]  Remote setup completed
[OK]  Uploaded files to <REMOTE_HOST>:/srv/python-backend-api
[OK]  DEPLOY
[RUN] SMOKE - verify deployed app
[SMOKE] url=http://<REMOTE_HOST>/health retries=3 timeout=5s
curl: (22) The requested URL returned error: 502
[OK]  Smoke URL reachable: http://<REMOTE_HOST>/health
[OK]  SMOKE

[OK]  Pipeline completed successfully
Remote host: <REMOTE_HOST>
Target: /srv/python-backend-api
Smoke URL: http://<REMOTE_HOST>/health
```

Note: the `502` was the first smoke attempt while the backend service was
starting. PipePilot retried and the smoke check passed.

## Structured Timeline

Important lines from `logs/history.log`:

```text
2026-05-01-19-02-12 : [START] Pipeline started -- examples/exemples/python-backend-api
2026-05-01-19-02-12 : [DETECT] Project type detected: python
2026-05-01-19-02-13 : [TEST] 1 tests passed successfully
2026-05-01-19-02-13 : [BUILD] Python backend dependencies will be installed on the remote host
2026-05-01-19-02-13 : [SMART] Remote target inferred: /srv/python-backend-api
2026-05-01-19-02-13 : [SMART] Deploy source inferred: .
2026-05-01-19-02-13 : [SMART] Remote server setup enabled automatically
2026-05-01-19-02-31 : [SETUP] Fresh-server setup completed -- kind backend
2026-05-01-19-02-36 : [BACKEND] Runtime detected -- python -- command: .venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 5000 -- service: pipepilot-python-backend-api
2026-05-01-19-02-48 : [BACKEND] Backend service configured and restarted -- pipepilot-python-backend-api
2026-05-01-19-02-49 : [SMOKE] Attempt 1/3 failed; retrying
2026-05-01-19-02-50 : [SMOKE] URL reachable: http://<REMOTE_HOST>/health
2026-05-01-19-02-50 : [END] Pipeline completed successfully
```

## Endpoint Verification

```text
GET /health
{"status":"ok"}

GET /items/1
{"id":1,"name":"PipePilot","type":"deployment"}
```

## Remote State After Deploy

```text
service=active
nginx=active
/usr/sbin/nginx
/usr/bin/rsync
/usr/bin/curl
/usr/bin/pip3
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Backend service:

```text
WorkingDirectory=/srv/python-backend-api
Environment=PORT=5000
ExecStart=/bin/bash -lc '.venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 5000'
```

Nginx reverse proxy:

```text
server_name <REMOTE_HOST>;
proxy_pass http://127.0.0.1:5000;
```

## Result

Deployment succeeded.

The Python backend API is reachable at `http://<REMOTE_HOST>/health`, running
through nginx on port `80` and managed by the systemd service
`pipepilot-python-backend-api`. The backend app itself listens on port `5000`.
