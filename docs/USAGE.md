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
  --key ~/.ssh/server_key.pem \
  --target /var/www/frontend \
  --deploy-dir dist \
  --build-cmd "npm run build" \
  --url https://myserver.com
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

Required remote options are `--host`, `--user`, `--key`, and `--target`.
Optional remote controls are `--ssh-port`, `--deploy-dir`, `--remote-cmd`,
`--restart`, and `--transfer`.

## Smart Fresh-Server Setup

When the remote server is new and has no tools installed yet, use
`--setup-server`. PipePilot connects through SSH before upload, detects or uses
the selected package manager, installs the packages needed for the app type,
creates the target directory, and can generate a simple nginx configuration.

Static frontend on a fresh VPS:

```bash
./pipepilot \
  -p ./frontend \
  -e production \
  --remote \
  --setup-server \
  --app-kind frontend \
  --host myserver.com \
  --user ubuntu \
  --key ~/.ssh/server_key.pem \
  --target /var/www/frontend \
  --deploy-dir dist \
  --domain myserver.com \
  --build-cmd "npm run build" \
  --url https://myserver.com
```

Node backend with nginx reverse proxy:

```bash
./pipepilot \
  -p ./backend \
  -e production \
  --remote \
  --setup-server \
  --app-kind node \
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
--app-kind <kind>       auto | static | frontend | node | python | c | generic
--domain <domain>       nginx server_name for frontend/proxy configs
--app-port <port>       backend port for nginx reverse proxy
--package-manager <pm>  auto | apt | dnf | yum | apk
--setup-cmd "<cmd>"     extra remote setup command before upload
```

With `--app-kind auto`, PipePilot uses local project detection and deployment
arguments to infer the setup. For example, a Node project that uploads `dist/`
is treated like a frontend, while a Node project with `--app-port` is treated
like a backend service.

## Logs

PipePilot writes structured log entries in this format:

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

By default, logs are written to `logs/history.log`. Use `-l <dir>` for a custom
location.

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
remote target directory, and can configure nginx for static frontend hosting or
backend reverse proxying. During deployment, PipePilot transfers files using
rsync or scp, executes remote commands through ssh, and verifies the deployment
using smoke tests such as curl or nc. This makes the tool independent from a
specific cloud provider and compatible with VPS servers, dedicated servers,
cloud virtual machines, and local network servers.
