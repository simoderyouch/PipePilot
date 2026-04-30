#!/usr/bin/env bash
# Pre-deploy hook for PipePilot.
# This hook runs immediately before the deploy stage.
# Students can extend it to stop a service, check disk space, or notify a team.

set -euo pipefail

echo "[HOOK] pre-deploy checks completed"

