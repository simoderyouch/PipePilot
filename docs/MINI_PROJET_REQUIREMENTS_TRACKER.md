# Mini Projet Requirements Tracker

Audit date: 2026-05-01

Project audited: PipePilot

Main script: `pipepilot`

Legend:

- `Met` - implemented clearly in the current project.
- `Partial` - implemented, but not exactly as requested in the Mini Projet text.
- `Missing` - not found in the repository.
- `N/A` - not required for the Bash script itself, but still needed for final submission.

## Overall Status

PipePilot already satisfies most of the Bash/script engineering requirements:
mandatory options, a mandatory parameter, functions, conditions, loops, process
execution modes, archives, permissions, logs, and test scenarios are present.

The main gaps are academic-format details:

- default log path is `logs/history.log`, not `/var/log/pipepilot/history.log`
- log format uses spaces around colons and `INFOS`/`ERROR` without brackets
- normal command output is split between terminal status output and raw log file,
  not fully mirrored to terminal and `history.log`
- `-r` performs archive rollback, while the assignment says restore/reset
  default parameters
- PDF report, PPTX presentation, and final ZIP package are not present

## 1. Project Overview And Objectives

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| Automate standard Unix/Linux processes | Met | `pipepilot`, `stages/*.sh` | Automates git pull/clone, lint, tests, build, archive, deploy, smoke checks, rollback. |
| Address a specific user need for developers or system administrators | Met | `README.md` | Need is CI/CD deployment automation for frontend/backend projects. |
| Main shell script deliverable | Met | `pipepilot` | Main Bash CLI exists and is executable in examples/docs. |
| Detailed PDF report | Missing | No tracked `TeamID-devoir-shell.pdf` found | Create final report with screenshots and examples. |
| Short presentation/demo | Missing | No tracked `TeamID-devoir-shell.pptx` found | Create one-slide presentation for 180-second pitch plus demo. |

## 2. Script Technical Requirements

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| Developed primarily in Bash | Met | `pipepilot`, `stages/*.sh`, `helpers/remote_setup.sh` | Entire core is Bash. |
| May call external Bash or C scripts | Met | `helpers/remote_setup.sh`, `hooks/*.sh`, `stages/*.sh` | Uses Bash helper/stage scripts. No C required. |
| Basic Unix/Linux commands and tools | Met | `git`, `find`, `grep`, `sed`, `awk`, `tar`, `zip`, `rsync`, `scp`, `ssh`, `curl`, `systemctl` | Used across `pipepilot` and `stages/`. |
| Conditions | Met | `if`, `case`, `[[ ... ]]` throughout `pipepilot` and `stages/` | Strong coverage. |
| Loops | Met | `while`, `for`, archive cleanup loops | Examples: `parse_args`, stage loading, test discovery, archive cleanup. |
| Functions | Met | `show_help`, `parse_args`, `run_pipeline`, stage functions | Strong function decomposition. |
| Environment/config variables | Met | `configs/default.conf`, `configs/staging.conf`, `configs/production.conf` | Config values are sourced and can be overridden by CLI. |
| Regular expressions | Met | Numeric validation, project detection, package scripts | Examples: `^[0-9]+$`, package script grep, host checks. |
| File manipulation | Met | `mkdir`, `rm`, `cp`, `rsync`, deploy target handling | Used for logs, archives, deployments, cleanup. |
| Archiving/compression | Met | `stages/05_archive.sh`, rollback functions | Supports `gzip`, `xz`, and `zip`. |
| Access control / privileges | Met | `validate_options` | Local production deploy and `-r` rollback require root/admin unless dry-run. |
| Pipes and filters | Met | `find | sort | tail`, `find | sort -r | awk | while`, `grep`, `sed` | Good coverage. |
| Accepts one or more parameters | Met | Many options supported | CLI follows `./pipepilot [OPTIONS] -p <project_path>`. |
| At least one mandatory parameter | Met | `-p <project_path>` | Enforced in `normalize_paths`. |

## 3. Mandatory Options

| Option | Required Meaning | Status | Current Implementation | Notes / Action |
|---|---|---|---|---|
| `-h` | Help / documentation | Met | `show_help` | Detailed built-in help exists. |
| `-f` | Fork execution | Met | `MODE="fork"` and `run_fork_pipeline` | Uses child background processes and `wait`. |
| `-t` | Thread execution | Partial | `MODE="thread"` and background jobs for lint/test | Bash does not have real threads; document this as background-job thread simulation, or add a C/pthread helper if strict. |
| `-s` | Subshell execution | Met | `run_subshell_pipeline` wraps pipeline in `( ... )` | Clear subshell implementation. |
| `-l` | Log directory | Met | `LOG_DIR="$2"` and `history.log` creation | Works with custom log directory. |
| `-r` | Restore/reset default parameters, admin-only | Partial | Current `-r` restores previous deployment archive | Admin restriction is met, but semantics differ from “reset default parameters.” Either explain as rollback/restore in report or add a true default-reset mode. |

## 4. Logging And Output Management

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| STDOUT and STDERR displayed in terminal and simultaneously written to log | Partial | `run_cmd`, `run_in_project`, `RAW_LOG_FILE` | Normal mode writes raw command output to `run-*.raw.log` and shows clean status in terminal. Verbose mode shows raw output in terminal but does not tee all raw output into `history.log`. To match exactly, use `tee -a "$LOG_FILE"` or document the split `history.log` + raw log design. |
| Log file named `history.log` | Met | `ensure_log_file` | Always creates `history.log` in selected log directory. |
| Log file located in `/var/log/yourprogramname/` | Partial | `configs/default.conf` uses `DEFAULT_LOG_DIR="logs"` | Change default to `/var/log/pipepilot` for strict compliance, or show `-l /var/log/pipepilot` in the report/demo. |
| Log format `yyyy-mm-dd-hh-mm-ss: username: [INFOS/ERROR]: message` | Partial | `log_info`, `log_error` | Current format is `yyyy-mm-dd-hh-mm-ss : username : INFOS : message`. Needs no spaces before colons and brackets around level for exact match. |

## 5. Error Handling

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| Handles incorrect usage | Met | `need_value`, `parse_args`, `validate_options`, `die` | Unknown options, missing values, invalid config, missing project, dependency errors handled. |
| Specific error codes | Met | `ERR_UNKNOWN_OPTION=100`, `ERR_MISSING_PARAMETER=101`, etc. | Good coverage from 100 to 114. |
| 100 for non-existent options | Met | `die "$ERR_UNKNOWN_OPTION"` | Implemented for unknown options/unexpected args. |
| 101 for missing mandatory parameters | Met | `ERR_MISSING_PARAMETER=101` | Missing `-p` and missing option values use this code. |
| Help displayed after any triggered error | Partial | `die` only calls `show_help` for unknown option, missing parameter, and config errors | Assignment says any triggered error. To match exactly, call `show_help` for all `die` errors or document why runtime errors omit help. |

## 6. Testing And Performance Evaluation

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| Standard syntax `program [options] [parameter]` | Met | Help and README examples | Current syntax is `./pipepilot [OPTIONS] -p <project_path>`. |
| Light scenario | Met | `tests/test_light.sh` | Shell project, sequential mode, lint/test/archive/deploy/logging. |
| Medium scenario | Met | `tests/test_medium.sh` | Python project in subshell mode. |
| Heavy scenario | Met | `tests/test_heavy.sh` | Backend-style Python project using thread simulation and production dry-run. |
| Evaluate fork execution | Partial | `-f` exists, but documented scenario set does not clearly dedicate light/medium/heavy to fork | Add a scenario or benchmark command that runs one case with `-f`. |
| Evaluate subshell execution | Met | `tests/test_medium.sh` | Uses `-s`. |
| Evaluate thread execution | Met | `tests/test_heavy.sh` | Uses `-t`. |
| Performance comparison | Partial | Tests run modes, but no timing table in docs | Add timing results with `time ./tests/...` to the PDF report or a benchmark markdown. |

## 7. Documentation And Submission

| Requirement | Status | Evidence | Notes / Action |
|---|---|---|---|
| Internal documentation via `-h` | Met | `show_help` | Detailed help is implemented. |
| Extended PDF report named `TeamID-devoir-shell.pdf` | Missing | Not found | Create before final submission. |
| Report includes screenshots | Missing | Not found | Add terminal screenshots for help, light/medium/heavy runs, log file, restore/admin error. |
| Report includes implementation details | Partial | `README.md`, `docs/USAGE.md`, `pipepilot_project_specification.md` | Markdown docs exist; still need PDF packaging. |
| Report includes concrete usage examples | Met | `README.md`, `docs/USAGE.md` | Strong examples exist. |
| One-slide PPTX named `TeamID-devoir-shell.pptx` | Missing | Not found | Create final presentation. |
| 180-second presentation + 5-minute demo plan | Missing | Not found | Add a short demo script or slide notes. |
| Final ZIP named `TeamID-devoir-shell.zip` | Missing | Not found | Package final script, docs, PDF, PPTX, and tests. |

## Recommended Fix List Before Submission

Priority 1 - strict assignment compliance:

1. Change default log directory to `/var/log/pipepilot` or explicitly run demos with `-l /var/log/pipepilot`.
2. Adjust log lines to exact format: `yyyy-mm-dd-hh-mm-ss: username: [INFOS]: message`.
3. Decide whether `-r` means rollback or reset defaults. If the teacher expects reset defaults, add a reset behavior or explain the mapping clearly.
4. Make help display after every `die` error if strict wording is enforced.

Priority 2 - evaluation/report polish:

1. Add a fork scenario command to `docs/TEST_SCENARIOS.md`, for example running the light project with `-f`.
2. Capture timing results for sequential, fork, subshell, and thread modes.
3. Create `TeamID-devoir-shell.pdf`.
4. Create `TeamID-devoir-shell.pptx`.
5. Create `TeamID-devoir-shell.zip`.

## Suggested Demo Commands

```bash
./pipepilot -h
./tests/test_light.sh
./tests/test_medium.sh
./tests/test_heavy.sh
./pipepilot -f -p tests/tmp/light_project -e staging -l tests/tmp/logs/fork --target tests/tmp/deploy/fork
sudo ./pipepilot -r -p tests/tmp/light_project --target tests/tmp/deploy/light -l /var/log/pipepilot
```

## Current Verdict

PipePilot is a strong Mini Projet candidate and meets the majority of the
technical Bash requirements. For final academic submission, focus on exact log
format/location, clarifying `-r`, adding fork performance evidence, and creating
the required PDF/PPTX/ZIP deliverables.
