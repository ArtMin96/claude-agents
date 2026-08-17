#!/usr/bin/env bash
# Install the agents and skills into ~/.claude/
# Usage: ./install.sh [--link]   (--link symlinks instead of copying)

set -euo pipefail

src="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"
mode="${1:-copy}"

mkdir -p "$dest/agents" "$dest/skills/build"

for f in "$src"/agents/*.md; do
  if [ "$mode" = "--link" ]; then
    ln -sfn "$f" "$dest/agents/$(basename "$f")"
  else
    cp -f "$f" "$dest/agents/"
  fi
  echo "  agents/$(basename "$f")"
done

if [ "$mode" = "--link" ]; then
  ln -sfn "$src/skills/build/SKILL.md" "$dest/skills/build/SKILL.md"
else
  cp -f "$src/skills/build/SKILL.md" "$dest/skills/build/"
fi
echo "  skills/build/SKILL.md"

echo "Installed to $dest — restart Claude Code to pick them up."
