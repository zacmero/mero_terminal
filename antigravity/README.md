# Portable Antigravity (AGY) Configuration

This directory is the source of truth for global **Google Antigravity (AGY)** agent configurations, Model Context Protocol (MCP) servers, plugins, skills, and rule sets.

All configuration files and directories here are symlinked into `~/.gemini/config/` (the global Antigravity discovery root) by `install.sh`.

---

## Directory Layout

```text
antigravity/
├── README.md               # Detailed guide for all AGY configurations & tools
├── config.json             # Global agent options & plugin activation states
├── mcp_config.json         # Global MCP server definitions (Serena, Morph)
├── hooks.json              # Global lifecycle hooks (PreToolUse, PostToolUse, Stop)
├── skills.json             # Explicit skills registry & search entries
├── plugins.json            # Explicit plugins registry & search entries
├── rules/                  # Global rules applied across all workspaces
│   └── AGENTS.md           # Core pair-programming and safety guidelines
├── skills/                 # Global custom skills
│   ├── serena/             # Semantic code navigation & symbol intelligence
│   ├── morph/              # Fast code apply & WarpGrep search
│   └── browser-harness/    # Direct Chrome CDP automation & self-healing
└── plugins/                # Modular, toggleable feature bundles
    ├── headroom/           # Context compression layer & MCP proxy (delicate)
    ├── ponytail/           # Lazy senior dev mode & YAGNI rules
    └── caveman/            # Ultra-terse communication & review mode
```

---

## Tool-by-Tool Guide & Particularities

### 1. Serena (`oraios/serena`)
- **Type**: Global MCP Server (`mcp_config.json`) + Skill (`skills/serena/SKILL.md`).
- **Launcher**: `mero-mcp-serena` (isolated runtime directory `SERENA_HOME=/tmp/mero-serena`).
- **Core Capability**: Provides semantic, symbol-level code understanding across 30+ languages using LSP indices.
- **Key MCP Tools**:
  - `find_symbol`: Locate function/class/interface declarations without regex guesswork.
  - `get_symbols_overview`: High-level structural outline of files or modules.
  - `find_referencing_symbols`: Find all call sites and usages across the project.
  - `edit_symbol` / `replace_symbol_body`: Symbol-targeted edits that avoid full-file rewrites.
- **Headless Mode**: The web dashboard and browser opening are intentionally disabled (`--enable-web-dashboard false --open-web-dashboard false`) so Serena functions cleanly as a pure, headless stdio MCP server without external port binding issues.
- **Enforcement Guideline**: Always prioritize Serena semantic symbol navigation over broad grep or reading entire directories into context.

---

### 2. RTK (Rust Token Killer) & Headroom (`headroomlabs-ai/headroom`)
- **RTK CLI (Mandatory Default Filter)**:
  - Prepend `rtk` to standard terminal and shell commands (`rtk git status`, `rtk ls -la`, `rtk test`, `rtk err <cmd>`, `rtk npm ...`, `rtk cargo ...`) to filter noisy boilerplate.
  - **Sensitive / Byte-Exact Bypass**: Use `rtk proxy <command>` or `rtk run <command>` when inspecting sensitive configuration files, raw binary streams, or private keys.
- **Headroom MCP (Context Compression Layer)**:
  - **Type**: Toggleable Plugin (`plugins/headroom/`) + MCP Proxy (`plugins/headroom/mcp_config.json`) + Skill (`plugins/headroom/skills/headroom/`).
  - **Usage**: Actively call `headroom_compress` on massive JSON outputs, server logs, RAG chunks, or bulky query responses.
  - **Safety Rules**:
    - **NEVER** compress sensitive documents, credentials, or private keys.
    - **Fallback Protocol**: If information is missing or truncated after compression, immediately retrieve the uncompressed original via `headroom_retrieve <hash>` or re-run without Headroom.
  - **Live Metrics**: Run `codexh savings` or `headroom status` to inspect tokens saved and proxy health.

---

### 3. Ponytail (`DietrichGebert/ponytail`)
- **Type**: Toggleable Plugin (`plugins/ponytail/`) + Rules (`rules/AGENTS.md`) + Skills (`skills/ponytail*/`).
- **Core Capability**: Enforces a "lazy senior developer" mindset to prevent over-engineering:
  1. *YAGNI:* Does this need to exist at all?
  2. *Reuse:* Already in this codebase?
  3. *Stdlib:* Does standard library do this?
  4. *Platform:* Native HTML/CSS/browser/OS feature covers it?
  5. *Installed Dep:* Solve with already-installed packages?
  6. *One-line:* Can this be a single clean line?
  7. *Minimal Diff:* Minimum code that works.
- **Available Skills**:
  - `/ponytail [lite|full|ultra]`: Active lazy coding mode.
  - `/ponytail-audit`: Whole-repository bloat scan.
  - `/ponytail-debt`: Scan and track deliberate `# ponytail:` shortcut comments.
  - `/ponytail-gain`: Display benchmark impact scoreboard.
  - `/ponytail-review`: Over-engineering diff review.
  - `/ponytail-help`: Reference card.
- **How to Enable / Disable**:
  - **Disabled by default** in `config.json` (`"ponytail": { "enabled": false }`).
  - Enable globally: Set `"ponytail": { "enabled": true }` in `antigravity/config.json`.
  - Use on-demand: Invoke individual skills (`/ponytail`, `/ponytail-audit`, etc.) at any time.

---

### 4. Caveman (`JuliusBrussee/caveman`)
- **Type**: Global Plugin (`plugins/caveman/`) + Skills (`skills/caveman*/`).
- **Core Capability**: Ultra-terse communication style that eliminates pleasantries, articles, and filler words, saving ~75% token usage while keeping code blocks, commands, and error logs byte-for-byte exact.
- **Available Skills**:
  - `/caveman [lite|full|ultra]`: Terse conversational mode.
  - `/caveman-commit`: Terse conventional commit message generator.
  - `/caveman-review`: One-line actionable PR review comments (`L<line>: <problem>. <fix>.`).
- **How to Enable / Disable**:
  - Enabled by default (`"caveman": { "enabled": true }` in `config.json`).
  - Revert to normal prose anytime by saying `"stop caveman"` or `"normal mode"`.

---

### 5. Morph MCP (`@morphllm/morphmcp`)
- **Type**: Global MCP Server (`mcp_config.json`) + Skill (`skills/morph/SKILL.md`).
- **Launcher**: `bin/mero-mcp-morph`.
- **Core Capability**: Ultra-fast code application (10,000+ tokens/sec) and semantic codebase search (`WarpGrep`).
- **Key MCP Tools**:
  - `morph_fast_apply`: Fast code edits using lazy edit markers (`// ... existing code ...`).
  - `warp_grep`: Hybrid keyword and semantic embeddings search.
- **Credentials & Privacy**:
  - `mero-mcp-morph` automatically retrieves `MORPH_API_KEY` from `~/.config/mero/codex-secrets.toml` or the `MORPH_API_KEY` environment variable. Secrets are never checked into Git.

---

### 6. Browser Harness (`browser-use/browser-harness`)
- **Type**: Custom Skill (`skills/browser-harness/SKILL.md`) + CLI Runtime `browser-harness`.
- **Core Capability**: Direct Chrome/Chromium automation using raw Chrome DevTools Protocol (CDP).
- **Self-Healing Architecture**:
  - If a required helper function is missing, the agent defines and executes it in `$BH_AGENT_WORKSPACE/agent_helpers.py`.
- **Execution Workflow**:
  ```bash
  browser-harness <<'PY'
  new_tab("https://example.com")
  print(page_info())
  PY
  ```
- **Diagnostics**: Run `browser-harness --doctor` to verify CDP connection and Chrome remote debugging state (`chrome://inspect/#remote-debugging`).

---

## Managing Plugins & MCPs in Antigravity

To toggle any plugin on or off across your sessions, edit [`config.json`](file:///home/zacmero/mero_terminal/antigravity/config.json):

```json
{
  "plugins": {
    "headroom": { "enabled": false },
    "ponytail": { "enabled": false },
    "caveman": { "enabled": true }
  }
}
```

Running `./install.sh` on any fresh machine installs all underlying runtimes (`uv`, `npm` packages, Python tools) and establishes all symlinks automatically.
