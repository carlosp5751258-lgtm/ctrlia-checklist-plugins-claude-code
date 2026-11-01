# Antes de instalar plugins, skills o MCP en Claude Code: checklist


- [ ] **1. Sabe qué puede hacer lo que vas a instalar.**
  - Por qué: cada tipo de extensión llega a sitios distintos, y casi todos ejecutan código con tus permisos.
  - Extensión del editor (VS Code, Cursor): código JavaScript que corre en el editor con tu usuario. Es lo que pasó en Cursor.
  - Plugin de Claude Code: según la [documentación oficial](https://code.claude.com/docs/es/plugins/security), «puede ejecutar código arbitrario en tu máquina con tus privilegios de usuario». Puede traer **hooks** (comandos de shell en momentos del ciclo de vida), **monitores** (comandos en segundo plano que arrancan solos al empezar la sesión), **mods** (JavaScript dentro de Claude Code), **servidores MCP y LSP** (procesos en tu máquina), una carpeta **bin/** que se añade al PATH de Bash, y skills, comandos y agentes que entran en el contexto como instrucciones.
  - Skill suelta: son instrucciones, pero pueden incluir scripts y un `allowed-tools` que aprueba herramientas sin preguntar durante su turno.
  - Servidor MCP: un proceso local (stdio) o un servicio remoto que le da herramientas a Claude y le devuelve contenido que puede traer inyección de instrucciones.
  - Lo clave: las reglas de permisos y el sandbox cubren las llamadas que hace Claude, no el código que el plugin ejecuta por su cuenta. Hooks, monitores, servidores MCP y LSP corren **fuera del sandbox** con todos tus permisos. Y sin ajustes administrados ni sesión de Team o Enterprise, un mod puede aprobar una llamada que tu regla deny rechaza.
- [ ] **2. Comprueba la tienda y el publicador.**
  - Por qué: el nombre de un marketplace o de un publicador te dice quién publica el catálogo, no qué hace cada cosa que hay dentro.
  - Plugins: Claude Code clasifica los marketplaces en tres niveles. **Oficial** (`claude-plugins-official` y otros nombres reservados), **comunidad** (`claude-community`, `claude-plugins-community` y `healthcare`) y **terceros** (todos los demás, incluido el de tu empresa o un compañero). Claude Code solo acepta los nombres oficiales y de comunidad si el marketplace viene de un repositorio `github.com/anthropics/`, así que un tercero no puede hacerse pasar por Anthropic: si lo intenta, falla con «Marketplace is registered from an untrusted source». En la comunidad, casi todas las entradas están fijadas a un commit y Claude Code se niega a instalar otro.
  - Cómo comprobarlo: `claude plugin marketplace list` imprime la fuente de cada marketplace (repositorio de GitHub o carpeta).
  - Extensiones del editor: en el Marketplace de VS Code, el publicador de `anthropic.claude-code` está marcado como verificado con el dominio anthropic.com (lo vimos en la API del Marketplace el 1-nov-2026: 29,2 millones de instalaciones, última versión 2.1.314); en Open VSX figura como verificado, versión 2.1.316. Mira siempre el identificador exacto `publicador.nombre` y desconfía de copias con nombres parecidos. Pero recuerda Cursor: el publicador verificado ayuda, no garantiza.
- [ ] **3. Lee lo que trae antes de activarlo.**
  - Por qué: la sección «Will install» del panel de `/plugin` muestra que un plugin tiene un hook, pero no qué ejecuta.
  - Paso 1 (el orden lo propone la documentación oficial): en una sesión, `/plugin`, elige el plugin y lee el panel de detalles: comandos, agentes, skills, hooks y servidores MCP y LSP. Si dice «Component summary not available for remote plugin», el plugin se descarga de otro sitio: más motivo para leer el código.
  - Paso 2: abre **Open homepage** o **View on GitHub** y busca la carpeta del plugin. Lee tres cosas: `hooks/hooks.json` (el comando de cada hook), `.mcp.json` (el comando o la URL de cada servidor) y **todos** los archivos de `bin/`.
  - Paso 3: clona el repositorio y ejecuta `claude --plugin-dir <carpeta> plugin details <nombre>`: lee los archivos sin abrir una sesión y lista el inventario. Lo probamos con un plugin de prueba: mostró la skill, el hook SessionStart y el servidor MCP, **pero no la carpeta bin/**, así que esa hay que mirarla a mano. El script `revisar-plugin.sh` del repositorio hace los pasos 2 y 3 de una vez.
  - Paso 4: después de instalar, `claude plugin details <nombre>` muestra lo mismo para la copia instalada en `~/.claude/plugins/cache/`.
  - Skills sueltas: lee el `SKILL.md` completo y cualquier script que acompañe; desconfía de un `allowed-tools` amplio (`Bash`, `Bash(curl *)`) y de instrucciones que manden descargar o ejecutar algo.

```bash
# Revisa un plugin clonado antes de instalarlo (salida real, Claude Code 2.1.316)
git clone https://github.com/<autor>/<marketplace>.git /tmp/revisar && cd /tmp/revisar
# 1. ¿Qué ejecuta?
cat <plugin>/hooks/hooks.json <plugin>/.mcp.json 2>/dev/null
ls -la <plugin>/bin/ 2>/dev/null && head -50 <plugin>/bin/*
# 2. Inventario sin abrir sesión
claude --plugin-dir <plugin> plugin details <plugin>

# Salida con nuestro plugin de prueba:
# plugin-dudoso 0.1.0
#   Source: plugin-dudoso@inline
# Component inventory
#   Skills (1)  saludo
#   Agents (0)
#   Hooks (1)  SessionStart  (harness-only — no model context cost)
#   MCP servers (1)  eco  (tool schemas resolved at runtime; not counted)
#   LSP servers (0)
# (no menciona bin/herramienta: revisa bin/ a mano)
```

- [ ] **4. Fija la versión y decide las actualizaciones.**
  - Por qué: lo que revisaste hoy puede cambiar mañana. Según la documentación, cuando la actualización automática está activa para un marketplace, Claude Code actualiza sus plugins en segundo plano, así que «los archivos que revisaste pueden cambiar en disco». La sesión en marcha sigue con lo que cargó; verás `Plugin updated: <nombre> · Run /reload-plugins to apply` y la siguiente sesión carga la versión nueva.
  - Valores por defecto: la actualización automática viene **activada** en `claude-plugins-official` y en los demás nombres oficiales (salvo `knowledge-work-plugins` y `first-party-plugins`) y en los marketplaces añadidos desde claude.ai; viene **desactivada** en el de comunidad, en los de terceros y en los locales.
  - Cómo controlarlo: en `/plugin`, pestaña **Marketplaces**, elige el marketplace y **Enable/Disable auto-update**. Para fijar una versión, añade el marketplace con una etiqueta: `/plugin marketplace add tu-org/plugins#v1.2.0`. Ojo: `claude plugin marketplace update` sin nombre refresca los catálogos pero no actualiza tus plugins.
  - Extensiones del editor: si prefieres revisar antes de actualizar, desactiva la actualización automática de extensiones en el editor (en VS Code, el ajuste `extensions.autoUpdate`) y mira la versión con `code --list-extensions --show-versions` (en Cursor, `cursor --list-extensions --show-versions`). Tras un incidente como el de Cursor, actualizar rápido a una versión limpia también importa: es un equilibrio.
- [ ] **5. Elige el ámbito más pequeño.**
  - Por qué: cuanto menos alcance, menos daño. Al instalar un plugin eliges dónde queda activado.
  - Usuario (`enabledPlugins` en `~/.claude/settings.json`): en todos tus proyectos de esta máquina. Es el valor por defecto de `claude plugin install`.
  - Proyecto (`.claude/settings.json`, va en git): para todo el que trabaje en el repo. Subir esa entrada lo activa para tus compañeros, pero no se lo descarga: cada uno tiene que instalarlo una vez con `--scope project`.
  - Local (`.claude/settings.local.json`): solo tú, solo en este repo.
  - Prioridad: si el mismo plugin está en varios ámbitos, gana local sobre proyecto y proyecto sobre usuario. Ten en cuenta que la terminal, las sesiones locales de la app de escritorio y la extensión de VS Code leen los mismos archivos: lo que instalas a nivel de usuario en una aparece en las otras dos.
  - Cómo comprobarlo: `claude plugin list` muestra `Version`, `Scope` y `Status` de cada plugin. Prueba primero en local; súbelo al proyecto solo cuando el equipo lo haya revisado. Y si un plugin te pide ejecutar un comando al instalarse (`Run this command now? [y/N]`), léelo: es código que corre en tu terminal.
- [ ] **6. Servidores MCP: aprueba uno por uno.**
  - Por qué: un servidor MCP local es un proceso con tus permisos, y uno remoto recibe lo que Claude le envía. La [documentación oficial](https://code.claude.com/docs/en/mcp) recomienda escribir tus propios servidores o usar los de proveedores en los que confíes; Anthropic revisa los conectores de su directorio con unos criterios, pero no audita la seguridad de ningún servidor MCP.
  - Lo que te protege: en una sesión interactiva, Claude Code pide aprobación antes de usar los servidores del `.mcp.json` de un proyecto, y un repo clonado no puede aprobarse los suyos: `enableAllProjectMcpServers` en su `.claude/settings.json` se ignora mientras no confíes en la carpeta. Lo comprobamos: el servidor del repo de prueba salía «⏸ Pending approval (run `claude` to approve)». Además, en la `url` y las `headers` de un servidor remoto, Claude Code deja vacías las variables de credenciales para que un `.mcp.json` no envíe tu token a un servidor ajeno.
  - Lo que no te protege: con `claude -p` en una carpeta en la que nunca confiaste, los servidores de `.mcp.json` se conectan sin preguntar. Y revisar el `.mcp.json` no muestra todo: los plugins y los conectores de claude.ai también añaden servidores.
  - Cómo comprobarlo: `claude mcp list` y `/mcp`. Para rechazar uno por nombre en todas las sesiones, `disabledMcpjsonServers`. Para olvidar tus aprobaciones, `claude mcp reset-project-choices`. Más sobre servidores en [MCP para programadores](https://ctrlia.dev/recetas/mcp-para-programadores.html).
- [ ] **7. Ten listo el plan para quitarlo.**
  - Por qué: si dejas de confiar en algo, desinstalar no siempre lo borra todo.
  - Plugins: `claude plugin uninstall <plugin> --scope <ámbito>`, con el ámbito en el que lo instalaste. Luego revisa: los datos persistentes del plugin se borran si era su último ámbito (salvo `--keep-data`), pero sus archivos se quedan en `~/.claude/plugins/cache/<marketplace>/<plugin>/` durante **14 días** hasta que una limpieza en segundo plano los elimina; bórralos tú si quieres que desaparezcan ya. Las dependencias que se instalaron solas se quedan hasta `claude plugin prune`. Si tampoco confías en el dueño del marketplace, quítalo: al eliminar un marketplace se desinstalan todos sus plugins.
  - Extensiones del editor: desinstalar no deshace lo que el código ya hizo. En el caso de Cursor, la extensión dejaba scripts y una clave SSH que seguían ahí: había que limpiar con los scripts del aviso, revisar `~/.ssh/authorized_keys` y cambiar, desde otro equipo, las credenciales a las que llegaba la máquina (GitHub, nube, npm, CI).
  - Cómo comprobarlo: después de quitar algo, `claude plugin list` no debe mostrarlo, `ls ~/.claude/plugins/cache/` no debe tener su carpeta y `/hooks` y `/mcp` no deben listar nada suyo.

Qué tienes instalado y de dónde viene (el repositorio lo trae como `inventario.sh`, que solo lee):

```bash
claude plugin marketplace list          # fuente de cada marketplace
claude plugin list                      # versión, ámbito y estado de cada plugin
claude mcp list                         # servidores MCP y su estado
code --list-extensions --show-versions | grep -i claude
cursor --list-extensions --show-versions | grep -i claude   # si usas Cursor
# Comprobación del caso Cursor (29-oct-2026):
grep -qs svc-telemetry ~/.ssh/authorized_keys && echo "Clave svc-telemetry encontrada" || echo "Sin clave"
```

Quitar un plugin del todo:

```bash
claude plugin uninstall <plugin>@<marketplace> --scope user
claude plugin prune                     # dependencias que se instalaron solas
rm -rf ~/.claude/plugins/cache/<marketplace>/<plugin>/   # si no quieres esperar 14 días
claude plugin marketplace remove <marketplace>           # si tampoco confías en la tienda
```

Si buscas qué instalar, empieza por nuestra lista de [skills recomendadas](https://ctrlia.dev/recetas/skills-que-instalar.html), y antes de dar permisos, repasa la [checklist de permisos](https://ctrlia.dev/recetas/checklist-permisos-claude-code.html).

---
Versión completa, con errores típicos y preguntas frecuentes: https://ctrlia.dev/recetas/checklist-plugins-claude-code.html · Probado con Claude Code 2.1.316 · MIT
