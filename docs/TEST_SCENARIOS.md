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

## Scenario 3 - Heavy

```bash
./tests/test_heavy.sh
```

- Project type: C
- Execution mode: thread simulation
- Validates: background jobs, C compilation, `make test`, production dry-run

## Run Everything

```bash
./tests/run_all.sh
```

Runtime logs are written to `tests/tmp/logs/`, and generated archives are
written to `tests/tmp/archives/`.

