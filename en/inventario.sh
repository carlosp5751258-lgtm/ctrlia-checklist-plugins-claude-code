#!/usr/bin/env bash
# Which Claude Code extensions you have installed and where they come from: ./inventario.sh
# Read-only: it doesn't install, update or delete anything.
set -euo pipefail
step() { echo; echo "== $1"; }

if command -v claude >/dev/null; then
  step "Marketplaces (source of each one)"; claude plugin marketplace list || true
  step "Plugins (version, scope and status)"; claude plugin list || true
  echo "(for MCP servers open /mcp or run \"claude mcp list\" in each project)"
fi
for editor in code cursor; do
  if command -v "$editor" >/dev/null; then
    step "$editor extensions matching \"claude\""
    "$editor" --list-extensions --show-versions 2>/dev/null | grep -i claude || echo "(none)"
  fi
done
step "Cursor case (Oct 29, 2026): svc-telemetry key in ~/.ssh/authorized_keys"
grep -qs svc-telemetry ~/.ssh/authorized_keys && echo "svc-telemetry key found: follow the cleanup steps" || echo "No key"
