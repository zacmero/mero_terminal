---
name: headroom
description: >-
  Context compression layer and token efficiency manager via Headroom proxy and MCP.
  Use when user asks about "headroom", "token compression", "proxy compression",
  "check savings", "headroom stats", or wants to inspect compressed context savings.
---

# Headroom Context Compression

Headroom is an open-source, local-first context compression layer for AI coding agents. It intercepts tool outputs, terminal logs, and context payloads to compress them before sending to LLM providers while retaining exact semantic accuracy.

> [!CAUTION]
> **Delicate Projects Warning**: In projects with fragile multi-file AST relations, complex macros, or byte-exact binary/protocol formats, aggressive tool output compression can hide critical subtle compiler warnings or context. Keep this plugin **disabled** in delicate codebases unless explicit token compression is desired.

## Operating Principles

1. **Local Proxy**: Runs locally on `http://127.0.0.1:18996` with `HEADROOM_TELEMETRY=off`.
2. **MCP Exposure**: Exposes context retrieval and token compression tools when the plugin is active.
3. **RTK Support**: RTK (`rtk`) is available globally as a command runner/filter.

## Checking Live Metrics

To view applied compression frames, tokens saved, and fail-open status:

```bash
# In shell:
codexh savings
# or check status:
headroom status
```

## Toggling Headroom in Antigravity

- **Enable**: Set `"headroom": { "enabled": true }` in `~/.gemini/config/config.json` (or `antigravity/config.json`).
- **Disable**: Set `"headroom": { "enabled": false }` in `~/.gemini/config/config.json`.
