# Changelog

All notable PipePilot changes are tracked here to demonstrate clear project
versioning. The format follows the spirit of Keep a Changelog, and releases use
semantic version numbers from `VERSION`.

## [0.9.0] - 2026-05-02

### Added

- Dockerfile and Docker Compose deployment support for full-stack projects.
- Automatic stack detection for Compose projects and Docker runtime detection
  for single-Dockerfile projects.
- Remote Docker setup for fresh Linux servers during PipePilot deployments.
- Docker stack scenario notes in `docker_senarios.md`.

### Changed

- Remote deployment can now treat multi-service frontend/backend projects as a
  `stack` and run Compose after upload.
- Build logic defers Docker builds to the remote server for remote deployments.

## [0.8.0] - 2026-05-01

### Added

- Automatic remote defaults for production frontend and backend deployments.
- Remote setup helper for fresh-server nginx, dependency, and proxy setup.
- Clean production deployment scenario notes for the portfolio and backend API.
- Backend API deployment documentation for port `6000` behind `/api/`.

### Changed

- Kept normal PipePilot output cleaner while preserving raw command logs.
- Updated remote usage docs to explain inferred targets, deploy sources, setup,
  and shared frontend/backend nginx behavior.

## [0.7.3] - 2026-04-30

### Changed

- Updated the CLI startup banner to use `assets/pipepilot_logo.png` when the
  user's terminal has a supported image renderer.
- Added the PNG logo assets used by GitHub and the command-line interface.
- Updated project structure documentation to match the current logo assets.

## [0.7.2] - 2026-04-30

### Changed

- Expanded the README into a complete professional project overview.

## [0.7.1] - 2026-04-30

### Changed

- Replaced the first logo with a cleaner professional SVG wordmark.

## [0.7.0] - 2026-04-30

### Added

- GitHub-ready SVG logo.
- Terminal startup banner for the PipePilot CLI.

### Changed

- Updated public wording to present PipePilot as a professional CI/CD tool.

## [0.6.0] - 2026-04-30

### Added

- Automatic backend runtime configuration after remote upload.
- Backend start command detection for Python FastAPI/Flask/simple scripts and
  Node.js package/start files.
- Automatic production dependency installation and systemd service creation for
  remote backend deployments.
- `--start-cmd` and `--service-name` overrides.

## [0.5.0] - 2026-04-30

### Changed

- Refocused smart deployment around only `frontend` and `backend`.
- Added `--backend-runtime auto|python|node` for backend setup.
- Replaced the C heavy scenario with a Python backend scenario.

## [0.4.0] - 2026-04-30

### Added

- Smart fresh-server setup with `--setup-server`.
- App-aware provisioning.
- Optional nginx setup with `--domain` and backend reverse proxy support with
  `--app-port`.
- Package-manager selection with `--package-manager auto|apt|dnf|yum|apk`.
- Custom remote provisioning commands with `--setup-cmd`.

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
- Versioning files for release history.
- Fully commented PipePilot Bash CLI.
- Three runnable pipeline scenarios.
- Usage and scenario documentation.
