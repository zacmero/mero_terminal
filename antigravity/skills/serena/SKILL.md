---
name: serena
description: >-
  Semantic code intelligence and symbol-level navigation using the Serena MCP toolkit.
  Use when analyzing large codebases, locating functions/classes/types, tracing symbol
  dependencies and references across multiple files, or performing semantic code refactoring.
---

# Serena Semantic Code Intelligence

Serena transforms AI agents into IDE-aware pair programmers by analyzing relational code symbols and dependencies.

## Available MCP Tools

When the Serena MCP server is active, use its tools over manual file parsing:

- `find_symbol`: Locate declarations of functions, classes, interfaces, or variables across the codebase.
- `get_symbols_overview`: Generate a high-level symbol map of a file or module.
- `find_referencing_symbols`: Trace where a specific symbol is invoked or imported.
- `edit_symbol`: Perform surgical, symbol-aware code refactoring.

## Best Practices

1. **Semantic Search First**: Before grepping large directory trees for symbol definitions, query Serena's symbol index.
2. **Context Preservation**: Leverage symbol overview tools to understand the scope and hierarchy before proposing large refactors.
3. **Graceful Fallback**: If Serena index is building or unavailable, fall back to standard `grep_search` and `view_file`.
