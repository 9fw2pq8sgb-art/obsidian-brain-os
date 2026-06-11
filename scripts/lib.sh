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

# brain_convo <transcript.jsonl> — print user/assistant text (last 20k chars).
# Shared by session-capture (trivial-session guard) and capture-worker (summary input).
brain_convo() {
  [ -n "${1:-}" ] && [ -f "$1" ] || return 0
  "$BRAIN_PY" - "$1" <<'PY'
import sys, json
out=[]
try:
    with open(sys.argv[1]) as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try: o=json.loads(line)
            except Exception: continue
            msg=o.get("message") or o
            role=msg.get("role") or ""
            content=msg.get("content"); text=""
            if isinstance(content,str): text=content
            elif isinstance(content,list):
                text="\n".join(c.get("text","") for c in content if isinstance(c,dict) and c.get("type")=="text")
            text=text.strip()
            if text and role in ("user","assistant"):
                out.append("### %s\n%s" % ("User" if role=="user" else "Claude", text))
except Exception: pass
print(("\n\n".join(out))[-20000:])
PY
}
