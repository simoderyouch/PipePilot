# Docker Stack Scenario

Date: 2026-05-01T21:02:07+01:00

Server: `54.211.174.69`

Example stack: `examples/exemples/portfolio-backend-stack`

PipePilot command type: production remote Docker Compose stack deployment

## Goal

Create and deploy a Docker Compose stack scenario from the examples folder. The
stack serves the portfolio frontend at `/` and proxies the backend API under
`/api/`.

The server was cleaned first, then PipePilot deployed the stack from a fresh
state.

## Stack Files

Created example files:

```text
examples/exemples/portfolio-backend-stack/README.md
examples/exemples/portfolio-backend-stack/compose.yml
examples/exemples/portfolio-backend-stack/backend/Dockerfile
examples/exemples/portfolio-backend-stack/backend/app.py
examples/exemples/portfolio-backend-stack/backend/requirements.txt
examples/exemples/portfolio-backend-stack/gateway/default.conf
examples/exemples/portfolio-backend-stack/frontend-dist/
```

Services:

| Service | Purpose |
|---|---|
| `gateway` | Public nginx entrypoint on host port `80` |
| `portfolio` | nginx static server for the built portfolio files |
| `backend` | FastAPI backend listening internally on port `6000` |

Routes:

```text
http://54.211.174.69/
http://54.211.174.69/api/health
http://54.211.174.69/api/items/1
```

## Server Cleanup

Cleanup removed previous stack/backend/frontend deployments, generated nginx
configs, containers, Docker state, systemd backend service, and setup packages.

Cleanup command:

```bash
ssh -i examples/pipepilot.pem \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  ubuntu@54.211.174.69 '
set -e
if [ -d /srv/portfolio-backend-stack ]; then
  cd /srv/portfolio-backend-stack
  if command -v docker >/dev/null 2>&1; then
    sudo docker compose -f compose.yml down --remove-orphans 2>/dev/null || sudo docker-compose -f compose.yml down --remove-orphans 2>/dev/null || true
  fi
fi
sudo systemctl stop pipepilot-python-backend-api 2>/dev/null || true
sudo systemctl disable pipepilot-python-backend-api 2>/dev/null || true
sudo rm -f /etc/systemd/system/pipepilot-python-backend-api.service
sudo systemctl daemon-reload 2>/dev/null || true
sudo systemctl stop nginx 2>/dev/null || true
if command -v docker >/dev/null 2>&1; then
  sudo docker rm -f $(sudo docker ps -aq) 2>/dev/null || true
  sudo docker system prune -af --volumes >/tmp/pipepilot-docker-prune.log 2>&1 || true
fi
sudo rm -rf /srv/portfolio-backend-stack /srv/python-backend-api /var/www/mohamededderyouch.me
sudo rm -f /etc/nginx/sites-enabled/pipepilot* /etc/nginx/sites-available/pipepilot* /etc/nginx/conf.d/pipepilot*.conf 2>/dev/null || true
sudo fuser -k 80/tcp 5000/tcp 6000/tcp 2>/dev/null || true
for pkg in nginx nginx-common nginx-core rsync curl docker.io docker-compose docker-compose-plugin docker-compose-v2 containerd runc; do
  sudo apt-get remove -y --purge "$pkg" >/tmp/pipepilot-stack-cleanup-$pkg.log 2>&1 || true
done
sudo apt-get autoremove -y >/tmp/pipepilot-stack-autoremove-2.log 2>&1 || true
'
```

Fresh-state verification:

```text
nginx_absent
rsync_absent
curl_absent
docker_absent
backend_service_absent
stack_dir_absent
port80_unreachable_after_cleanup
port6000_unreachable_after_cleanup
```

## Deploy Command

```bash
./pipepilot \
  -p examples/exemples/portfolio-backend-stack \
  -e production \
  --remote \
  --host 54.211.174.69 \
  --user ubuntu \
  --key examples/pipepilot.pem \
  --compose-file compose.yml \
  --url http://54.211.174.69/api/health
```

No manual `--target`, `--deploy-dir`, `--setup-server`, `--app-kind`,
`--backend-runtime`, `--domain`, or `--app-port` options were provided.

## Result

Status: success

Exit code: `0`

Portfolio URL:

```text
http://54.211.174.69/
```

Backend health URL:

```text
http://54.211.174.69/api/health
```

Raw output log:

```text
logs/run-2026-05-01-21-00-28-173261.raw.log
```

Structured log:

```text
logs/history.log
```

## PipePilot Output

```text
PipePilot run
Project: /home/edder/Documents/PipePilot/examples/exemples/portfolio-backend-stack
Environment: production
Mode: sequential
Structured log: /home/edder/Documents/PipePilot/logs/history.log
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-21-00-28-173261.raw.log

[RUN] GIT - sync source and detect project
[GIT] using local project files
[DETECT] project_type=docker-compose
[OK]  GIT
[RUN] LINT - run static checks
[OK]  LINT
[RUN] TEST - run available tests
[TEST] passed=0 failed=0
[OK]  TEST
[RUN] BUILD - install dependencies and build artifact
[BUILD] project_type=docker-compose
[BUILD] remote docker compose build deferred to deploy
[BUILD] artifact ready
[OK]  BUILD
[RUN] ARCHIVE - create rollback archive
[ARCHIVE] created /home/edder/Documents/PipePilot/archives/portfolio-backend-stack-2026-05-01-21-00-28-v0.8.0.tar.gz
[OK]  ARCHIVE
[RUN] DEPLOY - prepare remote and upload artifact
[SMART] target=/srv/portfolio-backend-stack
[SMART] deploy_source=.
[SMART] setup=enabled
[DEPLOY] remote=ubuntu@54.211.174.69 transfer=rsync
[SETUP] app_kind=stack runtime=compose packages="docker.io rsync curl"
[SETUP] target=/srv/portfolio-backend-stack server_name=54.211.174.69
[OK]  Remote setup completed
[DOCKER] runtime=compose file=compose.yml
[OK]  Uploaded files to 54.211.174.69:/srv/portfolio-backend-stack
[OK]  DEPLOY
[RUN] SMOKE - verify deployed app
[SMOKE] url=http://54.211.174.69/api/health retries=3 timeout=5s
curl: (22) The requested URL returned error: 502
[OK]  Smoke URL reachable: http://54.211.174.69/api/health
[OK]  SMOKE

[OK]  Pipeline completed successfully
Remote host: 54.211.174.69
Target: /srv/portfolio-backend-stack
Smoke URL: http://54.211.174.69/api/health
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-21-00-28-173261.raw.log
```

The first smoke attempt briefly returned `502` while the containers were
starting. PipePilot retried and the smoke check passed.

## Structured Timeline

Important lines from `logs/history.log`:

```text
2026-05-01-21-00-28 : [START] Pipeline started -- /home/edder/Documents/PipePilot/examples/exemples/portfolio-backend-stack
2026-05-01-21-00-28 : [DETECT] Project type detected: docker-compose
2026-05-01-21-00-28 : [BUILD] Docker Compose build will run on the remote host
2026-05-01-21-00-30 : [SMART] Remote target inferred: /srv/portfolio-backend-stack
2026-05-01-21-00-30 : [SMART] Deploy source inferred: .
2026-05-01-21-00-30 : [SMART] Remote server setup enabled automatically
2026-05-01-21-00-30 : [SETUP] Fresh-server setup started -- kind stack -- runtime compose -- packages: docker.io rsync curl
2026-05-01-21-00-54 : [SETUP] Fresh-server setup completed -- kind stack
2026-05-01-21-01-19 : [DOCKER] Runtime detected -- compose -- file: compose.yml
2026-05-01-21-01-43 : [DOCKER] Docker runtime configured and restarted
2026-05-01-21-01-43 : [DEPLOY] Production deployment completed successfully
2026-05-01-21-01-43 : [SMOKE] Attempt 1/3 failed; retrying
2026-05-01-21-01-45 : [SMOKE] URL reachable: http://54.211.174.69/api/health
2026-05-01-21-01-45 : [END] Pipeline completed successfully
```

## Smart Detection

| Item | Value |
|---|---|
| Project type | `docker-compose` |
| App kind | `stack` |
| Runtime | `compose` |
| Deploy source | `.` |
| Remote target | `/srv/portfolio-backend-stack` |
| Remote setup | enabled automatically |
| Setup packages | `docker.io rsync curl` |
| Compose file | `compose.yml` |
| Smoke URL | `http://54.211.174.69/api/health` |

## Remote State After Deploy

```text
docker=/usr/bin/docker
rsync=/usr/bin/rsync
curl=/usr/bin/curl
nginx_absent
```

Containers:

```text
NAME                                  IMAGE                             SERVICE     STATUS          PORTS
portfolio-backend-stack-backend-1     portfolio-backend-stack-backend   backend     Up              6000/tcp
portfolio-backend-stack-gateway-1     nginx:alpine                      gateway     Up              0.0.0.0:80->80/tcp, [::]:80->80/tcp
portfolio-backend-stack-portfolio-1   nginx:alpine                      portfolio   Up              80/tcp
```

Images:

```text
nginx:alpine 93.5MB
portfolio-backend-stack-backend:latest 247MB
```

Port checks:

```text
port80_reachable
port6000_not_exposed_on_host
```

This means the backend is reachable only through the Compose network and the
public gateway, not directly on the host.

## Endpoint Verification

```bash
curl -fsS http://54.211.174.69/api/health
curl -fsS http://54.211.174.69/api/items/1
```

Output:

```text
{"status":"ok"}
{"id":1,"name":"PipePilot","type":"deployment"}
```

Portfolio HTML check:

```text
<title>ED Deryouch | Full Stack Developer (React & MERN)</title>
<script type="module" crossorigin src="/assets/index-BhhYy0J8.js"></script>
<link rel="stylesheet" crossorigin href="/assets/index-C8EPu4Zx.css">
```

## Final State

The stack is live at:

```text
http://54.211.174.69/
```

The backend API is live through the stack gateway at:

```text
http://54.211.174.69/api/health
```
