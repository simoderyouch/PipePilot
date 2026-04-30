#!/usr/bin/env bash
# Scenario 3 - Heavy project.
# Creates a small C multi-file project and runs PipePilot in thread-simulation
# mode. Production is executed with --dry-run so the scenario demonstrates the
# production command safely without requiring root or a remote server.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$ROOT_DIR/tests/tmp/heavy_c_project"
ARCHIVE_DIR="$ROOT_DIR/tests/tmp/archives/heavy"
LOG_DIR="$ROOT_DIR/tests/tmp/logs/heavy"

rm -rf "$WORK_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
mkdir -p "$WORK_DIR"

cat > "$WORK_DIR/mathlib.h" <<'C'
#ifndef MATHLIB_H
#define MATHLIB_H

int add(int left, int right);
int multiply(int left, int right);

#endif
C

cat > "$WORK_DIR/mathlib.c" <<'C'
#include "mathlib.h"

int add(int left, int right) {
    return left + right;
}

int multiply(int left, int right) {
    return left * right;
}
C

cat > "$WORK_DIR/main.c" <<'C'
#include <stdio.h>
#include "mathlib.h"

int main(void) {
    printf("%d\n", add(2, 3) + multiply(2, 4));
    return 0;
}
C

cat > "$WORK_DIR/Makefile" <<'MAKE'
CC=gcc
CFLAGS=-Wall -Wextra -pedantic

app: main.c mathlib.c mathlib.h
	$(CC) $(CFLAGS) main.c mathlib.c -o app

test: app
	./app | grep -q '^13$$'

clean:
	rm -f app
MAKE

"$ROOT_DIR/pipepilot" \
    -t \
    -d \
    -p "$WORK_DIR" \
    -e production \
    -b main \
    -v \
    --archive-dir "$ARCHIVE_DIR" \
    -l "$LOG_DIR"

echo "[SCENARIO] Heavy C project completed"

