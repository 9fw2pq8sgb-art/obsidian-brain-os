#!/bin/bash
# brain-os shared library — resolves the vault path.
# Resolution order: env BRAIN_VAULT  >  config file  >  empty (scripts then no-op).
# Config file default: ~/.config/brain-os/config   (override via BRAIN_OS_CONFIG)

BRAIN_OS_CONFIG="${BRAIN_OS_CONFIG:-$HOME/.config/brain-os/config}"
[ -f "$BRAIN_OS_CONFIG" ] && . "$BRAIN_OS_CONFIG"
BRAIN_VAULT="${BRAIN_VAULT:-}"

# python3 (for parsing hook JSON)
BRAIN_PY=/opt/homebrew/bin/python3
[ -x "$BRAIN_PY" ] || BRAIN_PY=/usr/bin/python3
[ -x "$BRAIN_PY" ] || BRAIN_PY="$(command -v python3 2>/dev/null)"

brain_ready() { [ -n "$BRAIN_VAULT" ] && [ -d "$BRAIN_VAULT" ]; }

# logging — single append-only log; quiet (never pollutes hook stdout/stderr).
# Scripts set BRAIN_OS_TAG to identify themselves.
BRAIN_OS_LOG="${BRAIN_OS_LOG:-$HOME/.config/brain-os/brain-os.log}"
brain_log() {
  mkdir -p "${BRAIN_OS_LOG%/*}" 2>/dev/null
  printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${BRAIN_OS_TAG:-brain-os}" "$*" >> "$BRAIN_OS_LOG" 2>/dev/null || true
}
