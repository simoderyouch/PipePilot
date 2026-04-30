#!/usr/bin/env bash
# Run all PipePilot scenarios.
# This wrapper is useful during demonstrations because it executes the light,
# medium, and heavy cases in the same order as the specification.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/tests/test_light.sh"
"$ROOT_DIR/tests/test_medium.sh"
"$ROOT_DIR/tests/test_heavy.sh"
"$ROOT_DIR/tests/test_remote_dry_run.sh"

echo "[TESTS] All PipePilot scenarios completed"
