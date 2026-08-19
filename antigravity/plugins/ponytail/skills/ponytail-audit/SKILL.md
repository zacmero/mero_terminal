---
name: ponytail-audit
description: >
  Whole-repo audit for over-engineering. Scans the codebase for dead code,
  unneeded dependencies, single-caller wrappers, and hand-rolled stdlib code.
  Use when user says "audit this codebase", "audit for over-engineering",
  "what can I delete from this repo", "find bloat", or "/ponytail-audit".
---

# Ponytail Audit

Repo-wide scan for over-engineering and complexity. Rank findings biggest cut first.

## Tags
- `delete:` dead code, unused flexibility, speculative feature.
- `stdlib:` hand-rolled code the standard library ships.
- `native:` dependency doing what the platform already does.
- `yagni:` single-implementation abstractions, unused config.
- `shrink:` same logic, fewer lines.

## Output
One line per finding, ranked: `<tag> <what to cut>. <replacement>. [path]`
End with: `net: -<N> lines, -<M> deps possible.`
