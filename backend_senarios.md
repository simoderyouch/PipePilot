# Backend API Scenario

Date: 2026-05-01T19:45:36+01:00

Server: `54.211.174.69`

Project: `examples/exemples/python-backend-api`

Backend port: `6000`

## Goal

After the portfolio deployment, deploy the Python backend from the example
folder using PipePilot in production remote mode. The backend must run on port
`6000`, while nginx keeps the portfolio at `/` and proxies the API under
`/api/`. No code was edited.

## Deploy Command

```bash
./pipepilot \
  -p examples/exemples/python-backend-api \
  -e production \
  --remote \
  --host 54.211.174.69 \
  --user ubuntu \
  --key examples/pipepilot.pem \
  --app-port 6000 \
  --url http://54.211.174.69/api/health
```

No manual `--target`, `--deploy-dir`, `--setup-server`, `--app-kind`,
`--backend-runtime`, `--domain`, build command, retry, or timeout options were
used.

## Result

Status: success

Exit code: `0`

Live API URL:

```text
http://54.211.174.69/api/health
```

Portfolio URL:

```text
http://54.211.174.69/
```

Raw output log:

```text
logs/run-2026-05-01-19-44-10-133149.raw.log
```

Structured log:

```text
logs/history.log
```

## PipePilot Output

```text
PipePilot run
Project: /home/edder/Documents/PipePilot/examples/exemples/python-backend-api
Environment: production
Mode: sequential
Structured log: /home/edder/Documents/PipePilot/logs/history.log
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-19-44-10-133149.raw.log

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
[ARCHIVE] created /home/edder/Documents/PipePilot/archives/python-backend-api-2026-05-01-19-44-10-v0.7.3.tar.gz
[OK]  ARCHIVE
[RUN] DEPLOY - prepare remote and upload artifact
[SMART] target=/srv/python-backend-api
[SMART] deploy_source=.
[SMART] setup=enabled
[DEPLOY] remote=ubuntu@54.211.174.69 transfer=rsync
[SETUP] app_kind=backend runtime=python packages="python3 python3-pip python3-venv nginx rsync curl"
[SETUP] target=/srv/python-backend-api server_name=54.211.174.69
[OK]  Remote setup completed
[OK]  Uploaded files to 54.211.174.69:/srv/python-backend-api
[OK]  DEPLOY
[RUN] SMOKE - verify deployed app
[SMOKE] url=http://54.211.174.69/api/health retries=3 timeout=5s
[OK]  Smoke URL reachable: http://54.211.174.69/api/health
[OK]  SMOKE

[OK]  Pipeline completed successfully
Remote host: 54.211.174.69
Target: /srv/python-backend-api
Smoke URL: http://54.211.174.69/api/health
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-19-44-10-133149.raw.log
```

## Structured Timeline

```text
2026-05-01-19-44-10 : [START] Pipeline started -- /home/edder/Documents/PipePilot/examples/exemples/python-backend-api
2026-05-01-19-44-10 : [GIT] No git repository found; using existing local project files
2026-05-01-19-44-10 : [DETECT] Project type detected: python
2026-05-01-19-44-10 : [TEST] 1 tests passed successfully
2026-05-01-19-44-10 : [BUILD] Python backend dependencies will be installed on the remote host
2026-05-01-19-44-11 : [SMART] Remote target inferred: /srv/python-backend-api
2026-05-01-19-44-11 : [SMART] Deploy source inferred: .
2026-05-01-19-44-11 : [SMART] Remote server setup enabled automatically
2026-05-01-19-44-22 : [SETUP] Fresh-server setup completed -- kind backend
2026-05-01-19-44-29 : [BACKEND] Runtime detected -- python -- command: .venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 6000 -- service: pipepilot-python-backend-api
2026-05-01-19-44-40 : [BACKEND] Backend service configured and restarted -- pipepilot-python-backend-api
2026-05-01-19-44-41 : [DEPLOY] Production deployment completed successfully
2026-05-01-19-44-41 : [SMOKE] URL reachable: http://54.211.174.69/api/health
2026-05-01-19-44-41 : [END] Pipeline completed successfully
```

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

## Remote State

```text
service=active
nginx=active
/usr/sbin/nginx
/usr/bin/rsync
/usr/bin/curl
/usr/bin/pip3
Environment=PORT=6000 NODE_ENV=production PYTHONUNBUFFERED=1
WorkingDirectory=/srv/python-backend-api
ExecStart=/bin/bash -lc .venv/bin/python -m uvicorn app:app --host 0.0.0.0 --port 6000
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Port checks:

```text
port6000_reachable
port5000_unreachable
```

## Nginx Config

Generated file:

```text
/etc/nginx/sites-available/pipepilot-54.211.174.69
```

Config:

```nginx
server {
    listen 80;
    server_name 54.211.174.69;
    root /var/www/mohamededderyouch.me;
    index index.html;

    location = /api {
        return 308 /api/;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:6000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Final State

The portfolio frontend is live at `http://54.211.174.69/`.

The backend API is live at `http://54.211.174.69/api/health`.

The backend service is running through systemd on port `6000`.
