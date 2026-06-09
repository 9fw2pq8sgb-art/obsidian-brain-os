#!/bin/bash
# tidy-sessions.sh — moves auto-capture session notes out of the Inbox into the
# archive and rebuilds an index. Idempotent, non-destructive. Run nightly via cron.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
BRAIN_OS_TAG=tidy; set -euo pipefail
brain_ready || { echo "brain-os: BRAIN_VAULT not set — skipping."; brain_log "skipped (no BRAIN_VAULT)"; exit 0; }

INBOX="$BRAIN_VAULT/00 Inbox"
ARCH="$BRAIN_VAULT/04 Archive/Sessions"
mkdir -p "$ARCH"
shopt -s nullglob

# 1) move raw captures from the Inbox into the archive
for f in "$INBOX"/session-*.md; do
  mv -f "$f" "$ARCH/"
done

# 2) regenerate the index
IDX="$ARCH/Session-Captures Index.md"
{
  printf -- '---\ntags: [index, session-capture, archive]\n---\n\n'
  printf '# 🗄️ Session-Captures — Index (auto)\n\n'
  printf '> Raw session markers (brain-os SessionEnd hook), archived here by `tidy-sessions.sh`. Raw & unlinked (own graph cluster) — lift insights into project/knowledge notes. Updated: %s\n\n' "$(date '+%Y-%m-%d %H:%M')"
  printf '| Date | Time | Source | Note |\n|---|---|---|---|\n'
  for f in "$ARCH"/session-*.md; do
    b="$(basename "$f" .md)"; rest="${b#session-}"
    d="${rest%-*}"; hms="${rest##*-}"; t="${hms:0:2}:${hms:2:2}"
    q="$(grep -m1 '^quelle:' "$f" 2>/dev/null | sed 's/^quelle:[[:space:]]*//; s#/*$##')"
    q="$(basename "${q:-?}")"
    printf '| %s | %s | `%s` | [[%s]] |\n' "$d" "$t" "$q" "$b"
  done | sort -r
} > "$IDX"

n=$( (ls "$ARCH"/session-*.md 2>/dev/null || true) | wc -l | tr -d ' ')
echo "tidy-sessions: $n sessions archived/indexed."
brain_log "ok ($n sessions in archive)"
