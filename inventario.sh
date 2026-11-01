#!/usr/bin/env bash
# Qué extensiones de Claude Code tienes instaladas y de dónde vienen: ./inventario.sh
# Solo lee: no instala, no actualiza ni borra nada.
set -euo pipefail
paso() { echo; echo "== $1"; }

if command -v claude >/dev/null; then
  paso "Marketplaces (fuente de cada uno)"; claude plugin marketplace list || true
  paso "Plugins (versión, ámbito y estado)"; claude plugin list || true
  echo "(para los servidores MCP abre /mcp o ejecuta «claude mcp list» en cada proyecto)"
fi
for editor in code cursor; do
  if command -v "$editor" >/dev/null; then
    paso "Extensiones de $editor con «claude»"
    "$editor" --list-extensions --show-versions 2>/dev/null | grep -i claude || echo "(ninguna)"
  fi
done
paso "Caso Cursor (29-oct-2026): clave svc-telemetry en ~/.ssh/authorized_keys"
grep -qs svc-telemetry ~/.ssh/authorized_keys && echo "Clave svc-telemetry encontrada: sigue los pasos de limpieza" || echo "Sin clave"
