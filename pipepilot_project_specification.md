# PipePilot — Detailed Project Specification

> **Original project context:** This document is based on the provided mini-project PDF for a Bash CI/CD automation tool.  
> The app name has been improved from `deploymaster` to **PipePilot**, while keeping the same academic requirements, Linux concepts, options, error handling, logging format, execution modes, and 7-step deployment pipeline.

---

## 1. Project Identity

### 1.1 App Name

# **PipePilot**

### 1.2 Meaning

**PipePilot** means:

- **Pipe**: refers to the CI/CD pipeline.
- **Pilot**: the tool guides and controls the full deployment process.

So the name means:

> **A tool that pilots the deployment pipeline from source code to production.**

### 1.3 Slogan

> **Automate. Validate. Deploy. Rollback safely.**

### 1.4 Short Description

**PipePilot** is a Bash-based CI/CD automation tool that manages the complete deployment lifecycle of a software project.

It can:

- Pull or clone project source code.
- Detect the project type.
- Run lint/static analysis.
- Execute unit tests.
- Build or compile the project.
- Archive the current version.
- Deploy locally or remotely.
- Run smoke tests after deployment.
- Automatically rollback if something fails.
- Log every operation in a structured `history.log` file.
- Support multiple execution modes: sequential, subshell, fork, and thread simulation.

---

## 2. Academic Context

### 2.1 Project Type

**Mini Project — Operating Systems / Linux / Unix / Windows**

### 2.2 Main Objective

The goal of the project is to create a real Bash program that demonstrates Linux system concepts through a useful DevOps automation tool.

The program must respect the requirements from the PDF:

- Use Bash scripts.
- Use a required parameter.
- Provide at least 6 options.
- Include admin-only options.
- Use Linux commands and shell concepts.
- Implement logging in a `history.log` file.
- Use specific error codes.
- Display help after errors.
- Provide 3 test scenarios.
- Include a complete `-h` help/manual page.
- Demonstrate process management using fork, subshell, and background jobs.

---

## 3. Problem Statement

In modern software development, deploying an application often requires many manual steps:

1. Pull the latest code.
2. Check syntax and code quality.
3. Run tests.
4. Build the project.
5. Backup the current version.
6. Deploy the new version.
7. Verify that the application works.

Doing this manually can create many problems:

- Human errors.
- Forgotten steps.
- Wrong branch deployment.
- Wrong environment deployment.
- Lost time.
- No deployment history.
- Difficult debugging.
- No automatic rollback.
- Risk of breaking production.

---

## 4. Proposed Solution

**PipePilot** solves this problem by automating the complete CI/CD pipeline using Bash.

The tool executes the deployment pipeline in 7 steps:

```text
1. Pull
2. Lint
3. Test
4. Build
5. Archive
6. Deploy
7. Smoke Test
```

If an error happens in any important step, the tool:

1. Logs the error.
2. Displays the help documentation.
3. Stops execution with a specific error code.
4. Runs rollback when needed.

---

## 5. General Syntax

The program follows standard Linux command-line syntax:

```bash
pipepilot [OPTIONS] -p <project_path>
```

### Example

```bash
pipepilot -p /home/user/myapp -e staging -v
```

### Production Example

```bash
sudo pipepilot -p /home/user/myapp -e production -b main
```

---

## 6. Target Users

### 6.1 Developers

Developers can use PipePilot to automate daily deployment tasks during development.

Use cases:

- Test a project before deployment.
- Build a project quickly.
- Deploy to staging.
- Validate a branch.
- Run dry-run before production.

### 6.2 System Administrators

System administrators can use PipePilot to manage production deployments safely.

Use cases:

- Deploy to production.
- Manage rollbacks.
- Check logs.
- Use admin-only options.
- Deploy to remote servers using SSH/rsync/scp.

---

## 7. Project Architecture

Recommended project structure:

```text
pipepilot/
├── pipepilot                     # Main Bash script
├── configs/
│   ├── default.conf              # Default parameters
│   ├── staging.conf              # Staging environment configuration
│   └── production.conf           # Production environment configuration
├── hooks/
│   ├── pre-deploy.sh             # Script executed before deployment
│   └── post-deploy.sh            # Script executed after deployment
├── tests/
│   ├── test_light.sh             # Light test scenario
│   ├── test_medium.sh            # Medium test scenario
│   └── test_heavy.sh             # Heavy test scenario
├── archives/
│   └── app-yyyy-mm-dd-hh-mm.tar.gz
└── logs/
    └── history.log
```

For production usage, logs can also be stored in:

```text
/var/log/pipepilot/history.log
```

---

# 8. Detailed 7-Step CI/CD Pipeline

---

## Step 1 — Pull / Source Recovery

### 8.1.1 Goal

The goal of this step is to prepare the latest version of the project source code.

### 8.1.2 What PipePilot Does

PipePilot checks if the project is already a Git repository.

If yes, it runs:

```bash
git pull
```

It can also detect:

```bash
git branch --show-current
git rev-parse HEAD
git log -1 --pretty=format:'%an'
```

These commands help collect:

- Current branch.
- Latest commit hash.
- Commit author.
- Git status.

### 8.1.3 Optional Features to Add

#### Deploy a specific branch

```bash
-b <branch>
```

Example:

```bash
pipepilot -p /home/user/myapp -b develop
```

#### Clone a repository if the folder does not exist

```bash
--repo <repository_url>
```

Example:

```bash
pipepilot --repo https://github.com/user/app.git -p /home/user/app
```

#### Deploy a specific commit

```bash
--commit <commit_hash>
```

Example:

```bash
pipepilot -p /home/user/app --commit a3f2c1
```

### 8.1.4 Error Code

```text
103 = Git pull or git clone failed
```

### 8.1.5 Log Example

```text
2026-04-17-14-30-12 : mohamed : INFOS : [GIT] Pull OK -- branch main -- commit a3f2c1
```

---

## Step 2 — Lint / Static Code Analysis

### 8.2.1 Goal

The goal of this step is to detect syntax errors and code quality problems before testing or deployment.

### 8.2.2 What PipePilot Does

PipePilot detects the project type and runs the correct lint tool.

### 8.2.3 Shell Project

```bash
shellcheck script.sh
bash -n script.sh
```

### 8.2.4 Python Project

```bash
python -m py_compile file.py
pylint file.py
```

### 8.2.5 C Project

```bash
gcc -Wall -fsyntax-only file.c
```

### 8.2.6 Node.js Project

```bash
npm run lint
```

### 8.2.7 Optional Features to Add

#### Skip lint

```bash
--skip-lint
```

#### Strict mode

Stop the pipeline even on warnings:

```bash
--strict
```

#### Choose custom lint tool

```bash
--lint-tool <tool>
```

Example:

```bash
pipepilot -p ./myapp --lint-tool shellcheck
```

### 8.2.8 Error Code

```text
104 = Lint failed
```

### 8.2.9 Log Example

```text
2026-04-17-14-30-15 : mohamed : INFOS : [LINT] No syntax errors detected
```

---

## Step 3 — Test / Unit Testing

### 8.3.1 Goal

The goal of this step is to verify that the application works correctly before building and deploying.

### 8.3.2 What PipePilot Does

PipePilot searches for test files and runs them automatically.

Examples:

```bash
find . -name "test_*.sh"
find . -name "test_*.py"
```

### 8.3.3 Shell Tests

```bash
bash tests/test_light.sh
```

### 8.3.4 Python Tests

```bash
pytest
```

### 8.3.5 Node.js Tests

```bash
npm test
```

### 8.3.6 C Tests

```bash
make test
```

### 8.3.7 Optional Features to Add

#### Skip tests

```bash
--skip-tests
```

#### Run tests matching a pattern

```bash
--test-pattern <pattern>
```

Example:

```bash
pipepilot -p ./myapp --test-pattern auth
```

#### Stop after first failed test

```bash
--fail-fast
```

#### Generate coverage

```bash
--coverage
```

### 8.3.8 Error Code

```text
105 = Tests failed
```

### 8.3.9 Log Example

```text
2026-04-17-14-30-20 : mohamed : INFOS : [TEST] 12/12 tests passed successfully
```

---

## Step 4 — Build / Compilation or Packaging

### 8.4.1 Goal

The goal of this step is to create the final executable, package, or deployable build.

### 8.4.2 What PipePilot Does

PipePilot detects the build system and runs the correct command.

### 8.4.3 If `build.sh` Exists

```bash
./build.sh
```

### 8.4.4 If `Makefile` Exists

```bash
make
```

### 8.4.5 Node.js Project

```bash
npm install
npm run build
```

### 8.4.6 Python Project

```bash
pip install -r requirements.txt
```

### 8.4.7 C Project

```bash
gcc main.c -o app
```

### 8.4.8 Optional Features to Add

#### Skip build

```bash
--skip-build
```

#### Custom build command

```bash
--build-cmd "<command>"
```

Example:

```bash
pipepilot -p ./myapp --build-cmd "npm run build"
```

#### Clean before build

```bash
--clean
```

#### Install dependencies before build

```bash
--install-deps
```

### 8.4.9 Error Code

```text
106 = Build failed
```

### 8.4.10 Log Example

```text
2026-04-17-14-30-35 : mohamed : INFOS : [BUILD] Build successful -- artifact generated
```

---

## Step 5 — Archive / Backup Version

### 8.5.1 Goal

The goal of this step is to create a backup of the current version before deployment.

This backup is used for rollback if deployment fails.

### 8.5.2 What PipePilot Does

PipePilot creates a timestamped archive:

```bash
tar -czf app-2026-04-17-14-30.tar.gz ./myapp
```

Recommended archive path:

```text
archives/
```

or:

```text
/var/backups/pipepilot/
```

### 8.5.3 Optional Features to Add

#### Custom archive directory

```bash
--archive-dir <dir>
```

Example:

```bash
pipepilot -p ./myapp --archive-dir ./backups
```

#### Skip archive

```bash
--no-archive
```

#### Keep only the latest N archives

```bash
--keep <number>
```

Example:

```bash
pipepilot -p ./myapp --keep 5
```

#### Choose compression type

```bash
--compress gzip|xz|zip
```

### 8.5.4 Error Code

The PDF already includes rollback error code `109`.

You can add an optional archive-specific error code:

```text
111 = Archive failed
```

### 8.5.5 Log Example

```text
2026-04-17-14-30-36 : mohamed : INFOS : [ARCHIVE] app-2026-04-17-14-30.tar.gz created
```

---

## Step 6 — Deploy / Local or Remote Deployment

### 8.6.1 Goal

The goal of this step is to move the built application to the target environment.

### 8.6.2 What PipePilot Does

PipePilot supports local and remote deployment.

### 8.6.3 Local Deployment

```bash
cp -r build/ /var/www/app/
```

or:

```bash
rsync -av build/ /var/www/app/
```

### 8.6.4 Remote Deployment

```bash
rsync -av build/ user@server:/var/www/app/
```

or:

```bash
scp -r build/ user@server:/var/www/app/
```

### 8.6.5 Restart Remote Service

```bash
ssh user@server "systemctl restart app"
```

### 8.6.6 Environment Selection

```bash
-e <env>
```

Allowed environments:

```text
staging
production
```

Production deployment requires admin rights:

```bash
sudo pipepilot -p ./myapp -e production
```

### 8.6.7 Optional Features to Add

#### Remote host

```bash
--host <server>
```

#### SSH user

```bash
--user <username>
```

#### Target path

```bash
--target <path>
```

#### Restart service

```bash
--restart <service>
```

#### Dry-run mode

```bash
-d
```

or:

```bash
--dry-run
```

Example:

```bash
pipepilot -d -p ./myapp -e production -v
```

### 8.6.8 Error Codes

```text
107 = Deployment failed
110 = Permission denied / admin required
```

### 8.6.9 Log Example

```text
2026-04-17-14-30-40 : mohamed : INFOS : [DEPLOY] Staging deployment completed successfully
```

---

## Step 7 — Smoke Test / Post-Deployment Verification

### 8.7.1 Goal

The goal of this step is to verify that the deployed application is running correctly.

### 8.7.2 What PipePilot Does

PipePilot checks if the application is accessible after deployment.

### 8.7.3 Check URL

```bash
curl http://localhost:8080
```

### 8.7.4 Check Port

```bash
nc -z localhost 8080
```

### 8.7.5 Check Server

```bash
ping server_ip
```

### 8.7.6 Check Service Status

```bash
systemctl status app
```

### 8.7.7 Optional Features to Add

#### URL to test

```bash
--url <url>
```

Example:

```bash
pipepilot -p ./myapp --url http://localhost:8080/health
```

#### Port to test

```bash
--port <port>
```

#### Number of retries

```bash
--retries <number>
```

#### Timeout

```bash
--timeout <seconds>
```

#### Health endpoint

```bash
--health-path <path>
```

Example:

```bash
pipepilot -p ./myapp --health-path /api/health --retries 5
```

### 8.7.8 Error Code

```text
108 = Smoke test failed
```

### 8.7.9 Rollback Behavior

If the smoke test fails, PipePilot automatically restores the previous archived version.

### 8.7.10 Log Example

```text
2026-04-17-14-30-42 : mohamed : ERROR : [SMOKE] Port 8080 inaccessible -- code 108
2026-04-17-14-30-43 : mohamed : INFOS : [ROLLBACK] Restoring previous version
```

---

# 9. Complete Options Table

## 9.1 Required Parameter

| Option | Description | Required | Admin |
|---|---|---:|---:|
| `-p <path>` | Project path to deploy | Yes | No |

## 9.2 Main Options from the PDF

| Option | Description | Admin Required |
|---|---|---:|
| `-h` | Show complete documentation/help | No |
| `-f` | Fork mode: each stage runs in a child process | No |
| `-t` | Thread mode: independent modules run in parallel using background jobs | No |
| `-s` | Subshell mode: pipeline runs inside an isolated subshell | No |
| `-l <dir>` | Custom log directory | No |
| `-r` | Restore previous archived version | Yes |
| `-e <env>` | Target environment: `staging` or `production` | Only for production |
| `-b <branch>` | Git branch to deploy, default: `main` | No |
| `-d` | Dry-run: simulate without real deployment | No |
| `-v` | Verbose mode | No |

## 9.3 Extra Useful Options to Add

| Option | Description |
|---|---|
| `--repo <url>` | Clone repository if project does not exist |
| `--commit <hash>` | Deploy a specific commit |
| `--skip-lint` | Skip lint step |
| `--strict` | Treat warnings as errors |
| `--lint-tool <tool>` | Use a specific lint tool |
| `--skip-tests` | Skip test step |
| `--test-pattern <pattern>` | Run selected tests |
| `--fail-fast` | Stop testing after first failure |
| `--coverage` | Generate test coverage |
| `--skip-build` | Skip build step |
| `--build-cmd "<cmd>"` | Run a custom build command |
| `--clean` | Clean old build files before building |
| `--install-deps` | Install dependencies before building |
| `--archive-dir <dir>` | Custom archive directory |
| `--no-archive` | Skip archive creation |
| `--keep <number>` | Keep only last N archives |
| `--compress <type>` | Choose compression type |
| `--host <server>` | Remote deployment server |
| `--user <username>` | SSH username |
| `--target <path>` | Target deployment path |
| `--restart <service>` | Restart a system service after deploy |
| `--url <url>` | URL for smoke test |
| `--port <port>` | Port for smoke test |
| `--retries <number>` | Number of smoke test retries |
| `--timeout <seconds>` | Timeout for smoke test |
| `--health-path <path>` | Health endpoint path |

---

# 10. Execution Modes

---

## 10.1 Sequential Mode

This is the default mode.

Each step runs one after another:

```text
Pull → Lint → Test → Build → Archive → Deploy → Smoke
```

### Example

```bash
pipepilot -p /home/user/myapp -e staging
```

### Advantages

- Simple.
- Easy to debug.
- Predictable.

### Disadvantages

- Slower than parallel modes.

---

## 10.2 Subshell Mode `-s`

The full pipeline runs inside a subshell.

### Example

```bash
pipepilot -s -p /home/user/myapp -e staging
```

### Implementation Example

```bash
(
    source configs/staging.conf
    run_full_pipeline
)
```

### Advantages

- Isolated environment.
- Variables do not affect the parent shell.
- Good for safe testing.

### Disadvantages

- Not faster than sequential mode.

---

## 10.3 Fork Mode `-f`

Each stage runs as a child process.

### Example

```bash
pipepilot -f -p /home/user/myapp -e staging
```

### Implementation Example

```bash
stage_lint &
PID_LINT=$!
wait $PID_LINT || { log_error "Lint failed"; exit 104; }

stage_test &
PID_TEST=$!
wait $PID_TEST || { log_error "Tests failed"; exit 105; }

stage_build &
PID_BUILD=$!
wait $PID_BUILD || { log_error "Build failed"; exit 106; }
```

### Advantages

- Better process isolation.
- Good demonstration of Linux process management.
- Crash isolation is better than sequential mode.

### Disadvantages

- More complex to debug.

---

## 10.4 Thread Mode `-t`

This mode simulates threads using background jobs in Bash.

### Example

```bash
pipepilot -t -p /home/user/myapp -e staging -v
```

### Implementation Example

```bash
build_module_A &
build_module_B &
build_module_C &

wait
echo "All modules built successfully"
```

### Advantages

- Faster for multi-module projects.
- Good demonstration of jobs and background processes.

### Disadvantages

- Harder to debug.
- Not all pipeline steps can run in parallel.

---

# 11. Logging System

## 11.1 Log File

Default log file:

```text
/var/log/pipepilot/history.log
```

Alternative local log file:

```text
logs/history.log
```

Custom log directory can be provided using:

```bash
-l <dir>
```

Example:

```bash
pipepilot -p ./myapp -l ./logs
```

## 11.2 Required Log Format

The project must respect the PDF format:

```text
yyyy-mm-dd-hh-mm-ss : username : INFOS : message
yyyy-mm-dd-hh-mm-ss : username : ERROR : message
```

## 11.3 Log Function Examples

```bash
LOG_DIR="/var/log/pipepilot"
LOG_FILE="$LOG_DIR/history.log"

log_info() {
    local msg="$1"
    local ts
    ts=$(date "+%Y-%m-%d-%H-%M-%S")
    local entry="$ts : $USER : INFOS : $msg"
    echo "$entry" | tee -a "$LOG_FILE"
}

log_error() {
    local msg="$1"
    local ts
    ts=$(date "+%Y-%m-%d-%H-%M-%S")
    local entry="$ts : $USER : ERROR : $msg"
    echo "$entry" | tee -a "$LOG_FILE" >&2
}
```

## 11.4 Full Log Example

```text
2026-04-17-14-30-10 : mohamed : INFOS : [START] Pipeline started -- /home/mohamed/app
2026-04-17-14-30-12 : mohamed : INFOS : [GIT] Pull OK -- branch main -- commit a3f2c1
2026-04-17-14-30-15 : mohamed : INFOS : [LINT] No syntax errors detected
2026-04-17-14-30-20 : mohamed : INFOS : [TEST] 12/12 tests passed successfully
2026-04-17-14-30-35 : mohamed : INFOS : [BUILD] Build successful -- artifact generated
2026-04-17-14-30-36 : mohamed : INFOS : [ARCHIVE] app-2026-04-17-14-30.tar.gz created
2026-04-17-14-30-40 : mohamed : INFOS : [DEPLOY] Staging deployment completed successfully
2026-04-17-14-30-42 : mohamed : ERROR : [SMOKE] Port 8080 inaccessible -- code 108
2026-04-17-14-30-43 : mohamed : INFOS : [ROLLBACK] Restoring previous version
```

---

# 12. Error Management

## 12.1 Error Codes Required by the PDF

| Code | Name | Description |
|---:|---|---|
| `0` | Success | Pipeline completed successfully |
| `100` | Unknown option | The option is not recognized |
| `101` | Missing parameter | Required `-p` parameter is missing |
| `102` | Project not found | Project directory does not exist |
| `103` | Git failure | `git pull` or `git clone` failed |
| `104` | Lint failure | Syntax or static analysis errors |
| `105` | Test failure | One or more tests failed |
| `106` | Build failure | Compilation or build failed |
| `107` | Deployment failure | File transfer or deployment failed |
| `108` | Smoke test failure | Application is not accessible after deployment |
| `109` | Rollback failure | Restore operation failed |
| `110` | Permission denied | Admin/root permission required |

## 12.2 Optional Extra Error Codes

| Code | Name | Description |
|---:|---|---|
| `111` | Archive failure | Archive creation failed |
| `112` | Config failure | Invalid or missing config file |
| `113` | Dependency failure | Required command is missing |
| `114` | Hook failure | Pre-deploy or post-deploy hook failed |

## 12.3 Required Behavior on Error

When an error occurs, PipePilot must:

1. Write the error to `history.log`.
2. Trigger rollback if the pipeline was already in the deployment phase.
3. Display the help documentation using `show_help()`.
4. Exit with the correct error code.

Example:

```bash
log_error "[BUILD] Build failed -- code 106"
show_help
exit 106
```

---

# 13. Rollback System

## 13.1 Goal

Rollback restores the previous working version if deployment fails.

## 13.2 When Rollback Is Triggered

Rollback should run when failure happens during:

- Build phase after archive was created.
- Deploy phase.
- Smoke test phase.

## 13.3 Manual Rollback

The user can manually restore the previous version using:

```bash
sudo pipepilot -r -p /home/user/myapp
```

## 13.4 Admin Requirement

Rollback requires admin rights because it can modify deployed files.

Check admin rights:

```bash
if [ "$EUID" -ne 0 ]; then
    log_error "Permission denied: rollback requires root"
    exit 110
fi
```

## 13.5 Rollback Error

```text
109 = Rollback failed
```

---

# 14. Hooks System

PipePilot can support external scripts before and after deployment.

## 14.1 Pre-Deploy Hook

Path:

```text
hooks/pre-deploy.sh
```

This script runs before deployment.

Possible uses:

- Stop service.
- Check disk space.
- Notify team.
- Prepare target directory.

Example:

```bash
bash hooks/pre-deploy.sh
```

## 14.2 Post-Deploy Hook

Path:

```text
hooks/post-deploy.sh
```

This script runs after deployment.

Possible uses:

- Restart service.
- Clear cache.
- Send notification.
- Check logs.

Example:

```bash
bash hooks/post-deploy.sh
```

---

# 15. Linux Concepts Implemented

| Linux Concept | Commands / Syntax | Usage in PipePilot |
|---|---|---|
| Variables | `VAR=value`, `$VAR` | Store paths, env, branch, log file |
| Environment | `export`, `source` | Load config files |
| Conditions | `if`, `elif`, `else`, `case` | Parse options and handle errors |
| Loops | `for`, `while` | Run tests, retry smoke tests |
| Functions | `function_name(){}` | Pipeline stages and logging |
| Regular expressions | `grep -E`, `[[ =~ ]]` | Detect test files and project type |
| File manipulation | `find`, `cp`, `mv`, `mkdir`, `rm` | Archives, deploy, rollback |
| Compression | `tar`, `gzip` | Create rollback archives |
| Access control | `$EUID`, `chmod`, `chown` | Admin checks and permissions |
| Pipes and filters | `|`, `grep`, `awk`, `sed` | Parse logs and command outputs |
| Redirections | `>`, `>>`, `2>&1`, `tee` | Logging terminal and file output |
| Fork | `&`, `wait`, `$!` | Fork mode |
| Subshell | `( commands )` | Isolated mode |
| Jobs | `jobs`, `&`, `wait` | Thread simulation mode |

---

# 16. Test Scenarios

---

## 16.1 Scenario 1 — Light Project

### Goal

Validate the base pipeline on a simple project.

### Project Type

Shell script project.

### Characteristics

- Around 50 lines of code.
- 3 simple test files.
- Local staging deployment.
- Sequential execution.

### Command

```bash
pipepilot -p /home/user/project_light -e staging -v
```

### Expected Duration

```text
3 to 8 seconds
```

### Expected Result

```text
Pipeline completed successfully.
```

---

## 16.2 Scenario 2 — Medium Project

### Goal

Test fork and subshell execution modes.

### Project Type

Python application.

### Characteristics

- Python project with virtual environment.
- 15 unit tests.
- Local staging deployment.

### Commands

Subshell mode:

```bash
pipepilot -s -p /home/user/project_python -e staging
```

Fork mode:

```bash
pipepilot -f -p /home/user/project_python -e staging
```

### Expected Duration

```text
15 to 30 seconds
```

### Expected Result

```text
Tests pass, build succeeds, staging deployment succeeds.
```

---

## 16.3 Scenario 3 — Heavy Project

### Goal

Evaluate thread mode and remote production deployment.

### Project Type

C multi-module project.

### Characteristics

- 5 independent modules.
- Remote deployment with SSH/rsync.
- Production environment.
- Admin rights required.
- Smoke test using HTTP and port checking.

### Commands

Thread mode and production:

```bash
sudo pipepilot -t -p /home/user/project_c -e production -b main -v
```

Manual rollback:

```bash
sudo pipepilot -r -p /home/user/project_c
```

Dry-run production simulation:

```bash
pipepilot -d -p /home/user/project_c -e production -v
```

### Expected Duration

```text
45 to 90 seconds
```

### Expected Result

```text
Modules build in parallel, deployment succeeds, smoke tests pass.
```

---

# 17. Comparison of Execution Modes

| Criteria | Sequential | Subshell `-s` | Fork `-f` | Thread `-t` |
|---|---|---|---|---|
| Environment isolation | No | Yes | Partial | No |
| Parallelism | No | No | Partial | Yes |
| Debugging | Easy | Medium | Medium | Hard |
| Performance | Slow | Slow | Medium | Fast |
| Crash isolation | No | Yes | Yes | No |
| Best use case | Simple deployment | Safe isolated run | Process demo | Multi-module build |

---

# 18. Help Documentation `-h`

PipePilot must include complete help using:

```bash
pipepilot -h
```

Recommended output:

```text
NAME
    pipepilot - Bash CI/CD automation tool for generic projects

SYNOPSIS
    pipepilot [OPTIONS] -p <project_path>

DESCRIPTION
    PipePilot automates the complete software deployment pipeline:
    Git source recovery, static analysis, unit testing, build,
    versioned archive, local/remote deployment, smoke tests,
    and automatic rollback on failure.

OPTIONS
    -h                  Show this help and exit
    -f                  Fork mode: stages run in child processes
    -t                  Thread mode: independent modules run in background jobs
    -s                  Subshell mode: pipeline runs in an isolated subshell
    -l <dir>            Custom log directory
    -r                  Restore previous version [ADMIN REQUIRED]
    -e <env>            Environment: staging | production [ADMIN for production]
    -p <path>           Project path [REQUIRED]
    -b <branch>         Git branch to deploy, default: main
    -d                  Dry-run mode
    -v                  Verbose mode

EXIT CODES
    0                   Pipeline completed successfully
    100                 Unknown option
    101                 Missing required parameter -p
    102                 Project directory not found
    103                 Git pull or clone failed
    104                 Lint failed
    105                 Unit tests failed
    106                 Build failed
    107                 Deployment failed
    108                 Smoke test failed
    109                 Rollback failed
    110                 Permission denied

EXAMPLES
    pipepilot -p /srv/app -e staging
    pipepilot -f -p /srv/app -e production -b develop
    pipepilot -t -p /srv/app -e staging -v
    sudo pipepilot -r -p /srv/app
    pipepilot -d -p /srv/app -e production
```

---

# 19. Example Commands

## 19.1 Simple Staging Deployment

```bash
pipepilot -p /home/user/myapp -e staging
```

## 19.2 Verbose Deployment

```bash
pipepilot -p /home/user/myapp -e staging -v
```

## 19.3 Deploy a Specific Branch

```bash
pipepilot -p /home/user/myapp -e staging -b develop
```

## 19.4 Production Deployment

```bash
sudo pipepilot -p /home/user/myapp -e production -b main
```

## 19.5 Dry-Run Before Production

```bash
pipepilot -d -p /home/user/myapp -e production -v
```

## 19.6 Manual Rollback

```bash
sudo pipepilot -r -p /home/user/myapp
```

## 19.7 Thread Mode

```bash
pipepilot -t -p /home/user/myapp -e staging -v
```

---

# 20. Final Recommendation

For the academic project, use this identity:

```text
Project Name: PipePilot
Type: Bash CI/CD Automation Tool
Slogan: Automate. Validate. Deploy. Rollback safely.
```

However, inside the report, you can mention:

```text
PipePilot is the improved name of the original deploymaster concept.
```

This keeps the project aligned with the PDF while giving it a more modern and memorable identity.

---

# 21. Final Summary

**PipePilot** is a complete Bash-based CI/CD automation tool that respects the mini-project requirements.

It includes:

- A real problem and solution.
- Standard Linux syntax.
- Required parameter `-p`.
- More than 6 options.
- Admin-only operations.
- 7-step pipeline.
- Logging system.
- Error codes.
- Automatic rollback.
- Help documentation.
- Sequential, subshell, fork, and thread modes.
- Three test scenarios.
- Many Linux concepts from the course.

Final pipeline:

```text
Pull → Lint → Test → Build → Archive → Deploy → Smoke Test
```

If anything fails:

```text
Log error → Rollback if needed → Show help → Exit with error code
```
