#!/usr/bin/env bash
# Reads what a plugin would run BEFORE you install it: ./revisar-plugin.sh <plugin-folder>
# (the folder containing .claude-plugin/plugin.json, inside the repository you cloned)
set -euo pipefail
dir="${1:?Usage: ./revisar-plugin.sh <plugin-folder>}"
[ -f "$dir/.claude-plugin/plugin.json" ] || { echo "Can't find $dir/.claude-plugin/plugin.json" >&2; exit 1; }
cd "$dir"

echo "== Manifest"; cat .claude-plugin/plugin.json; echo

echo; echo "== Hooks: the command of each one"
cat hooks/hooks.json 2>/dev/null || echo "(no hooks/hooks.json)"

echo; echo "== MCP servers: the command or URL of each one"
cat .mcp.json 2>/dev/null || echo "(no .mcp.json)"

echo; echo "== bin/: added to Bash's PATH (plugin details doesn't list it: read all of it)"
if [ -d bin ]; then
  for f in bin/*; do [ -f "$f" ] || continue; echo "--- $f"; head -50 "$f"; done
else
  echo "(no bin/)"
fi

echo; echo "== Skills with allowed-tools"
grep -rn 'allowed-tools' skills 2>/dev/null || echo "(none)"

echo; echo "== Inventory according to Claude Code (reads the files, doesn't open a session)"
name=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' .claude-plugin/plugin.json)
if command -v claude >/dev/null; then
  claude --plugin-dir . plugin details "$name" || echo "(claude plugin details failed)"
else
  echo "(claude isn't installed: skipping this step)"
fi
