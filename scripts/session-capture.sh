#!/bin/bash
# SessionEnd hook — captures the session into the vault Inbox.
#   Default: a lightweight pointer note (cheap, no dependencies).
#   Opt-in:  set BRAIN_CAPTURE_SUMMARY=1 (in ~/.config/brain-os/config) to instead
#            write a short LLM summary via headless `claude` (runs detached, uses
#            your Claude Code login). Falls back to the pointer note if unavailable.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
BRAIN_OS_TAG=capture; set -uo pipefail

# Recursion guard: the headless `claude` started by the summary worker would itself
# fire SessionEnd — skip when we're already inside a capture.
[ "${BRAIN_CAPTURE:-}" = "1" ] && exit 0

input=$(cat)
brain_ready || exit 0

tp=$(printf '%s' "$input" | "$BRAIN_PY" -c 'import sys,json;print(json.load(sys.stdin).get("transcript_path",""))' 2>/dev/null)
cwd=$(printf '%s' "$input" | "$BRAIN_PY" -c 'import sys,json;print(json.load(sys.stdin).get("cwd",""))' 2>/dev/null)

# Opt-in: detached LLM summary (so the hook returns immediately, no timeout)
if [ "${BRAIN_CAPTURE_SUMMARY:-}" = "1" ] && [ -n "$tp" ] && command -v claude >/dev/null 2>&1; then
  BRAIN_CAPTURE=1 BRAIN_VAULT="$BRAIN_VAULT" nohup bash "$DIR/capture-worker.sh" "$tp" "$cwd" >/dev/null 2>&1 &
  disown 2>/dev/null
  brain_log "dispatched summary worker (cwd=${cwd:-?})"
  exit 0
fi

# Default: lightweight pointer note
INBOX="$BRAIN_VAULT/00 Inbox"; mkdir -p "$INBOX"
ts=$(date '+%Y-%m-%d-%H%M%S'); note="$INBOX/session-${ts}_$$.md"
{
  printf -- '---\ntags: [session-capture]\nquelle: %s\ntranscript: %s\ncreated: %s\n---\n\n' "${cwd:-?}" "${tp:-?}" "$(date '+%Y-%m-%d %H:%M')"
  printf '# 🗒️ Session-Capture %s\n\n' "$ts"
  printf '> Raw session marker (brain-os). Working dir: `%s`\n> Full transcript: `%s`\n\n' "${cwd:-?}" "${tp:-?}"
  printf '_Tip: set `BRAIN_CAPTURE_SUMMARY=1` in ~/.config/brain-os/config for auto LLM summaries. Auto-archived by `tidy-sessions.sh`._\n'
} > "$note" 2>/dev/null
brain_log "wrote pointer note ${note##*/}"
exit 0
