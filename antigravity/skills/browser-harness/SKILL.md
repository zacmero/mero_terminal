---
name: browser-harness
description: "Always use browser-harness for any web interaction: automation, scraping, testing, or site/app work."
---

# browser-harness

Direct browser control via Chrome DevTools Protocol (CDP). For task-specific edits, use `agent-workspace/agent_helpers.py`.

## When Not to Use

A basic fetch of public information needs no browser. If a plain HTTP request can read it — a public page, an API, docs — use `curl` or standard fetch tools. Use browser-harness when the task needs interaction (click, type, navigate), the user's logged-in session, JS rendering, or a bot-protected page.

## Usage

```bash
browser-harness <<'PY'
print(page_info())
PY
```

- Invoke as `browser-harness`. Use heredocs for multi-line commands.
- Helpers are pre-imported. `run.py` calls `ensure_daemon()` before `exec`.
- First navigation is `new_tab(url)`, not `goto_url(url)`.
- `new_tab()` and `switch_tab()` attach and move without changing Chrome's visible tab. Screenshots and normal CDP input work in the background; call `activate_tab(target)` only when explicitly requested.

## Diagnostics

If the daemon cannot connect, run diagnostics:

```bash
browser-harness --doctor
```

## Page Workflow

1. **Accessibility Tree First**: Prefer finding elements with the accessibility tree: `cdp("Accessibility.getFullAXTree")["nodes"]` (role, name, and `backendDOMNodeId`).
2. **Coordinates Calculation**: Box model center via `cdp("DOM.getBoxModel", backendNodeId=n)`.
3. **Targeted Interaction**: `click_at_xy(x, y)` -> verify with `js(...)` or `page_info()`.
4. **Navigation**: Always call `wait_for_load()` after navigating.
5. **Self-Healing Helpers**: If a complex interaction is missing a helper, implement the helper in `$BH_AGENT_WORKSPACE/agent_helpers.py` using raw CDP calls.
