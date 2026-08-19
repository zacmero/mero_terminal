---
name: morph
description: >-
  Ultra-fast code editing and agentic codebase search powered by Morph MCP.
  Use when performing rapid multi-file edits, applying surgical diffs with lazy edit markers,
  or running semantic search across large codebases with WarpGrep.
---

# Morph Fast Apply & WarpGrep

Morph MCP provides high-speed code manipulation and semantic codebase indexing.

## Available Tools

- `morph_fast_apply`: Applies diffs and code transformations at 10,000+ tokens/sec using lazy edit markers (`// ... existing code ...`).
- `warp_grep`: Agentic, intelligent codebase search combining keyword and semantic embeddings.

## Usage Guidelines

1. **Authentication**: `mero-mcp-morph` automatically retrieves the `MORPH_API_KEY` from `~/.config/mero/codex-secrets.toml` or the `MORPH_API_KEY` environment variable.
2. **Lazy Edit Markers**: When calling `morph_fast_apply`, replace unchanged code sections with standard comment markers rather than repeating entire files.
3. **Verification**: Always inspect modified files following rapid multi-file transforms to verify linting and structural validity.
