# Test Scenarios

The `tests/` directory contains the three scenarios required by the project
specification. Each script creates its own temporary demo project under
`tests/tmp/`, so the repository stays clean after the tests finish.

## Scenario 1 - Light

```bash
./tests/test_light.sh
```

- Project type: Shell
- Execution mode: sequential
- Validates: lint, tests, archive, local deploy, logging

## Scenario 2 - Medium

```bash
./tests/test_medium.sh
```

- Project type: Python
- Execution mode: subshell
- Validates: Python syntax checking, tests, isolated pipeline execution

## Scenario 3 - Backend

```bash
./tests/test_heavy.sh
```

- Project type: Backend Python
- Execution mode: thread simulation
- Validates: background jobs, backend tests, production dry-run

## Run Everything

```bash
./tests/run_all.sh
```

Runtime logs are written to `tests/tmp/logs/`, and generated archives are
written to `tests/tmp/archives/`.

## Extra Scenario - Remote Dry Run

```bash
./tests/test_remote_dry_run.sh
```

- Project type: frontend
- Execution mode: sequential
- Validates: `--remote`, `--setup-server`, app-kind provisioning, SSH key
  validation, `--deploy-dir`, `--remote-cmd`, `--restart`, and `--transfer scp`
  without contacting a real server
