# Before installing plugins, skills or MCP in Claude Code: a checklist (Ctrl+IA)

What to check before installing the editor extension, a plugin, a skill or an MCP server: what it runs on your machine, which store it comes from, how to read it before turning it on, how to control updates and how to remove it completely. It starts from the tampered extension served by the Cursor marketplace (Oct 29, 2026). Scripts and messages are in Spanish.

Full page: https://ctrlia.dev/en/recetas/checklist-plugins-claude-code.html (Español: https://ctrlia.dev/recetas/checklist-plugins-claude-code.html)

## What's inside
| File | What for |
| --- | --- |
| `checklist.en.md` / `checklist.md` | The list to print or tick, with the why and how to check each item |
| `revisar-plugin.sh` | Reads a cloned plugin before installing it: manifest, hooks, `.mcp.json`, **all of `bin/`** (which `plugin details` doesn't list), skills with allowed-tools and the `claude --plugin-dir … plugin details` inventory |
| `inventario.sh` | What you have installed and where it comes from: marketplaces, plugins, VS Code and Cursor extensions and the `svc-telemetry` key check. Read-only |

## How to use it
```bash
git clone https://github.com/<author>/<marketplace>.git /tmp/revisar
./revisar-plugin.sh /tmp/revisar/<plugin-folder>   # the one containing .claude-plugin/plugin.json
./inventario.sh
```

## Tested
With Claude Code 2.1.316 on Linux, with an isolated configuration: `revisar-plugin.sh` on a test plugin with a skill, a hook, an MCP server and `bin/` (and on a folder that isn't a plugin: it exits with code 1), and `inventario.sh` end to end. No real plugins were installed or uninstalled (see the page).

## License
MIT. Copyright (c) 2026 Ctrl+IA (Carlos P.).
