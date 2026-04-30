#!/usr/bin/env bash
# Run all academic PipePilot scenarios.
# This wrapper is useful during demonstrations because it executes the light,
# medium, and heavy cases in the same order as the specification.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/tests/test_light.sh"
"$ROOT_DIR/tests/test_medium.sh"
"$ROOT_DIR/tests/test_heavy.sh"

echo "[TESTS] All PipePilot scenarios completed"

