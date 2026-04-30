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

## Logs

PipePilot writes structured log entries in this format:

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

By default, logs are written to `logs/history.log`. Use `-l <dir>` for a custom
location.

