# Portable Codex configuration

This directory is the source of truth for the shared Codex configuration and
the MCP launchers. `~/.codex/config.toml` is a symlink to `config.toml` here.

The rest of `~/.codex` stays machine-local. Never sync its sessions, SQLite
files, history, credentials, or logs. Atuin Threads supports encrypted handoff
of captured conversation records to another machine, using Atuin's filters and
existing sync account. See the [Mero Terminal README](../README.md) for the
capture policy, migration, and resume workflow.

## Install on another machine

Clone or sync `mero_terminal`, then install the pinned MCP runtimes:

```bash
mkdir -p "$HOME/.local/share/mero-mcp/morph" "$HOME/.local/share/mero-mcp/playwright"
npm install --prefix "$HOME/.local/share/mero-mcp/morph" --no-save --no-package-lock --omit=dev @morphllm/morphmcp@0.8.207
npm install --prefix "$HOME/.local/share/mero-mcp/playwright" --no-save --no-package-lock --omit=dev @playwright/mcp@0.0.79
uv tool install --force --from git+https://github.com/oraios/serena@f1d78a88cec2031d6b699c9944839979e9a0175d serena-agent
```

Install the launchers and config link:

```bash
mkdir -p "$HOME/.local/bin" "$HOME/.config/mero"
ln -sfn "$HOME/mero_terminal/codex/bin/mero-mcp-serena" "$HOME/.local/bin/mero-mcp-serena"
ln -sfn "$HOME/mero_terminal/codex/bin/mero-mcp-morph" "$HOME/.local/bin/mero-mcp-morph"
ln -sfn "$HOME/mero_terminal/codex/bin/mero-mcp-playwright" "$HOME/.local/bin/mero-mcp-playwright"
ln -sfn "$HOME/mero_terminal/codex/config.toml" "$HOME/.codex/config.toml"
```

Create `$HOME/.config/mero/codex-secrets.toml` with mode `600` and put the
Morph key there. It is intentionally outside this syncable directory:

```toml
[mcp_servers.morph-mcp.env]
MORPH_API_KEY = "your-key"
```

The Morph launcher reads that file without putting the key in the shared
Codex config or its process arguments. The Serena launcher uses `/tmp` for its
writable runtime home because Codex sandboxes may make `$HOME` read-only.

Install the `mero-headroom` repository and its existing `codexh` symlinks
separately. Restart Codex after changing this configuration.

## Atuin Threads MCP

Atuin captures and syncs threads independently of MCP. The managed Codex
configuration leaves Atuin MCP disabled on ordinary launches. Enable it for a
single invocation when an agent needs to read a previous conversation.

```bash
rtk codex -c 'mcp_servers.atuin.enabled=true'
```

The opt-in exposes `atuin_threads_search`, `atuin_threads_list`, and
`atuin_threads_read`. Ask Codex to search for a specific topic and read the
relevant messages in small pages. In the interactive CLI, `/mcp` shows the
server status. A new `rtk codex` launch uses the disabled default again. Use
`rtk atuin threads search` and `rtk atuin threads show` to inspect a conversation
from the shell.

The server's tools are read-only. The agent can include retrieved text in a
request to its model provider, so only opt in when the conversation is suitable
for that use.
