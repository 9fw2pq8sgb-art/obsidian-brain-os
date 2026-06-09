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
- Ensure the `ignore` patterns (so session captures aren't searched), **merging safely** into any existing qmd config:
  `python3 "${CLAUDE_PLUGIN_ROOT}/scripts/qmd-config.py" "$VAULT"`
- `qmd embed` (first run downloads ~2 GB of local models)
- Register the MCP server: `claude mcp add qmd -- qmd mcp`

## 5. Nightly maintenance (cron)
Install the STABLE launcher, then point cron at it (so it survives plugin updates):
- Copy `${CLAUDE_PLUGIN_ROOT}/templates/brain-os-nightly.sh` → `~/.config/brain-os/brain-os-nightly.sh` and `chmod +x` it.
- Add ONE idempotent cron job (grep it out first):
```
50 23 * * * /bin/bash "$HOME/.config/brain-os/brain-os-nightly.sh"
```
The launcher resolves the **current** brain-os scripts dir at runtime and runs tidy → qmd-refresh
(chained, no race), logging to `~/.config/brain-os/brain-os.log`. Because cron points at a FIXED
path, you do **not** need to re-run setup after plugin updates. (Installing cron may require the
user to run the `crontab` command themselves if the agent is sandboxed.)

## 6. Code-architecture graphs (graphify) — optional
If the user works with code repos, offer graphify:
- `pipx install graphifyy && pipx inject graphifyy anthropic && graphify install`
- Set `ANTHROPIC_API_KEY` in `~/.zshrc` (for LLM cluster naming; Claude is auto-selected as backend).
Usage: scope to the source dir, `graphify update <src> && graphify cluster-only <src> && graphify tree <src> && graphify export callflow-html`, then deposit the architecture note + diagrams into the matching `01 Projects/.../` folder.

## 7. Verify
- `echo $BRAIN_VAULT` after sourcing the config; confirm PARA folders exist.
- `qmd query "test"` returns results.
- Tell the user: hooks fire next session; say "I want to present <project>" to open a pitch canvas; ask any content question and you'll search the vault semantically via qmd.
- Run **`/brain-doctor`** for a full health check (config, vault/PARA, qmd + collection, claude CLI, capture flag, nightly wrapper + cron, recent log).

Summarize what was set up and what (if anything) the user must finish manually (cron, API key, qmd model download).
