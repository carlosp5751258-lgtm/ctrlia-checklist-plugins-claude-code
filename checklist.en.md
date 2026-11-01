# Before installing plugins, skills or MCP in Claude Code


- [ ] **1. Know what the thing you're installing can do.**
  - Why: each kind of extension reaches different places, and almost all of them run code with your permissions.
  - Editor extension (VS Code, Cursor): JavaScript code running in the editor as your user. That's what happened in Cursor.
  - Claude Code plugin: according to the [official docs](https://code.claude.com/docs/en/plugins/security), it "can execute arbitrary code on your machine with your user privileges". It can bring **hooks** (shell commands at lifecycle points), **monitors** (background commands that start on their own when the session begins), **mods** (JavaScript inside Claude Code), **MCP and LSP servers** (processes on your machine), a **bin/** folder added to Bash's PATH, and skills, commands and agents that enter the context as instructions.
  - Standalone skill: instructions, but it can include scripts and an `allowed-tools` that approves tools without asking during its turn.
  - MCP server: a local process (stdio) or a remote service that gives Claude tools and returns content that may carry prompt injection.
  - The key point: permission rules and the sandbox cover the calls Claude makes, not the code the plugin runs on its own. Hooks, monitors, MCP and LSP servers run **outside the sandbox** with all your permissions. And without managed settings or a Team or Enterprise session, a mod can approve a call your deny rule rejects.
- [ ] **2. Check the store and the publisher.**
  - Why: a marketplace or publisher name tells you who publishes the catalog, not what each thing inside it does.
  - Plugins: Claude Code sorts marketplaces into three tiers. **Official** (`claude-plugins-official` and other reserved names), **community** (`claude-community`, `claude-plugins-community` and `healthcare`) and **third-party** (everything else, including your company's or a coworker's). Claude Code only accepts the official and community names if the marketplace comes from a `github.com/anthropics/` repository, so a third party can't impersonate Anthropic: if it tries, it fails with "Marketplace is registered from an untrusted source". In the community tier, almost every entry is pinned to a commit and Claude Code refuses to install a different one.
  - How to check it: `claude plugin marketplace list` prints the source of each marketplace (GitHub repository or folder).
  - Editor extensions: on the VS Code Marketplace, the publisher of `anthropic.claude-code` is marked as verified with the anthropic.com domain (we saw it in the Marketplace API on Nov 1, 2026: 29.2 million installs, latest version 2.1.314); on Open VSX it's listed as verified, version 2.1.316. Always look at the exact `publisher.name` identifier and be wary of copies with similar names. But remember Cursor: a verified publisher helps, it doesn't guarantee.
- [ ] **3. Read what it brings before turning it on.**
  - Why: the "Will install" section of the `/plugin` panel shows that a plugin has a hook, but not what it runs.
  - Step 1 (the order is the one the official docs suggest): in a session, `/plugin`, pick the plugin and read the details panel: commands, agents, skills, hooks and MCP and LSP servers. If it says "Component summary not available for remote plugin", the plugin is downloaded from somewhere else: all the more reason to read the code.
  - Step 2: open **Open homepage** or **View on GitHub** and find the plugin's folder. Read three things: `hooks/hooks.json` (each hook's command), `.mcp.json` (each server's command or URL) and **every** file in `bin/`.
  - Step 3: clone the repository and run `claude --plugin-dir <folder> plugin details <name>`: it reads the files without opening a session and lists the inventory. We tried it with a test plugin: it showed the skill, the SessionStart hook and the MCP server, **but not the bin/ folder**, so you have to check that one by hand. The repository's `revisar-plugin.sh` script does steps 2 and 3 in one go.
  - Step 4: after installing, `claude plugin details <name>` shows the same for the installed copy in `~/.claude/plugins/cache/`.
  - Standalone skills: read the whole `SKILL.md` and any script that comes with it; be wary of a broad `allowed-tools` (`Bash`, `Bash(curl *)`) and of instructions telling Claude to download or run something.

```bash
# Review a cloned plugin before installing it (real output, Claude Code 2.1.316)
git clone https://github.com/<author>/<marketplace>.git /tmp/revisar && cd /tmp/revisar
# 1. What does it run?
cat <plugin>/hooks/hooks.json <plugin>/.mcp.json 2>/dev/null
ls -la <plugin>/bin/ 2>/dev/null && head -50 <plugin>/bin/*
# 2. Inventory without opening a session
claude --plugin-dir <plugin> plugin details <plugin>

# Output with our test plugin:
# plugin-dudoso 0.1.0
#   Source: plugin-dudoso@inline
# Component inventory
#   Skills (1)  saludo
#   Agents (0)
#   Hooks (1)  SessionStart  (harness-only — no model context cost)
#   MCP servers (1)  eco  (tool schemas resolved at runtime; not counted)
#   LSP servers (0)
# (it doesn't mention bin/herramienta: check bin/ by hand)
```

- [ ] **4. Pin the version and decide on updates.**
  - Why: what you reviewed today can change tomorrow. According to the docs, when auto-update is on for a marketplace, Claude Code updates its plugins in the background, so "the files you reviewed can change on disk". The running session keeps what it loaded; you'll see `Plugin updated: <name> · Run /reload-plugins to apply` and the next session loads the new version.
  - Defaults: auto-update is **on** for `claude-plugins-official` and the other official names (except `knowledge-work-plugins` and `first-party-plugins`) and for marketplaces added from claude.ai; it's **off** for the community one, third-party ones and local ones.
  - How to control it: in `/plugin`, **Marketplaces** tab, pick the marketplace and **Enable/Disable auto-update**. To pin a version, add the marketplace with a tag: `/plugin marketplace add your-org/plugins#v1.2.0`. Watch out: `claude plugin marketplace update` with no name refreshes the catalogs but doesn't update your plugins.
  - Editor extensions: if you'd rather review before updating, turn off automatic extension updates in the editor (in VS Code, the `extensions.autoUpdate` setting) and check the version with `code --list-extensions --show-versions` (in Cursor, `cursor --list-extensions --show-versions`). After an incident like Cursor's, updating quickly to a clean version also matters: it's a balance.
- [ ] **5. Choose the smallest scope.**
  - Why: the less reach, the less damage. When you install a plugin you choose where it's enabled.
  - User (`enabledPlugins` in `~/.claude/settings.json`): in all your projects on this machine. It's the default for `claude plugin install`.
  - Project (`.claude/settings.json`, goes in git): for everyone working in the repo. Committing that entry enables it for your teammates but doesn't download it for them: each one has to install it once with `--scope project`.
  - Local (`.claude/settings.local.json`): just you, just in this repo.
  - Priority: if the same plugin is in several scopes, local beats project and project beats user. Keep in mind that the terminal, local desktop app sessions and the VS Code extension read the same files: what you install at user level in one shows up in the other two.
  - How to check it: `claude plugin list` shows each plugin's `Version`, `Scope` and `Status`. Try it locally first; move it to the project only once the team has reviewed it. And if a plugin asks you to run a command when installing (`Run this command now? [y/N]`), read it: it's code that runs in your terminal.
- [ ] **6. MCP servers: approve them one by one.**
  - Why: a local MCP server is a process with your permissions, and a remote one receives whatever Claude sends it. The [official docs](https://code.claude.com/docs/en/mcp) recommend writing your own servers or using ones from providers you trust; Anthropic reviews the connectors in its directory against some criteria, but doesn't audit the security of any MCP server.
  - What protects you: in an interactive session, Claude Code asks for approval before using the servers in a project's `.mcp.json`, and a cloned repo can't approve its own: `enableAllProjectMcpServers` in its `.claude/settings.json` is ignored while you haven't trusted the folder. We checked it: the test repo's server showed "⏸ Pending approval (run `claude` to approve)". Also, in a remote server's `url` and `headers`, Claude Code leaves credential variables empty so a `.mcp.json` can't send your token to someone else's server.
  - What doesn't protect you: with `claude -p` in a folder you never trusted, the servers in `.mcp.json` connect without asking. And reviewing `.mcp.json` doesn't show everything: plugins and claude.ai connectors also add servers.
  - How to check it: `claude mcp list` and `/mcp`. To reject one by name in every session, `disabledMcpjsonServers`. To forget your approvals, `claude mcp reset-project-choices`. More about servers in [MCP for developers](https://ctrlia.dev/en/recetas/mcp-para-programadores.html).
- [ ] **7. Have a removal plan ready.**
  - Why: if you stop trusting something, uninstalling doesn't always remove everything.
  - Plugins: `claude plugin uninstall <plugin> --scope <scope>`, with the scope you installed it in. Then check: the plugin's persistent data is deleted if it was its last scope (unless `--keep-data`), but its files stay in `~/.claude/plugins/cache/<marketplace>/<plugin>/` for **14 days** until a background cleanup removes them; delete them yourself if you want them gone now. Dependencies installed automatically stay until `claude plugin prune`. If you don't trust the marketplace owner either, remove it: removing a marketplace uninstalls all its plugins.
  - Editor extensions: uninstalling doesn't undo what the code already did. In the Cursor case, the extension left scripts and an SSH key that stayed behind: you had to clean up with the scripts in the notice, check `~/.ssh/authorized_keys` and change, from another machine, the credentials the machine could reach (GitHub, cloud, npm, CI).
  - How to check it: after removing something, `claude plugin list` shouldn't show it, `ls ~/.claude/plugins/cache/` shouldn't have its folder and `/hooks` and `/mcp` shouldn't list anything of its own.

What you have installed and where it comes from (the repository includes it as `inventario.sh`, which only reads):

```bash
claude plugin marketplace list          # source of each marketplace
claude plugin list                      # version, scope and status of each plugin
claude mcp list                         # MCP servers and their status
code --list-extensions --show-versions | grep -i claude
cursor --list-extensions --show-versions | grep -i claude   # if you use Cursor
# Check for the Cursor case (Oct 29, 2026):
grep -qs svc-telemetry ~/.ssh/authorized_keys && echo "Clave svc-telemetry encontrada" || echo "Sin clave"
```

Removing a plugin completely:

```bash
claude plugin uninstall <plugin>@<marketplace> --scope user
claude plugin prune                     # dependencies installed automatically
rm -rf ~/.claude/plugins/cache/<marketplace>/<plugin>/   # if you don't want to wait 14 days
claude plugin marketplace remove <marketplace>           # if you don't trust the store either
```

If you're looking for what to install, start with our list of [recommended skills](https://ctrlia.dev/en/recetas/skills-que-instalar.html), and before granting permissions, go through the [permissions checklist](https://ctrlia.dev/en/recetas/checklist-permisos-claude-code.html).

---
Full version, with common mistakes and FAQ: https://ctrlia.dev/en/recetas/checklist-plugins-claude-code.html · Tested with Claude Code 2.1.316 · MIT
