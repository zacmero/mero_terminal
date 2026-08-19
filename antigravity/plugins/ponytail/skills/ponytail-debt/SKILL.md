---
name: ponytail-debt
description: >
  Harvest every `ponytail:` shortcut comment in the codebase into a tracked debt
  ledger. Use when user says "ponytail debt", "/ponytail-debt", "what did ponytail defer",
  "list shortcuts", "ponytail ledger", or "what did we mark to do later".
---

# Ponytail Debt

Collects deliberate `ponytail:` comments into a structured ledger so shortcuts stay visible.

## Scan
`grep -rnE '(#|//) ?ponytail:' .`

## Output
One row per marker:
`<file>:<line>: <what was simplified>. ceiling: <limit>. upgrade: <trigger>.`
End with: `<N> markers, <M> with no trigger.`
