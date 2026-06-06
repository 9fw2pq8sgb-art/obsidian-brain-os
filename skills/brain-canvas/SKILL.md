---
name: brain-canvas
description: Build or open a presentation "pitch canvas" for an Obsidian project — a JSON Canvas that explains a project (problem, solution, how it works, USPs, status, facts) with a live embed of the project note. Use when the user wants to present/pitch a project, asks for a project canvas, or says "I want to present <project>".
---

# Brain Canvas — Project Pitch Canvases

Generate a consistent, presentation-ready **JSON Canvas** (`.canvas`) for any project in the Obsidian vault, and open it on request.

## When to build
User asks to "make a canvas for X", "pitch/present X", or you just created a main project and want a visual overview.

## Where
Save as `01 Projects/<…>/<Project>/<Project> Vorstellung (Canvas).canvas` inside the vault
(resolve the vault path from `~/.config/brain-os/config` → `BRAIN_VAULT`, or ask).
Add a link in the project note: `> 🗺️ **Presentation (Canvas):** [[<Project> Vorstellung (Canvas)]]`.

## Template (JSON Canvas 1.0)
A title card (accent color) + a row of three (Problem → Solution → How it works, connected by edges),
a row of three (⭐ USPs, 📍 Status, 🔢 Facts/Tech), and a file-embed of the project note at the bottom.

Node layout (x,y,width,height), all `type:"text"` unless noted:
- `title`  x-520 y-580 w1180 h120  — `# <emoji> <Project>\n<one-line pitch>`  color `"#00C896"` (or your accent)
- `problem` x-520 y-430 w370 h250 color `"1"` — `## ❗ Problem` + bullets
- `loesung` x-130 y-430 w370 h250 color `"4"` — `## ✅ Solution` + bullets
- `how`     x260  y-430 w400 h250 color `"5"` — `## ⚙️ How it works` + numbered steps
- `usp`     x-520 y-160 w560 h250 color accent — `## ⭐ USPs` + bullets
- `status`  x60   y-160 w260 h250 color `"3"` — `## 📍 Status`
- `fakten`  x340  y-160 w320 h250 color `"6"` — `## 🔢 Facts / Tech`
- `embed`   type `"file"`, `file:"<vault-relative path to project .md>"`, x-520 y120 w1180 h430

Edges: problem→loesung (right→left), loesung→how (right→left), title→usp (bottom→top, label "Core value").

Canvas colors are presets `"1"`–`"6"` (1 red, 3 yellow, 4 green, 5 cyan, 6 purple) or hex strings.

## Build steps
1. Resolve vault + project folder + the project note filename.
2. Read the project note to extract problem/solution/USPs/status/facts (ask the user to fill gaps).
3. Write the `.canvas` JSON with the nodes/edges above (use the `json-canvas` skill's spec if available).
4. Append the link line to the project note (idempotent — skip if already present).
5. Tell the user to reload Obsidian; offer to open it.

## Open an existing canvas
Run the bundled helper:
```
bash "${CLAUDE_PLUGIN_ROOT}/scripts/present.sh" "<Project>"
```
It resolves the project's presentation canvas and opens it via `obsidian://`.
