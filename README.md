# PipePilot

![PipePilot banner](assets/pipepilot_banner.jpg)

**Automate. Validate. Deploy. Rollback safely.**

PipePilot is a Bash-powered CI/CD deployment assistant for frontend and backend
projects. It runs the full release path from source recovery to smoke testing,
can prepare a fresh Linux server over SSH, and can start Python or Node.js
backends as managed services.

## Why PipePilot

PipePilot is built for small teams, VPS deployments, internal tools, and
lightweight production workflows where a full CI/CD platform would be too heavy.
It keeps the deployment process visible and scriptable while still handling the
repetitive parts: builds, archives, server setup, file transfer, service
restart, smoke checks, and rollback.

## Pipeline

Every run follows the same seven-step pipeline:

```text
Pull -> Lint -> Test -> Build -> Archive -> Deploy -> Smoke Test
```

If a deployment or smoke test fails, PipePilot logs the failure and attempts to
restore the latest archive.

## Features

- Frontend deployment with automatic `dist/`, `build/`, or `public/` upload.
- Backend deployment for Python and Node.js projects.
- Smart fresh-server setup through SSH with `--setup-server`.
- Automatic backend dependency installation after upload.
- Automatic backend service creation with systemd.
- Python backend start detection for FastAPI, Flask, `app.py`, and `main.py`.
- Node.js backend start detection for `npm start`, `server.js`, `app.js`,
  `index.js`, and `main.js`.
- Remote transfer through `rsync` or `scp`.
- nginx setup for frontend hosting and backend reverse proxying.
- Structured deployment logs in `history.log`.
- Timestamped rollback archives.
- Dry-run mode for safe production simulation.
- Sequential, subshell, fork, and background-job execution modes.
- Semantic versioning with release tags.

## Requirements

Local machine:

- Bash
- Git
- SSH client
- `rsync` or `scp` for remote deployment
- Node.js/npm for Node projects
- Python 3 for Python projects

Remote server:

- Linux with SSH access
- A user with permission to create the target directory
- `sudo` access when using `--setup-server` for package installation, nginx, or
  systemd service creation

## Security Notes

- Keep SSH private keys outside the repository, for example under `~/.ssh/`.
- Do not commit real server IP addresses, private hostnames, or deployment-only
  URLs in public documentation.
- Use placeholder hosts such as `myserver.com` or `api.example.com` in examples.
- Review generated logs and scenario notes before publishing; remote deployment
  output can include hosts, target paths, and smoke-test URLs.

## Installation

```bash
git clone https://github.com/simoderyouch/PipePilot.git
cd PipePilot
chmod +x pipepilot
./pipepilot --version
```

## Quick Start

Run a local staging deployment:

```bash
./pipepilot -p /path/to/app -e staging -v
```

Preview a production deployment without changing anything:

```bash
./pipepilot -d -p /path/to/app -e production -v
```

Show all options:

```bash
./pipepilot -h
```

## Frontend Deployment

Deploy an already configured frontend project. PipePilot detects the build
script, chooses `dist/`, `build/`, `out/`, or `public/`, prepares nginx, picks a
remote target, and smoke-tests the public URL:

```bash
./pipepilot \
  -p ./frontend \
  -e production \
  --remote \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key
```

Override the smart defaults when a deployment needs a custom path, output
folder, or domain:

```bash
./pipepilot \
  -p ./frontend \
  -e production \
  --remote \
  --setup-server \
  --app-kind frontend \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key \
  --target /var/www/frontend \
  --deploy-dir dist \
  --domain myserver.com
```

## Backend Deployment

Deploy a Python backend and let PipePilot create the service automatically:

```bash
./pipepilot \
  -p ./backend \
  -e production \
  --remote \
  --setup-server \
  --app-kind backend \
  --backend-runtime python \
  --host api.myserver.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key \
  --target /srv/backend \
  --app-port 8000 \
  --domain api.myserver.com \
  --url https://api.myserver.com/health
```

Deploy a Node.js backend with a custom start command:

```bash
./pipepilot \
  -p ./api \
  -e production \
  --remote \
  --setup-server \
  --app-kind backend \
  --backend-runtime node \
  --host api.myserver.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key \
  --target /srv/api \
  --app-port 3000 \
  --start-cmd "node server.js" \
  --service-name pipepilot-api \
  --url https://api.myserver.com/health
```

## Smart Backend Runtime

When `--app-kind backend` is used, PipePilot can infer how to run the app:

| Runtime | Automatic behavior |
|---|---|
| Python | Creates `.venv`, installs `requirements.txt`, detects FastAPI, Flask, `app.py`, or `main.py` |
| Node.js | Installs production dependencies, detects `npm start`, `server.js`, `app.js`, `index.js`, or `main.js` |
| systemd | Creates, enables, and restarts a service automatically |
| nginx | Creates a reverse proxy when `--domain` and `--app-port` are provided |

Use `--start-cmd` and `--service-name` when your backend needs explicit control.

## Port Options

PipePilot uses three different port options, depending on what part of the
deployment you want to control:

| Option | Used for |
|---|---|
| `--ssh-port <port>` | SSH connection port for remote upload and remote commands; defaults to `22` |
| `--app-port <port>` | Backend application port used by systemd and nginx reverse proxy configuration |
| `--port <port>` | Smoke-test port check, useful when you want to verify that a TCP port is reachable |

Example backend deployment with explicit SSH, app, and smoke-test ports:

```bash
./pipepilot \
  -p ./backend \
  -e production \
  --remote \
  --setup-server \
  --app-kind backend \
  --backend-runtime python \
  --host api.example.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key \
  --ssh-port 2222 \
  --app-port 8000 \
  --port 443 \
  --url https://api.example.com/health
```

For backend services, `--app-port` is the port the app listens on behind nginx.
For smoke tests, `--url` checks an HTTP endpoint and `--port` checks whether a
network port is reachable.

## Environment Handling

PipePilot loads configuration in this order:

```text
configs/default.conf
configs/<environment>.conf
command-line options
```

The environment is selected with `-e staging` or `-e production`. If `-e` is not
provided, PipePilot uses `DEFAULT_ENV` from `configs/default.conf`.

Environment files can define deployment defaults such as:

```text
TARGET_PATH
REMOTE_HOST
REMOTE_USER
REMOTE_KEY
SSH_PORT
DEPLOY_DIR
APP_KIND
BACKEND_RUNTIME
DOMAIN_NAME
APP_PORT
SMOKE_URL
SMOKE_PORT
```

Command-line options always win over config values, so a team can keep safe
defaults in `configs/staging.conf` and `configs/production.conf`, then override
one run with flags like `--target`, `--ssh-port`, `--app-port`, or `--url`.

## Example Backend API Scenario

The repository includes a small FastAPI backend example at
`examples/exemples/python-backend-api`. It is useful for demonstrating a full
remote backend deployment from a clean Linux server state.

The example API exposes:

- `GET /`
- `GET /health`
- `GET /items`
- `GET /items/{item_id}`

Deploy it with smart defaults:

```bash
./pipepilot \
  -p examples/exemples/python-backend-api \
  -e production \
  --remote \
  --host api.example.com \
  --user ubuntu \
  --key ~/.ssh/pipepilot_deploy_key
```

PipePilot detects the Python backend, uploads the project to a generated
`/srv/<project-name>` target, installs backend dependencies on the remote
server, creates a systemd service, configures nginx as a reverse proxy, and
smoke-tests the inferred URL.

The expected successful run includes these high-level events:

```text
[DETECT] project_type=python
[SMART] target=/srv/python-backend-api
[SMART] deploy_source=.
[SMART] setup=enabled
[SETUP] app_kind=backend runtime=python packages="python3 python3-pip python3-venv nginx rsync curl"
[OK]  Remote setup completed
[OK]  Uploaded files
[OK]  Smoke URL reachable
[OK]  Pipeline completed successfully
```

The detailed scenario notes live in `backend_senario.md`; keep that file
sanitized before publishing because deployment logs can contain real hosts,
URLs, and local key paths.

## Important Options

| Option | Purpose |
|---|---|
| `-p <path>` | Project path to deploy |
| `-e staging\|production` | Target environment |
| `-d`, `--dry-run` | Simulate actions without changing deployment targets |
| `--remote` | Enable SSH remote deployment |
| `--setup-server` | Prepare a fresh Linux server before upload; remote mode enables this automatically unless disabled |
| `--no-setup-server` | Disable automatic remote server preparation |
| `--app-kind frontend\|backend` | Tell PipePilot what kind of app is being deployed; defaults to auto |
| `--backend-runtime python\|node` | Select backend runtime |
| `--host <host>` | Remote server hostname or domain |
| `--user <user>` | SSH username |
| `--key <path>` | SSH private key |
| `--ssh-port <port>` | SSH connection port; defaults to `22` |
| `--target <path>` | Deployment directory; remote mode infers `/var/www/<name>` for frontends and `/srv/<name>` for backends |
| `--deploy-dir <dir>` | Local build directory to upload; auto-detects `dist`, `build`, `out`, or `public` |
| `--domain <domain>` | nginx server name; inferred from `--host` when the host is a domain name |
| `--app-port <port>` | Backend port for reverse proxy and service env |
| `--start-cmd "<cmd>"` | Override backend start command |
| `--service-name <name>` | Override generated systemd service name |
| `--url <url>` | Smoke-test URL; remote mode infers `http://<domain-or-host>` |
| `--port <port>` | Smoke-test port |

## Execution Modes

```bash
./pipepilot -p ./app -e staging          # sequential
./pipepilot -s -p ./app -e staging       # subshell
./pipepilot -f -p ./app -e staging       # forked stages
./pipepilot -t -p ./app -e staging       # background-job mode
```

## Logs And Archives

Normal mode prints a compact run summary to the terminal:

```text
PipePilot run
Project: /path/to/app
Environment: production
Structured log: logs/history.log
Raw output: logs/run-2026-05-01-13-09-26-12345.raw.log

[RUN] GIT
[OK]  GIT
[RUN] DEPLOY
[SMART] Target: /var/www/app
[SMART] Deploy source: dist
[SETUP] kind=frontend runtime=none packages="nginx rsync curl"
[OK]  Pipeline completed successfully
```

Detailed command output from tools such as `npm`, `apt`, `rsync`, and `ssh` is
stored in a per-run raw log. Use `-v` when you want that raw output streamed to
the terminal.

Structured logs are written in this format:

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

Default paths:

```text
logs/history.log
logs/run-<timestamp>-<pid>.raw.log
archives/
```

Use `-l <dir>` for a custom log directory and `--archive-dir <dir>` for custom
archives.

## Project Structure

```text
PipePilot/
├── pipepilot                  # CLI and pipeline orchestrator
├── stages/                    # One file for each pipeline step
│   ├── 01_pull.sh
│   ├── 02_lint.sh
│   ├── 03_test.sh
│   ├── 04_build.sh
│   ├── 05_archive.sh
│   ├── 06_deploy.sh
│   └── 07_smoke.sh
├── configs/                   # Environment defaults
├── hooks/                     # Pre/post deploy extension points
├── tests/                     # Runnable deployment scenarios
├── docs/                      # Usage and versioning notes
├── assets/                    # README banner and logo images
├── VERSION
└── CHANGELOG.md
```

## Testing

Run all scenarios:

```bash
./tests/run_all.sh
```

Run the remote dry-run scenario only:

```bash
./tests/test_remote_dry_run.sh
```

The tests create temporary projects under `tests/tmp/` and do not require a real
remote server.

## Versioning

PipePilot uses semantic versioning. The current version is stored in `VERSION`,
release notes are in `CHANGELOG.md`, and release tags are published as `vX.Y.Z`.

## Documentation

- [Usage guide](docs/USAGE.md)
- [Test scenarios](docs/TEST_SCENARIOS.md)
- [Versioning strategy](docs/VERSIONING.md)
- [Project specification](pipepilot_project_specification.md)
