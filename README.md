# PipePilot

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
