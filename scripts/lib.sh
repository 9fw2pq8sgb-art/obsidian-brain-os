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
