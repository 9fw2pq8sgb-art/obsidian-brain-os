#!/bin/bash
# qmd-refresh.sh — keeps the qmd semantic search index current. Run nightly via cron
# (after tidy-sessions.sh). Local-only; models are cached in ~/.cache/qmd/models/.
# Requires qmd installed and a 'brain' collection (see /brain-setup).
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
BRAIN_OS_TAG=qmd; set -uo pipefail
QMD="$(command -v qmd || true)"
[ -z "$QMD" ] && { echo "brain-os: qmd not found — skipping."; brain_log "skipped (qmd not found)"; exit 0; }
"$QMD" update >/dev/null 2>&1   # re-index changed/new notes
"$QMD" embed  >/dev/null 2>&1   # embed only new/changed chunks
echo "qmd-refresh: index updated."
brain_log "ok (qmd update+embed)"
