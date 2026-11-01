#!/usr/bin/env bash
# Lee lo que ejecutaría un plugin ANTES de instalarlo: ./revisar-plugin.sh <carpeta-del-plugin>
# (la carpeta que contiene .claude-plugin/plugin.json, dentro del repositorio que clonaste)
set -euo pipefail
dir="${1:?Uso: ./revisar-plugin.sh <carpeta-del-plugin>}"
[ -f "$dir/.claude-plugin/plugin.json" ] || { echo "No encuentro $dir/.claude-plugin/plugin.json" >&2; exit 1; }
cd "$dir"

echo "== Manifiesto"; cat .claude-plugin/plugin.json; echo

echo; echo "== Hooks: el comando de cada uno"
cat hooks/hooks.json 2>/dev/null || echo "(sin hooks/hooks.json)"

echo; echo "== Servidores MCP: el comando o la URL de cada uno"
cat .mcp.json 2>/dev/null || echo "(sin .mcp.json)"

echo; echo "== bin/: se añade al PATH de Bash (plugin details no lo lista: léelo entero)"
if [ -d bin ]; then
  for f in bin/*; do [ -f "$f" ] || continue; echo "--- $f"; head -50 "$f"; done
else
  echo "(sin bin/)"
fi

echo; echo "== Skills con allowed-tools"
grep -rn 'allowed-tools' skills 2>/dev/null || echo "(ninguna)"

echo; echo "== Inventario según Claude Code (lee los archivos, no abre sesión)"
nombre=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["name"])' .claude-plugin/plugin.json)
if command -v claude >/dev/null; then
  claude --plugin-dir . plugin details "$nombre" || echo "(claude plugin details falló)"
else
  echo "(claude no está instalado: salta este paso)"
fi
