---
name: ponytail-review
description: >
  Code review focused exclusively on over-engineering. Finds what to delete:
  reinvented standard library, unneeded dependencies, speculative abstractions.
  Use when user says "review for over-engineering", "what can we delete",
  "is this over-engineered", "simplify review", or invokes /ponytail-review.
---

# Ponytail Review

Review diffs for unnecessary complexity. One line per finding: location, what to cut, what replaces it.

## Format
`L<line>: <tag> <what>. <replacement>.`

Tags: `delete:`, `stdlib:`, `native:`, `yagni:`, `shrink:`.

## Scoring
End with: `net: -<N> lines possible.`
If clean: `Lean already. Ship.`
