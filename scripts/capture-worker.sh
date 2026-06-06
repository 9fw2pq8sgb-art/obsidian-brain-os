#!/bin/bash
# Detached LLM-summary worker (opt-in, started by session-capture.sh when
# BRAIN_CAPTURE_SUMMARY=1). Reads the transcript, asks headless `claude` for a
# short structured summary, and writes it to the vault Inbox with the full raw
# text collapsed. Falls back to a raw dump if the summary fails.
export BRAIN_CAPTURE=1
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"

transcript="$1"; cwd="$2"
brain_ready || exit 0
[ -f "$transcript" ] || exit 0
INBOX="$BRAIN_VAULT/00 Inbox"; mkdir -p "$INBOX"
CLAUDE_BIN="$(command -v claude 2>/dev/null)"

convo="$("$BRAIN_PY" - "$transcript" <<'PY'
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
)"
[ "${#convo}" -lt 200 ] && exit 0

PROMPT='You receive the raw text of a Claude Code working session (User / Claude). Write a SHORT, factual summary for a project log. Exactly these sections, terse bullets, no intro/outro:

## What it was about
## What was done
## Decisions
## Open to-dos

If a section is empty, write "—". Match the language of the conversation.'
summary=""
[ -n "$CLAUDE_BIN" ] && summary="$(printf '%s' "$convo" | timeout 180 "$CLAUDE_BIN" -p "$PROMPT" --model haiku --allowedTools "" 2>/dev/null)"

ts="$(date +%Y-%m-%d-%H%M%S)"; out="$INBOX/session-$ts.md"
{
  echo "---"; echo "tags: [session-capture, inbox]"; echo "datum: $(date +%Y-%m-%d)"
  echo "quelle: ${cwd:-unknown}"
  if [ "${#summary}" -ge 80 ]; then echo "typ: llm-summary"; else echo "typ: raw"; fi
  echo "---"; echo
  echo "# 🗒️ Session-Capture $(date '+%Y-%m-%d %H:%M')"; echo
  echo "> Auto-captured Claude Code session. Working dir: \`${cwd:-?}\`"; echo
  if [ "${#summary}" -ge 80 ]; then
    printf '%s\n' "$summary"; echo; echo "---"
    echo '> [!note]- 📜 Full raw transcript (collapsed)'
    printf '%s\n' "$convo" | sed 's/^/> /'
  else
    echo "> _(Automatic summary unavailable — raw text.)_"; echo
    printf '%s\n' "$convo"
  fi
} > "$out"
exit 0
