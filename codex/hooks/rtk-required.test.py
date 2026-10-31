#!/usr/bin/env python3
import importlib.util
from pathlib import Path
from types import SimpleNamespace
import unittest
import shlex
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("rtk_required", Path(__file__).with_name("rtk-required.py"))
hook = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hook)


class RequiredRtkTests(unittest.TestCase):
    def event(self, command, tool="Bash", mode="bypassPermissions"):
        return {"hook_event_name": "PreToolUse", "tool_name": tool,
                "permission_mode": mode, "tool_input": {"command": command}}

    def test_native_git_rewrite(self):
        for command in ("git status --short", "git diff --stat", "git log -3 --oneline"):
            with self.subTest(command=command):
                result = hook.process(self.event(command))["hookSpecificOutput"]
                self.assertEqual(result["permissionDecision"], "allow")
                self.assertTrue(hook.wrapped(result["updatedInput"]["command"]))

    def test_explicit_compressed_commands(self):
        for command in ("rtk git status --short", hook.RTK + " git diff --stat",
                        "rtk git log --format='%s|%an'", "rtk summary --shell bash 'git status; git diff'"):
            with self.subTest(command=command):
                self.assertEqual(hook.process(self.event(command)), {})

    def test_quoted_source_treats_markdown_and_shell_examples_as_literal_data(self):
        for source in (
            'print("`avatar`")',
            'print("$(example)")',
            'print("<tag> | ; && (example)")',
            'text = "a quote: ' + chr(39) + '"\nprint(text)',
            'print("a\\nb")\nprint("`code` and $(shell)")',
        ):
            command = hook.RTK + " proxy python3 -c " + shlex.quote(source)
            with self.subTest(source=source), patch.object(hook.subprocess, "run", return_value=SimpleNamespace(stdout="{}")) as native:
                self.assertEqual(hook.process(self.event(command)), {})
                native.assert_not_called()

    def test_quoted_operator_arguments_are_not_outer_shell_syntax(self):
        for value in (";", "|", "&&", "()", "<<", "\n", "`id`", "$(id)"):
            command = hook.RTK + " proxy printf %s " + shlex.quote(value)
            with self.subTest(value=value), patch.object(hook.subprocess, "run", return_value=SimpleNamespace(stdout="{}")) as native:
                self.assertEqual(hook.process(self.event(command)), {})
                native.assert_not_called()

    def test_escaped_and_double_quoted_literals_stay_literal(self):
        for argument in (
            '"a ; | && (literal)"',
            r'"\$(id)"',
            r'"\`id\`"',
            r'\`id\`',
            '"line one\nline two"',
        ):
            command = hook.RTK + " proxy printf %s " + argument
            with self.subTest(argument=argument), patch.object(hook.subprocess, "run", return_value=SimpleNamespace(stdout="{}")) as native:
                self.assertEqual(hook.process(self.event(command)), {})
                native.assert_not_called()

    def test_quoted_source_cannot_hide_a_real_outer_command(self):
        safe = hook.RTK + " proxy python3 -c " + shlex.quote('print("`example`")')
        commands = [safe + tail for tail in (
            "; printf raw", " && printf raw", " | cat", "\nprintf raw",
            " & printf raw", " $(printf raw)", ' "$(printf raw)"',
            " " + chr(96) + "printf raw" + chr(96),
        )]
        commands += [
            hook.RTK + r' proxy printf %s "\\$(printf raw)"',
            hook.RTK + " proxy printf %s <(printf raw)",
            hook.RTK + " proxy printf %s $'unsupported'",
            hook.RTK + " proxy printf %s 'unterminated",
        ]
        for command in commands:
            with self.subTest(command=command):
                attestation = hook.json.dumps({"hookSpecificOutput": {
                    "permissionDecision": "allow", "updatedInput": {"command": command},
                }})
                with patch.object(hook.subprocess, "run", return_value=SimpleNamespace(stdout=attestation)):
                    result = hook.process(self.event(command))
                self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_explicit_proxy_allows_exact_source_and_heredoc(self):
        command = hook.RTK + " proxy python3 - <<'PY'\nprint('exact')\nPY"
        self.assertEqual(hook.process(self.event(command)), {})

    def test_quoted_heredoc_body_is_opaque_including_escaped_apostrophes(self):
        body = r"""s=p.read_text();old='I couldn\'t finish';new='I can\'t complete'
literal = "$(raw); raw | raw"
"""
        command = hook.RTK + " proxy python3 - <<'PY'\n" + body + "PY\n \t\n"
        with patch.object(hook.subprocess, "run", return_value=SimpleNamespace(stdout="{}")) as native:
            self.assertEqual(hook.process(self.event(command)), {})
            native.assert_not_called()

    def test_proxy_preserves_quoted_benign_semicolons(self):
        command = hook.RTK + " proxy printf '%s;literal' 'another;argument'"
        self.assertEqual(hook.process(self.event(command)), {})
        command += " <<'PY'\nopaque data\nPY"
        self.assertEqual(hook.process(self.event(command)), {})

    def test_heredoc_cannot_hide_following_shell_commands(self):
        prefix = hook.RTK + " proxy python3 - <<'PY'\nprint('exact')\n"
        for suffix in ("PY\nprintf raw", "PY; printf raw", "PY\nPY",
                       "PY\nPY\nprintf raw", "PY\nrtk proxy printf extra",
                       "PY\n\u2003", "PY\n\r"):
            with self.subTest(suffix=suffix):
                with patch.object(hook.subprocess, "run",
                                  return_value=SimpleNamespace(stdout="{}")):
                    result = hook.process(self.event(prefix + suffix))
                self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_proxy_header_chains_and_shell_substitutions_are_denied(self):
        for command in (
            "rtk proxy printf exact; printf raw",
            "rtk proxy rtk git status && printf raw",
            "rtk proxy printf exact\nprintf raw",
            "rtk proxy printf exact # comment\nprintf raw",
            "rtk proxy printf exact;>output printf raw",
            'rtk proxy printf "$(printf raw)"',
            "rtk proxy printf " + chr(96) + "id" + chr(96),
            "rtk proxy python3 -; printf raw <<'PY'\nprint('exact')\nPY",
            "rtk proxy $(printf python3) - <<'PY'\nprint('exact')\nPY",
            "rtk proxy python3 - <<'PY' | cat\nprint('exact')\nPY",
            "rtk proxy printf exact # <<'PY'\nprintf raw\nPY",
            "rtk proxy cat <<'ONE' <<'TWO'\ndata\nONE\ndata\nTWO",
            "rtk proxy cat <<PY\n$(printf raw)\nPY",
            "rtk proxy cat <<'PY'\nunterminated",
        ):
            with self.subTest(command=command):
                with patch.object(hook.subprocess, "run",
                                  return_value=SimpleNamespace(stdout="{}")):
                    result = hook.process(self.event(command))
                self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_native_attestation_cannot_allow_an_unchanged_raw_tail(self):
        command = hook.RTK + " proxy cat <<'PY'\nopaque\nPY\nprintf raw"
        rewritten = hook.json.dumps({"hookSpecificOutput": {
            "permissionDecision": "allow", "updatedInput": {"command": command},
        }})
        with patch.object(hook.subprocess, "run",
                          return_value=SimpleNamespace(stdout=rewritten)):
            result = hook.process(self.event(command))
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_raw_or_compound_bypass_is_denied(self):
        for command in ("python3 -c 'print(1)'", "/tmp/rtk git status", "rtk git status; git diff",
                        "rtk git status\ngit diff", 'rtk git log "$(git diff)"', "", "rtk"):
            with self.subTest(command=command):
                result = hook.process(self.event(command))["hookSpecificOutput"]
                self.assertEqual(result["permissionDecision"], "deny")

    def test_future_permission_mode_never_silently_bypasses(self):
        result = hook.process(self.event("git status", mode="futureMode"))
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")

    def test_other_tools_and_exec_alias(self):
        self.assertEqual(hook.process(self.event("patch", tool="apply_patch")), {})
        self.assertEqual(hook.process({"hook_event_name": "PreToolUse", "tool_name": "exec_command",
                                      "tool_input": {"cmd": "rtk git status"}}), {})


if __name__ == "__main__":
    unittest.main()
