# Antes de instalar plugins, skills o MCP en Claude Code: checklist (Ctrl+IA)

English version: [README.en.md](README.en.md) (archivos en `en/`).

Qué comprobar antes de instalar la extensión del editor, un plugin, una skill o un servidor MCP: qué ejecuta en tu máquina, de qué tienda viene, cómo leerlo antes de activarlo, cómo controlar las actualizaciones y cómo quitarlo del todo. Parte del caso de la extensión manipulada en el marketplace de Cursor (29-oct-2026).

Página completa: https://ctrlia.dev/recetas/checklist-plugins-claude-code.html (English: https://ctrlia.dev/en/recetas/checklist-plugins-claude-code.html)

## Qué trae
| Archivo | Para qué |
| --- | --- |
| `checklist.md` / `en/checklist.md` | La lista para imprimir o marcar, con el porqué y cómo comprobar cada punto |
| `revisar-plugin.sh` | Lee un plugin clonado antes de instalarlo: manifiesto, hooks, `.mcp.json`, **todo `bin/`** (que `plugin details` no lista), skills con allowed-tools y el inventario de `claude --plugin-dir … plugin details` |
| `inventario.sh` | Qué tienes instalado y de dónde viene: marketplaces, plugins, extensiones de VS Code y Cursor y la comprobación de la clave `svc-telemetry`. Solo lee |

## Cómo usarlo
```bash
git clone https://github.com/<autor>/<marketplace>.git /tmp/revisar
./revisar-plugin.sh /tmp/revisar/<carpeta-del-plugin>   # la que contiene .claude-plugin/plugin.json
./inventario.sh
```

## Probado
Con Claude Code 2.1.316 en Linux, con configuración aislada: `revisar-plugin.sh` sobre un plugin de prueba con skill, hook, servidor MCP y `bin/` (y sobre una carpeta que no es un plugin: sale con código 1), e `inventario.sh` completo. No se instalaron ni desinstalaron plugins reales (ver la página).

## Licencia
MIT. Copyright (c) 2026 Ctrl+IA (Carlos P.).
