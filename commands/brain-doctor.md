---
description: Diagnose a brain-os install (read-only). Checks config, vault + PARA folders, qmd and its 'brain' collection, the claude CLI, the capture-summary flag, the nightly wrapper + cron, and recent log lines. Use when something isn't working or to verify setup.
---

Run the bundled self-check and report the result to the user:

```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/doctor.sh"
```

Summarize the ✅/⚠️/❌ lines concisely. For every ⚠️ or ❌, give a one-line fix — typically:
- config / vault / PARA / cron issues → run `/brain-setup`
- qmd missing → `npm install -g @tobilu/qmd` (Node ≥ 22; macOS: `brew install sqlite`)
- claude CLI missing → install Claude Code CLI (capture then uses lightweight pointer notes)
- summaries off → set `BRAIN_CAPTURE_SUMMARY=1` in `~/.config/brain-os/config`

Do NOT change anything — this is a diagnostic only.
