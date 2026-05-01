# PipePilot Usage

PipePilot follows standard Linux command-line syntax:

```bash
./pipepilot [OPTIONS] -p <project_path>
```

## Common Commands

Run a staging deployment:

```bash
./pipepilot -p /path/to/app -e staging -v
```

Run in dry-run production mode:

```bash
./pipepilot -d -p /path/to/app -e production -v
```

Run fork mode:

```bash
./pipepilot -f -p /path/to/app -e staging
```

Run thread-simulation mode:

```bash
./pipepilot -t -p /path/to/app -e staging
```

Run manual rollback:

```bash
sudo ./pipepilot -r -p /path/to/app --target /deploy/target
```

## Remote Deployment Mode

Remote mode is an advanced implementation of Step 6. PipePilot still runs pull,
lint, tests, build, and archive locally, then uploads the deploy directory to a
remote Linux server through SSH.

Frontend example:

```bash
./pipepilot \
  -p ./frontend \
  -e production \
  --remote \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/server_key.pem
```

Backend example:

```bash
./pipepilot \
  -p ./backend \
  -e production \
  --remote \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/server_key.pem \
  --target /home/ubuntu/apps/backend \
  --remote-cmd "cd /home/ubuntu/apps/backend && npm install --production" \
  --restart backend \
  --url https://api.myserver.com/health
```

Custom SSH port and scp transfer:

```bash
./pipepilot \
  -p ./app \
  -e production \
  --remote \
  --host 192.168.1.50 \
  --user deploy \
  --key ~/.ssh/id_rsa \
  --ssh-port 2222 \
  --target /srv/apps/app \
  --transfer scp \
  --url http://192.168.1.50:8080
```

Required remote options are `--host`, `--user`, and `--key`. Remote mode can
infer `--target`, `--deploy-dir`, `--setup-server`, `--domain`, and `--url`.
Optional remote controls are `--ssh-port`, `--target`, `--deploy-dir`,
`--remote-cmd`, `--restart`, `--transfer`, and `--no-setup-server`.

## Smart Fresh-Server Setup

In remote mode, PipePilot enables server setup automatically unless
`--no-setup-server` is provided. It connects through SSH before upload, detects
or uses the selected package manager, installs the packages needed for the app
type, creates the target directory, and can generate a simple nginx
configuration.

Static frontend on a fresh VPS:

```bash
./pipepilot \
  -p ./frontend \
  -e production \
  --remote \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/server_key.pem
```

Node backend with nginx reverse proxy:

```bash
./pipepilot \
  -p ./backend \
  -e production \
  --remote \
  --setup-server \
  --app-kind backend \
  --backend-runtime node \
  --host api.myserver.com \
  --user ubuntu \
  --key ~/.ssh/server_key.pem \
  --target /srv/backend \
  --app-port 3000 \
  --domain api.myserver.com \
  --remote-cmd "cd /srv/backend && npm install --production" \
  --restart backend \
  --url https://api.myserver.com/health
```

Useful setup options:

```text
--setup-server          Enable fresh-server provisioning
--app-kind <kind>       auto | frontend | backend
--backend-runtime <rt>  auto | python | node
--domain <domain>       nginx server_name for frontend/proxy configs
--app-port <port>       backend port for nginx reverse proxy
--start-cmd "<cmd>"     backend start command; auto-detected when omitted
--service-name <name>   systemd service name; generated when omitted
--package-manager <pm>  auto | apt | dnf | yum | apk
--setup-cmd "<cmd>"     extra remote setup command before upload
```

With `--app-kind auto`, PipePilot uses local project detection and deployment
arguments to infer the setup. A project that uploads `dist/`, `build/`, or
`public/` is treated like a frontend. A project with `--app-port` or a Python
project is treated like a backend. Backend runtime can be selected explicitly
with `--backend-runtime python` or `--backend-runtime node`.

## Smart Backend Runtime

For remote backend deployments, PipePilot now does more than upload files. After
transfer it installs production dependencies and starts the backend as a
service:

- Python: creates `.venv`, installs `requirements.txt`, detects FastAPI, Flask,
  `app.py`, or `main.py`.
- Node.js: installs production dependencies and detects `npm start`,
  `server.js`, `app.js`, `index.js`, or `main.js`.
- systemd: creates and restarts a service automatically.
- Override: use `--start-cmd` or `--service-name` when your app needs a custom
  command or service name.

When a frontend and backend share the same host, generated nginx configuration
keeps the frontend at `/` and proxies the backend under `/api/`. Use a smoke URL
such as `http://example.com/api/health` for that combined layout.

Python backend with automatic FastAPI detection:

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
  --key ~/.ssh/server_key.pem \
  --target /srv/backend \
  --app-port 8000 \
  --domain api.myserver.com
```

Node backend with a custom start command:

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
  --key ~/.ssh/server_key.pem \
  --target /srv/api \
  --app-port 3000 \
  --start-cmd "node server.js" \
  --service-name pipepilot-api
```

## Logs

PipePilot keeps normal terminal output clean and orientational. A typical run
shows stage state, smart inference, setup state, the final target, and the raw
log path:

```text
[RUN] BUILD
[OK]  BUILD
[RUN] DEPLOY
[SMART] Target: /var/www/app
[SMART] Deploy source: dist
[SMART] Setup: enabled
[SETUP] kind=frontend runtime=none packages="nginx rsync curl"
[OK]  DEPLOY
[RUN] SMOKE
[OK]  Smoke URL reachable: http://example.com
```

PipePilot writes structured log entries in this format:

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

By default, structured logs are written to `logs/history.log`, and noisy command
output is written to `logs/run-<timestamp>-<pid>.raw.log`. Use `-l <dir>` for a
custom location. Use `-v` to stream raw command output directly to the terminal.

## Pipeline Stage Files

Each pipeline step is stored in its own file under `stages/`:

```text
01_pull.sh     Pull or clone source code
02_lint.sh     Run static analysis
03_test.sh     Execute unit tests
04_build.sh    Build or package the project
05_archive.sh  Create rollback archive
06_deploy.sh   Deploy locally or remotely
07_smoke.sh    Verify deployment health
```

The main `pipepilot` file handles arguments, configuration, logging, rollback,
and execution modes, then sources these stage files.

## Report Paragraph

PipePilot includes a Remote Deployment Mode that allows deployment to any Linux
server accessible through SSH. The user provides the remote host, SSH username,
private key, SSH port, target directory, and optional post-deployment commands.
PipePilot can also prepare a fresh server automatically with `--setup-server`:
it detects the application type, installs the required packages, creates the
remote target directory, and can configure nginx for frontend hosting or
backend reverse proxying. During deployment, PipePilot transfers files using
rsync or scp, executes remote commands through ssh, and verifies the deployment
using smoke tests such as curl or nc. This makes the tool independent from a
specific cloud provider and compatible with VPS servers, dedicated servers,
cloud virtual machines, and local network servers.
