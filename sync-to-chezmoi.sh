#!/usr/bin/env bash
# Sync skills from this repo into chezmoi's dot_claude/commands/
# Run after adding/editing a skill so all platforms pick it up on next `dotup`.
#
# Usage: ./sync-to-chezmoi.sh
# Or: automatically via the git pre-push hook (hooks/pre-push)
set -euo pipefail

SKILLS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills"
CHEZMOI_DIR="$HOME/.local/share/chezmoi/dot_claude/commands"

if [ ! -d "$CHEZMOI_DIR" ]; then
    echo "ERROR: chezmoi commands dir not found: $CHEZMOI_DIR" >&2
    echo "Is chezmoi initialized? Run: chezmoi init" >&2
    exit 1
fi

echo "Syncing skills → chezmoi..."
changes=0
for skill in "$SKILLS_DIR"/*.md; do
    [ -f "$skill" ] || continue
    name="$(basename "$skill")"
    target="$CHEZMOI_DIR/$name"
    if [ ! -f "$target" ] || ! cmp -s "$skill" "$target"; then
        cp "$skill" "$target"
        echo "  + $name"
        changes=$((changes + 1))
    fi
done

# Detect skills in chezmoi that no longer exist in the repo
for existing in "$CHEZMOI_DIR"/*.md; do
    [ -f "$existing" ] || continue
    name="$(basename "$existing")"
    if [ ! -f "$SKILLS_DIR/$name" ]; then
        echo "  ! $name exists in chezmoi but not in repo (consider removing)"
    fi
done

if [ "$changes" -eq 0 ]; then
    echo "  (no changes)"
else
    echo "  $changes skill(s) updated"
    echo ""
    echo "Next steps:"
    echo "  1. cd ~/.local/share/chezmoi && git add dot_claude/commands/ && git commit"
    echo "  2. git push"
    echo "  3. On other machines: run 'dotup' to pick up new skills"
fi
