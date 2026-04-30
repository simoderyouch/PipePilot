# Versioning Strategy

PipePilot follows semantic versioning with this format:

```text
MAJOR.MINOR.PATCH
```

- `MAJOR` increases when an option or behavior changes in a way that can break
  existing commands.
- `MINOR` increases when a new compatible feature is added, such as a new
  deployment option or execution mode.
- `PATCH` increases when bugs are fixed without changing how users run the
  program.

## Current Version

The current version is stored in the repository root `VERSION` file. The
`pipepilot --version` command reads that file, so the command line and the
repository always show the same release number.

## Release Workflow

1. Update `VERSION`.
2. Add a dated entry to `CHANGELOG.md`.
3. Commit the implementation with a clear message.
4. Create a Git tag such as `v0.1.0`.
5. Push both commits and tags to GitHub.

## Why This Matters

Versioning makes deployments safer because every archive, rollback, and log line
can be linked to a known project release. It also demonstrates professional
software lifecycle management for the academic project.

