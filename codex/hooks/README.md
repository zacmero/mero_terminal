# Codex operator RTK hook

`rtk-required.py` enforces the coding operator's mandatory RTK output policy.
It is not Sera's runtime, model routing or a shell security sandbox.

The hook accepts RTK-filtered commands and an explicit `rtk proxy` for exact
output. Existing native RTK attestation handles supported raw command rewrites;
unsupported raw commands and outer shell chains remain rejected.

The quote check reads the original shell text before `shlex` discards quotation.
Single-quoted Python/Markdown and correctly escaped literal backticks or `$(...)`
are data. Actual unescaped command substitution, outer pipelines/chains and
unvalidated heredocs are rejected. A validated quoted heredoc has an opaque body
and cannot hide another command after its closing delimiter. ANSI-C/localized
shell quoting is outside this deliberately small parser and remains rejected.

Local checks:

```bash
rtk test env PYTHONDONTWRITEBYTECODE=1 python3 codex/hooks/rtk-required.test.py
```

The current VM uses symlinks from `~/.codex/rtk-required.py` and
`~/.codex/rtk-required.test.py` to these reviewed sources. Existing files are
backed up before replacement. The configured hook command stays at its existing
path; installing this correction does not disable RTK, replace other hooks or
change Codex credentials. This repair does not change the main environment
installer or overwrite an existing user's configuration.
