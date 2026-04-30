# PipePilot

**Automate. Validate. Deploy. Rollback safely.**

PipePilot is a Bash-based CI/CD automation tool for academic Linux and operating
systems practice. The project automates a seven-step deployment pipeline:

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
tests/       Three runnable academic test scenarios
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

The scenarios build temporary Shell, Python, and C projects under `tests/tmp/`
and demonstrate sequential, subshell, and thread-simulation execution.

## Remote Deployment

PipePilot can deploy to any Linux server that accepts SSH:

```bash
./pipepilot -p ./frontend -e production --remote \
  --host myserver.com --user ubuntu --key ~/.ssh/server_key.pem \
  --target /var/www/frontend --deploy-dir dist \
  --build-cmd "npm run build" --url https://myserver.com
```
