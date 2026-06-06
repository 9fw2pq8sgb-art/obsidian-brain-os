#!/bin/bash
# present.sh "<Project>" — opens a project's presentation canvas in Obsidian.
# Used when the user says "I want to present <project>".
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; . "$DIR/lib.sh"
brain_ready || { echo "brain-os: BRAIN_VAULT not set."; exit 1; }
q="${1:-}"
[ -z "$q" ] && { echo "Usage: present.sh \"<Project>\""; exit 1; }

PROJ="$BRAIN_VAULT/01 Projects"
# Prefer a dedicated presentation canvas; fall back to any canvas of the project.
match="$(find "$PROJ" -iname "*${q}* Vorstellung (Canvas).canvas" 2>/dev/null | head -1)"
[ -z "$match" ] && match="$(find "$PROJ" -iname "*${q}*Canvas*.canvas" 2>/dev/null | head -1)"
[ -z "$match" ] && match="$(find "$PROJ" -iname "*${q}*.canvas" 2>/dev/null | head -1)"
[ -z "$match" ] && { echo "No canvas found for '$q'."; exit 1; }

enc="$("$BRAIN_PY" -c 'import sys,urllib.parse;print(urllib.parse.quote(sys.argv[1]))' "$match")"
open "obsidian://open?path=$enc"
echo "Opening canvas: $match"
