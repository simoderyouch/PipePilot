# Portfolio Scenario

Date: 2026-05-01T18:58:35+01:00

## Goal

Rerun the portfolio deployment from a fresh remote instance state and verify
that PipePilot output stays clean, orientational, and structured.

Fresh state means:

- no deployed portfolio directory
- no generated PipePilot nginx config
- no `nginx`, `rsync`, or `curl`
- no HTTP service responding on port `80`

Use placeholders in this document before publishing:

- `<REMOTE_HOST>` - remote server hostname or IP
- `<SSH_KEY_PATH>` - local SSH private key path

## Final Result

Status: success

Exit code: `0`

Live URL:

```text
http://<REMOTE_HOST>
```

Raw command output log:

```text
logs/run-2026-05-01-18-57-04-72814.raw.log
```

Structured log:

```text
logs/history.log
```

## Manual Cleanup

This command removes the previous portfolio deployment, generated nginx config,
and setup packages so the scenario starts from a fresh server state.

```bash
REMOTE_HOST="<REMOTE_HOST>"
SSH_KEY="<SSH_KEY_PATH>"

ssh -i "$SSH_KEY" \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  "ubuntu@$REMOTE_HOST" '
set -e
sudo systemctl stop nginx 2>/dev/null || true
sudo rm -rf /var/www/mohamededderyouch.me
sudo rm -f \
  /etc/nginx/sites-enabled/pipepilot \
  /etc/nginx/sites-available/pipepilot \
  /etc/nginx/conf.d/pipepilot.conf 2>/dev/null || true
sudo apt-get remove -y --purge nginx nginx-common rsync curl \
  >/tmp/pipepilot-portfolio-cleanup.log 2>&1 || true
sudo apt-get autoremove -y \
  >/tmp/pipepilot-portfolio-autoremove.log 2>&1 || true

if command -v nginx >/dev/null 2>&1; then echo nginx_present; else echo nginx_absent; fi
if command -v rsync >/dev/null 2>&1; then echo rsync_present; else echo rsync_absent; fi
if command -v curl >/dev/null 2>&1; then echo curl_present; else echo curl_absent; fi
if test -d /var/www/mohamededderyouch.me; then echo portfolio_dir_present; else echo portfolio_dir_absent; fi
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
portfolio_dir_absent
port80_unreachable_after_cleanup
```

## Deploy Command

```bash
./pipepilot \
  -p examples/exemples/mohamededderyouch.me \
  -e production \
  --remote \
  --host <REMOTE_HOST> \
  --user ubuntu \
  --key <SSH_KEY_PATH>
```

No manual `--target`, `--deploy-dir`, `--setup-server`, `--app-kind`,
`--domain`, `--url`, retries, or timeout options were provided.

## Scenario Run Output

```text
PipePilot run
Project: /home/edder/Documents/PipePilot/examples/exemples/mohamededderyouch.me
Environment: production
Mode: sequential
Structured log: /home/edder/Documents/PipePilot/logs/history.log
Raw output: /home/edder/Documents/PipePilot/logs/run-2026-05-01-18-57-04-72814.raw.log

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
[ARCHIVE] created /home/edder/Documents/PipePilot/archives/mohamededderyouch.me-2026-05-01-18-57-36-v0.7.3.tar.gz
[OK]  ARCHIVE
[RUN] DEPLOY - prepare remote and upload artifact
[SMART] target=/var/www/mohamededderyouch.me
[SMART] deploy_source=dist
[SMART] setup=enabled
[DEPLOY] remote=ubuntu@<REMOTE_HOST> transfer=rsync
[SETUP] app_kind=frontend runtime=none packages="nginx rsync curl"
[SETUP] target=/var/www/mohamededderyouch.me server_name=<REMOTE_HOST>
[OK]  Remote setup completed
[OK]  Uploaded files to <REMOTE_HOST>:/var/www/mohamededderyouch.me
[OK]  DEPLOY
[RUN] SMOKE - verify deployed app
[SMOKE] url=http://<REMOTE_HOST> retries=3 timeout=5s
[OK]  Smoke URL reachable: http://<REMOTE_HOST>
[OK]  SMOKE

[OK]  Pipeline completed successfully
Remote host: <REMOTE_HOST>
Target: /var/www/mohamededderyouch.me
Smoke URL: http://<REMOTE_HOST>
```

## Structured Timeline

Important lines from `logs/history.log`:

```text
2026-05-01-18-57-04 : [START] Pipeline started -- examples/exemples/mohamededderyouch.me
2026-05-01-18-57-11 : [GIT] Pull OK -- branch main -- commit fe74020 -- author simoderyouch
2026-05-01-18-57-11 : [DETECT] Project type detected: node
2026-05-01-18-57-13 : [LINT] npm lint reported issues; continuing because --strict is not enabled
2026-05-01-18-57-13 : [TEST] package.json has no test script; skipping
2026-05-01-18-57-36 : [BUILD] Build successful -- artifact generated
2026-05-01-18-57-56 : [SMART] Remote target inferred: /var/www/mohamededderyouch.me
2026-05-01-18-57-56 : [SMART] Deploy source inferred: dist
2026-05-01-18-57-56 : [SMART] Remote server setup enabled automatically
2026-05-01-18-58-12 : [SETUP] Fresh-server setup completed -- kind frontend
2026-05-01-18-58-35 : [DEPLOY] Production deployment completed successfully
2026-05-01-18-58-35 : [SMOKE] URL reachable: http://<REMOTE_HOST>
2026-05-01-18-58-35 : [END] Pipeline completed successfully
```

## Smart Detection

| Item | Value |
|---|---|
| Project type | `node` |
| App kind | `frontend` |
| Build command | `npm run build` from `package.json` |
| Deploy source | `dist` |
| Remote target | `/var/www/mohamededderyouch.me` |
| Remote setup | enabled automatically |
| Setup packages | `nginx rsync curl` |
| Smoke URL | `http://<REMOTE_HOST>` |

## Remote State After Deploy

```text
nginx=active
/usr/sbin/nginx
/usr/bin/rsync
/usr/bin/curl
portfolio_index_present
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

Generated nginx config:

```nginx
server {
    listen 80;
    server_name <REMOTE_HOST>;
    root /var/www/mohamededderyouch.me;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

## Smoke Verification

PipePilot:

```text
[OK]  Smoke URL reachable: http://<REMOTE_HOST>
```

Manual HTTP check:

```text
10:  <title>ED Deryouch | Full Stack Developer (React & MERN)</title>
13:    content="ED Deryouch is a Full Stack Developer specializing in React, JavaScript, MERN Stack, and high-performance web applications." />
15:  <meta name="author" content="ED Deryouch" />
20:  <meta property="og:title" content="ED Deryouch| Full Stack Developer" />
21:  <meta property="og:description" content="Portfolio of ED Deryouch - Full Stack Developer (React, MERN Stack)" />
26:  <meta name="twitter:title" content="ED Deryouch | Full Stack Developer" />
33:  <script type="module" crossorigin src="/assets/index-BhhYy0J8.js"></script>
34:  <link rel="stylesheet" crossorigin href="/assets/index-C8EPu4Zx.css">
```

## Notes

- PipePilot output is clean and orientational by default.
- Noisy command details are preserved in the raw log instead of flooding stdout.
- `-v` can still be used when raw command output should stream to the terminal.
- Lint issues are visible as a warning because `--strict` was not enabled.
- Node tests were skipped automatically because there is no `test` script.
