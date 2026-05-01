# Portfolio Scenario

Date: 2026-05-01T19:45:36+01:00

Server: `54.211.174.69`

Project: `examples/exemples/mohamededderyouch.me`

## Goal

Clean the remote server completely, then deploy the portfolio first using
PipePilot in production remote mode with the example portfolio folder. No code
was edited.

## Cleanup

Cleanup removed the previous backend service, nginx config, deployed portfolio,
deployed backend, setup packages, and any processes on backend ports `5000` and
`6000`.

Command used:

```bash
ssh -i examples/pipepilot.pem \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  ubuntu@54.211.174.69 '
set -e
sudo systemctl stop pipepilot-python-backend-api 2>/dev/null || true
sudo systemctl disable pipepilot-python-backend-api 2>/dev/null || true
sudo rm -f /etc/systemd/system/pipepilot-python-backend-api.service
sudo systemctl daemon-reload 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
sudo rm -rf /srv/python-backend-api /var/www/mohamededderyouch.me
sudo rm -f /etc/nginx/sites-enabled/pipepilot /etc/nginx/sites-available/pipepilot /etc/nginx/conf.d/pipepilot.conf 2>/dev/null || true
sudo fuser -k 5000/tcp 6000/tcp 2>/dev/null || true
sudo apt-get remove -y --purge nginx nginx-common nginx-core rsync curl python3-pip python3-venv >/tmp/pipepilot-cleanup.log 2>&1 || true
sudo apt-get autoremove -y >/tmp/pipepilot-autoremove.log 2>&1 || true
'
```

Fresh-state verification:

```text
nginx_absent
rsync_absent
curl_absent
pip3_absent
backend_service_absent
backend_dir_absent
portfolio_dir_absent
port80_unreachable_after_cleanup
port6000_unreachable_after_cleanup
```

## Deploy Command

```bash
./pipepilot \
  -p examples/exemples/mohamededderyouch.me \
  -e production \
  --remote \
  --host 54.211.174.69 \
  --user ubuntu \
  --key examples/pipepilot.pem
```

No manual `--target`, `--deploy-dir`, `--setup-server`, `--app-kind`,
`--domain`, `--url`, retry, or timeout options were used.

## Result

Status: success

Exit code: `0`

Live URL:

```text
http://54.211.174.69
```

Raw output log:

```text
logs/run-2026-05-01-19-42-41-131980.raw.log
```

Structured log:

```text
logs/history.log
```

## PipePilot Output

```text
PipePilot run
Project: /home/edder/Documents/PipePilot/examples/exemples/mohamededderyouch.me
Environment: production
Mode: sequential
Structured log: /home/edder/Documents/PipePilot/logs/history.log
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-19-42-41-131980.raw.log

[RUN] GIT - sync source and detect project
[GIT] branch=main commit=fe74020 author=simoderyouch
[DETECT] project_type=node
[OK]  GIT
[RUN] LINT - run static checks
[LINT] running npm run lint
[WARN] Lint reported issues; continuing because --strict is not enabled
[OK]  LINT
[RUN] TEST - run available tests
[TEST] no npm test script found
[TEST] passed=0 failed=0
[OK]  TEST
[RUN] BUILD - install dependencies and build artifact
[BUILD] project_type=node
[BUILD] installing dependencies with npm ci
[BUILD] running npm run build
[BUILD] artifact ready
[OK]  BUILD
[RUN] ARCHIVE - create rollback archive
[ARCHIVE] created /home/edder/Documents/PipePilot/archives/mohamededderyouch.me-2026-05-01-19-43-08-v0.7.3.tar.gz
[OK]  ARCHIVE
[RUN] DEPLOY - prepare remote and upload artifact
[SMART] target=/var/www/mohamededderyouch.me
[SMART] deploy_source=dist
[SMART] setup=enabled
[DEPLOY] remote=ubuntu@54.211.174.69 transfer=rsync
[SETUP] app_kind=frontend runtime=none packages="nginx rsync curl"
[SETUP] target=/var/www/mohamededderyouch.me server_name=54.211.174.69
[OK]  Remote setup completed
[OK]  Uploaded files to 54.211.174.69:/var/www/mohamededderyouch.me
[OK]  DEPLOY
[RUN] SMOKE - verify deployed app
[SMOKE] url=http://54.211.174.69 retries=3 timeout=5s
[OK]  Smoke URL reachable: http://54.211.174.69
[OK]  SMOKE

[OK]  Pipeline completed successfully
Remote host: 54.211.174.69
Target: /var/www/mohamededderyouch.me
Smoke URL: http://54.211.174.69
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-19-42-41-131980.raw.log
```

## Structured Timeline

```text
2026-05-01-19-42-41 : [START] Pipeline started -- /home/edder/Documents/PipePilot/examples/exemples/mohamededderyouch.me
2026-05-01-19-42-43 : [GIT] Pull OK -- branch main -- commit fe74020 -- author simoderyouch
2026-05-01-19-42-43 : [DETECT] Project type detected: node
2026-05-01-19-42-45 : [LINT] npm lint reported issues; continuing because --strict is not enabled
2026-05-01-19-42-45 : [TEST] package.json has no test script; skipping
2026-05-01-19-43-08 : [BUILD] Build successful -- artifact generated
2026-05-01-19-43-27 : [SMART] Remote target inferred: /var/www/mohamededderyouch.me
2026-05-01-19-43-27 : [SMART] Deploy source inferred: dist
2026-05-01-19-43-27 : [SMART] Remote server setup enabled automatically
2026-05-01-19-43-43 : [SETUP] Fresh-server setup completed -- kind frontend
2026-05-01-19-44-05 : [DEPLOY] Production deployment completed successfully
2026-05-01-19-44-05 : [SMOKE] URL reachable: http://54.211.174.69
2026-05-01-19-44-05 : [END] Pipeline completed successfully
```

## Smart Detection

| Item | Value |
|---|---|
| Project type | `node` |
| App kind | `frontend` |
| Deploy source | `dist` |
| Remote target | `/var/www/mohamededderyouch.me` |
| Remote setup | enabled automatically |
| Setup packages | `nginx rsync curl` |
| Smoke URL | `http://54.211.174.69` |

## Manual Verification

```bash
curl -fsS http://54.211.174.69 | sed -n '1,45p'
```

Important returned HTML:

```text
<title>ED Deryouch | Full Stack Developer (React & MERN)</title>
<meta name="author" content="ED Deryouch" />
<script type="module" crossorigin src="/assets/index-BhhYy0J8.js"></script>
<link rel="stylesheet" crossorigin href="/assets/index-C8EPu4Zx.css">
```

After the backend deployment, the portfolio remains reachable at:

```text
http://54.211.174.69/
```
