#!/usr/bin/env bash
# Post-deploy hook for PipePilot.
# This hook runs immediately after files are copied to the target destination.
# Students can extend it to restart services, clear cache, or send notifications.

set -euo pipefail

echo "[HOOK] post-deploy tasks completed"

