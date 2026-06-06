---
description: One-time guided setup for brain-os — creates/links the Obsidian vault, writes the config, scaffolds PARA, and wires up semantic search (qmd), nightly maintenance (cron), and optional code-architecture graphs (graphify).
---

You are setting up **brain-os** for the user. Work step by step, confirm before destructive actions, and keep it OS-aware (these instructions assume macOS/Linux with zsh/bash).

## 1. Vault path
Ask the user for their Obsidian vault path (or where to create a new one). Call it `$VAULT`.
- If it doesn't exist, offer to scaffold a fresh PARA vault by copying `${CLAUDE_PLUGIN_ROOT}/templates/vault/` to `$VAULT`.
- If it exists, only ensure the PARA folders exist (`00 Inbox`, `01 Projects`, `02 Areas`, `03 Resources`, `04 Archive`); never overwrite the user's notes.

## 2. Config
Write `~/.config/brain-os/config` with:
```
BRAIN_VAULT="<absolute path to $VAULT>"
# BRAIN_CAPTURE_SUMMARY=1   # optional: auto LLM-summarize each session (headless claude) instead of a pointer note
```
(Create `~/.config/brain-os/` if needed.) This is what every hook/script reads. Confirm the hooks
(`session-intake`, `session-capture`) will now activate on the next session. Ask whether the user
wants the LLM summary capture — if yes, uncomment `BRAIN_CAPTURE_SUMMARY=1` (it uses their Claude
Code login, runs detached, falls back to a raw dump if `claude` is unavailable).

## 3. Obsidian graph filter (optional)
If `$VAULT/.obsidian/graph.json` is absent or the user agrees, copy
`${CLAUDE_PLUGIN_ROOT}/templates/obsidian-graph.json` to `$VAULT/.obsidian/graph.json`
(search filter `-tag:session-capture` so raw captures don't clutter the graph). Don't clobber an existing one without asking.

## 4. Semantic search (qmd) — recommended
Check for `qmd` (`command -v qmd`). If missing, tell the user to install it (`npm install -g @tobilu/qmd`; needs Node ≥ 22 and, on macOS, `brew install sqlite`). Then:
- `qmd collection add "$VAULT" --name brain`
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/qmd-index.yml` to `~/.config/qmd/index.yml`, replacing `__VAULT__` with `$VAULT` (this adds the `ignore` patterns for session captures). If a config already exists, MERGE the `ignore` block rather than overwriting.
- `qmd embed` (first run downloads ~2 GB of local models)
- Register the MCP server: `claude mcp add qmd -- qmd mcp`

## 5. Nightly maintenance (cron)
Offer to add two cron jobs (idempotent — grep them out first):
```
45 23 * * * /bin/bash "${CLAUDE_PLUGIN_ROOT}/scripts/tidy-sessions.sh" >/dev/null 2>&1
50 23 * * * /bin/bash "${CLAUDE_PLUGIN_ROOT}/scripts/qmd-refresh.sh"  >/dev/null 2>&1
```
NOTE: `${CLAUDE_PLUGIN_ROOT}` changes when the plugin updates — for cron, resolve it to the
current absolute path at setup time and write THAT into the crontab (and tell the user to re-run
`/brain-setup` after a plugin update). Installing cron may require the user to run the command
themselves if the agent is sandboxed.

## 6. Code-architecture graphs (graphify) — optional
If the user works with code repos, offer graphify:
- `pipx install graphifyy && pipx inject graphifyy anthropic && graphify install`
- Set `ANTHROPIC_API_KEY` in `~/.zshrc` (for LLM cluster naming; Claude is auto-selected as backend).
Usage: scope to the source dir, `graphify update <src> && graphify cluster-only <src> && graphify tree <src> && graphify export callflow-html`, then deposit the architecture note + diagrams into the matching `01 Projects/.../` folder.

## 7. Verify
- `echo $BRAIN_VAULT` after sourcing the config; confirm PARA folders exist.
- `qmd query "test"` returns results.
- Tell the user: hooks fire next session; say "I want to present <project>" to open a pitch canvas; ask any content question and you'll search the vault semantically via qmd.

Summarize what was set up and what (if anything) the user must finish manually (cron, API key, qmd model download).
