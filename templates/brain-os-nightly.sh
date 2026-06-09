#!/bin/bash
# brain-os nightly maintenance — STABLE launcher.
# Cron points HERE (a fixed path: ~/.config/brain-os/brain-os-nightly.sh), so it
# survives plugin updates: it resolves the CURRENT brain-os scripts dir at runtime,
# then runs tidy-sessions -> qmd-refresh (chained, no race), logging everything.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
CFG="${BRAIN_OS_CONFIG:-$HOME/.config/brain-os/config}"
[ -f "$CFG" ] && . "$CFG"
LOG="${BRAIN_OS_LOG:-$HOME/.config/brain-os/brain-os.log}"
log() { mkdir -p "${LOG%/*}" 2>/dev/null; printf '%s [nightly] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG" 2>/dev/null; }

find_scripts() {
  # 1) explicit override from config
  if [ -n "${BRAIN_OS_PLUGIN_ROOT:-}" ] && [ -d "$BRAIN_OS_PLUGIN_ROOT/scripts" ]; then
    echo "$BRAIN_OS_PLUGIN_ROOT/scripts"; return; fi
  # 2) installed plugin cache (newest), then dev checkout
  ls -dt "$HOME/.claude/plugins/cache/"*/brain-os/*/scripts \
         "$HOME/.claude/plugins/"*/brain-os/scripts \
         "$HOME/.claude/plugins/marketplaces/"*/scripts \
         "$HOME/Code/obsidian-brain-os/scripts" 2>/dev/null | head -1
}

S="$(find_scripts)"
[ -z "$S" ] && { log "ERROR: brain-os scripts dir not found — re-run /brain-setup"; exit 1; }
log "start (scripts=$S)"
/bin/bash "$S/tidy-sessions.sh" >> "$LOG" 2>&1 && log "tidy ok" || log "tidy FAILED (exit $?)"
/bin/bash "$S/qmd-refresh.sh"   >> "$LOG" 2>&1 && log "qmd ok"  || log "qmd FAILED (exit $?)"
log "done"
