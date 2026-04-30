# Changelog

All notable PipePilot changes are tracked here to demonstrate clear project
versioning. The format follows the spirit of Keep a Changelog, and releases use
semantic version numbers from `VERSION`.

## [0.3.0] - 2026-04-30

### Added

- Remote Deployment Mode with `--remote`, SSH key authentication, custom SSH
  port, `rsync` or `scp` transfer, remote commands, and remote service restart.
- Remote deployment validation for required host, user, key, target path, and
  transfer tool.
- Dry-run remote deployment scenario for safe testing without a real server.

## [0.2.0] - 2026-04-30

### Changed

- Split the seven CI/CD pipeline steps into separate files under `stages/`.
- Kept `pipepilot` as the CLI, configuration, logging, rollback, and execution
  mode orchestrator.
- Documented the new stage-file layout in the README and usage guide.

## [0.1.0] - 2026-04-30

### Added

- Initial repository identity for PipePilot.
- Project structure for configs, hooks, tests, archives, logs, and docs.
- Versioning files for teacher-visible release history.
- Fully commented PipePilot Bash CLI.
- Three runnable academic test scenarios.
- Usage and scenario documentation.
