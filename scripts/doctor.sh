#!/bin/bash
# brain-os doctor — READ-ONLY self-check of the install. Prints ✅/⚠️/❌ lines.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
ok()   { printf '  ✅ %s\n' "$*"; }
warn() { printf '  ⚠️  %s\n' "$*"; }
bad()  { printf '  ❌ %s\n' "$*"; }

echo "🩺 brain-os doctor"

# Config
[ -f "$BRAIN_OS_CONFIG" ] && ok "config present: $BRAIN_OS_CONFIG" || bad "config missing ($BRAIN_OS_CONFIG) — run /brain-setup"

# Vault + PARA
if brain_ready; then
  ok "vault: $BRAIN_VAULT"
  for d in "00 Inbox" "01 Projects" "02 Areas" "03 Resources" "04 Archive"; do
    [ -d "$BRAIN_VAULT/$d" ] && ok "PARA: $d" || warn "PARA folder missing: $d"
  done
else
  bad "BRAIN_VAULT not set or not a directory — run /brain-setup"
fi

# python3
[ -n "$BRAIN_PY" ] && [ -x "$BRAIN_PY" ] && ok "python3: $BRAIN_PY" || bad "python3 not found (hooks parse JSON with it)"

# qmd + brain collection
if command -v qmd >/dev/null 2>&1; then
  ok "qmd installed ($(command -v qmd))"
  if qmd collection list 2>/dev/null | grep -q "brain"; then ok "qmd 'brain' collection present"
  else warn "qmd 'brain' collection missing — run /brain-setup (semantic search)"; fi
else
  warn "qmd not installed — semantic search disabled (npm i -g @tobilu/qmd)"
fi

# claude CLI (for capture summaries)
command -v claude >/dev/null 2>&1 && ok "claude CLI present (capture summaries)" || warn "claude CLI not on PATH — capture falls back to pointer notes"

# capture summary flag
[ "${BRAIN_CAPTURE_SUMMARY:-}" = "1" ] && ok "BRAIN_CAPTURE_SUMMARY=1 (LLM summaries ON)" || warn "BRAIN_CAPTURE_SUMMARY off — pointer notes only (set =1 in config to enable)"

# nightly wrapper + cron
[ -f "$HOME/.config/brain-os/brain-os-nightly.sh" ] && ok "nightly wrapper installed" || warn "nightly wrapper missing (~/.config/brain-os/brain-os-nightly.sh) — run /brain-setup"
if crontab -l 2>/dev/null | grep -qE "brain-os-nightly\.sh|tidy-sessions\.sh|qmd-refresh\.sh"; then ok "nightly cron present"
else warn "no nightly cron — run /brain-setup (step 5)"; fi

# log
if [ -f "$BRAIN_OS_LOG" ]; then
  ok "log: $BRAIN_OS_LOG"
  echo "  last 3 log lines:"; tail -3 "$BRAIN_OS_LOG" 2>/dev/null | sed 's/^/    /'
else
  warn "no log yet ($BRAIN_OS_LOG) — hooks haven't run/logged"
fi

echo "Done."
