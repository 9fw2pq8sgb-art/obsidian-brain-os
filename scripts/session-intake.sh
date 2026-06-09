#!/bin/bash
# SessionStart hook — injects a project-aware intake instruction for Claude.
# Discovers categories (sub-folders of "01 Projects/") and projects dynamically,
# reading an optional `repo:` frontmatter to surface a code path.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
BRAIN_OS_TAG=intake; set -uo pipefail
cat >/dev/null 2>&1   # consume the SessionStart JSON on stdin

brain_ready || exit 0
PROJ="$BRAIN_VAULT/01 Projects"
[ -d "$PROJ" ] || exit 0

get_repo() { awk -F': ' '/^repo:/{sub(/[[:space:]]+$/,"",$2); print $2; exit}' "$1"/*.md 2>/dev/null; }

# Build inventory. Two layouts supported:
#   01 Projects/<Category>/<Project>/   (e.g. by client/company)  -> grouped
#   01 Projects/<Project>/              (flat)                    -> single list
inv=$(
  find "$PROJ" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | while IFS= read -r lvl1; do
    # does lvl1 itself look like a project (has .md) or a category (has sub-dirs)?
    subdirs=$(find "$lvl1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)
    has_md=$(find "$lvl1" -maxdepth 1 -name '*.md' 2>/dev/null | head -1)
    if [ -n "$subdirs" ] && [ -z "$has_md" ]; then
      printf '%s:\n' "$(basename "$lvl1")"
      find "$lvl1" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | while IFS= read -r d; do
        repo=$(get_repo "$d")
        if [ -n "$repo" ]; then printf '  - %s  [Code: %s]\n' "$(basename "$d")" "$repo"
        else printf '  - %s\n' "$(basename "$d")"; fi
      done
    else
      repo=$(get_repo "$lvl1")
      if [ -n "$repo" ]; then printf -- '- %s  [Code: %s]\n' "$(basename "$lvl1")" "$repo"
      else printf -- '- %s\n' "$(basename "$lvl1")"; fi
    fi
  done
)
[ -z "$inv" ] && inv="(no projects yet)"

cat <<EOF
[brain-os intake] The primary store is ALWAYS the Obsidian vault at: $BRAIN_VAULT
Projects live under "01 Projects/" (optionally grouped one level deep, e.g. by client).

When the user creates, saves, or works on a project in THIS session: BEFORE writing
files, ask (clickable, via AskUserQuestion) which project it belongs to — offer the
most relevant existing projects plus an "Other / new project / just a question" option.
Do NOT ask for the storage location — it is always the vault.

If a chosen project has a [Code: <path>] and the task is coding/builds/git, work
directly in that repo by absolute path; keep notes/docs in the vault.

Current projects:
$inv
EOF
exit 0
