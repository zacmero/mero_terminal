# Portable Antigravity Configuration

This directory is the source of truth for global Google Antigravity (AGY) customizations across machines.

Configuration files and directories here are symlinked into `~/.gemini/config/` (the global Antigravity discovery root).

## Directory Structure

```text
antigravity/
├── README.md           # Documentation for AGY configuration
├── config.json         # Global agent configuration and plugin toggles
├── mcp_config.json     # Global Model Context Protocol (MCP) servers
├── hooks.json          # Global lifecycle hooks (PreToolUse, PostToolUse, Stop, etc.)
├── skills.json         # Explicit skills registry & search entries
├── plugins.json        # Explicit plugins registry & search entries
├── rules/              # Global agent rules and guidelines
│   └── AGENTS.md       # Baseline instructions applied across all sessions
├── skills/             # Custom global skills (e.g. skills/<name>/SKILL.md)
└── plugins/            # Custom global plugins (e.g. plugins/<name>/plugin.json)
```

## Symlink Targets

When `install.sh` runs (or when linking manually), these files link to the standard global discovery paths:

- `~/.gemini/config/config.json` -> `antigravity/config.json`
- `~/.gemini/config/mcp_config.json` -> `antigravity/mcp_config.json`
- `~/.gemini/config/hooks.json` -> `antigravity/hooks.json`
- `~/.gemini/config/skills.json` -> `antigravity/skills.json`
- `~/.gemini/config/plugins.json` -> `antigravity/plugins.json`
- `~/.gemini/config/rules/` -> `antigravity/rules/`
- `~/.gemini/config/skills/` -> `antigravity/skills/`
- `~/.gemini/config/plugins/` -> `antigravity/plugins/`

Machine-local state (conversation databases, tokens, runtime caches in `~/.gemini/antigravity-cli/`) remains strictly local and is never committed to version control.
