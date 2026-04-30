# PipePilot

![PipePilot logo](assets/logo.svg)

**Automate. Validate. Deploy. Rollback safely.**

PipePilot is a Bash-based CI/CD automation tool for frontend and backend
projects. It automates a production-style seven-step deployment pipeline:

1. Pull source code
2. Lint/static analysis
3. Unit tests
4. Build
5. Archive/version backup
6. Deploy
7. Smoke test with rollback support

The implementation follows the detailed specification in
`pipepilot_project_specification.md`.

## Quick Start

```bash
chmod +x pipepilot
./pipepilot -h
./pipepilot -p /path/to/app -e staging -v
```

## Project Structure

```text
configs/     Environment configuration files
stages/      One Bash file for each of the seven pipeline steps
hooks/       Pre-deploy and post-deploy extension scripts
tests/       Runnable pipeline and deployment scenarios
archives/    Runtime rollback archives
logs/        Runtime history.log output
docs/        Usage, tests, and versioning notes
```

## Versioning

PipePilot uses semantic versioning. The current version is stored in `VERSION`,
and release notes are tracked in `CHANGELOG.md`.

## Test Scenarios

```bash
./tests/run_all.sh
```

The scenarios build temporary frontend and backend projects under `tests/tmp/`
and demonstrate sequential, subshell, and thread-simulation execution.

## Remote Deployment

PipePilot can deploy to any Linux server that accepts SSH:

```bash
./pipepilot -p ./frontend -e production --remote \
  --host myserver.com --user ubuntu --key ~/.ssh/server_key.pem \
  --target /var/www/frontend --deploy-dir dist \
  --build-cmd "npm run build" --url https://myserver.com
```

For a fresh server, add `--setup-server` so PipePilot installs the needed
packages and prepares the target path based on the app type:

```bash
./pipepilot -p ./frontend -e production --remote --setup-server \
  --app-kind frontend --host myserver.com --user ubuntu \
  --key ~/.ssh/server_key.pem --target /var/www/frontend \
  --deploy-dir dist --domain myserver.com
```

For backends, PipePilot can install dependencies and create a systemd service
automatically:

```bash
./pipepilot -p ./backend -e production --remote --setup-server \
  --app-kind backend --backend-runtime python --host api.myserver.com \
  --user ubuntu --key ~/.ssh/server_key.pem --target /srv/backend \
  --app-port 8000 --domain api.myserver.com
```
