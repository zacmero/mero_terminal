---
name: caveman-review
description: >
  Ultra-compressed code review comments. Cuts noise from PR feedback while preserving
  the actionable signal. Each comment is one line: location, problem, fix. Use when user
  says "review this PR", "code review", "review the diff", "/review", or invokes
  /caveman-review.
---

# Caveman Review

Write code review comments terse and actionable. One line per finding. Location, problem, fix.

## Rules

**Format:** `L<line>: <problem>. <fix>.` — or `<file>:L<line>: ...` for multi-file diffs.

**Severity prefix (optional, when mixed):**
- `🔴 bug:` — broken behavior, will cause incident
- `🟡 risk:` — works but fragile (race, missing null check)
- `🔵 nit:` — style, naming, micro-optim
- `❓ q:` — genuine question

## Examples
- `L42: 🔴 bug: user can be null after .find(). Add guard before .email.`
- `L88-140: 🔵 nit: 50-line fn does 4 things. Extract validate/normalize/persist.`
- `L23: 🟡 risk: no retry on 429. Wrap in withBackoff(3).`
