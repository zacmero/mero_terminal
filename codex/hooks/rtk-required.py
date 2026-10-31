#!/usr/bin/env python3
"""Codex operator output policy. This is not a shell security boundary."""
import json
import re
import shlex
import subprocess
import sys
from pathlib import Path

RTK = str(Path.home() / ".local/bin/rtk")


def deny():
    return {"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": (
            "RTK is mandatory. Use an RTK command, or explicitly use rtk proxy "
            "when exact unfiltered output is necessary. Wrap complete pipelines "
            "with rtk summary --shell bash; do not append raw shell commands."
        ),
    }}


def shell_tokens(command, comments=False):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";&|()<>\n")
    lexer.whitespace = " \t\r"
    # Keep newlines after comments visible to the single-command check.
    lexer.commenters = "#" if comments else ""
    return list(lexer)


def no_outer_shell_syntax(command):
    # shlex removes quotes: inspect the original text so quoted code stays data.
    quote = None
    i = 0
    while i < len(command):
        char = command[i]
        if quote == "'":
            if char == "'":
                quote = None
            i += 1
            continue
        if char == "\\":
            if i + 1 == len(command):
                return False
            if quote is None or command[i + 1] in '$`"\\\n':
                i += 2
                continue
        if quote == '"' and char == '"':
            quote = None
        elif quote is None and char in ("'", '"'):
            quote = char
        elif char == "`" or command.startswith("$(", i):
            return False
        elif quote is None and (
            char in ";&|()\n" or command.startswith("<<", i)
            or command.startswith("$'", i) or command.startswith('$"', i)
        ):
            return False
        i += 1
    return quote is None


def wrapped(command):
    header, newline, body = command.partition("\n")
    heredoc = re.fullmatch(r"(.*\S)[ \t]+<<[ \t]*'([A-Za-z_][A-Za-z0-9_]*)'[ \t]*", header)
    if heredoc:
        # This restricted quoted form has an opaque body, not more shell syntax.
        # Require its exact terminator and reject every subsequent command.
        if not newline:
            return False
        command, delimiter = heredoc.groups()
        lines = body.split("\n")
        try:
            end = lines.index(delimiter)
        except ValueError:
            return False
        if "\n".join(lines[end + 1:]).strip(" \t\n"):
            return False
    tokens = shell_tokens(command)
    if len(tokens) < 2 or tokens[0] not in ("rtk", RTK):
        return False
    if heredoc and (tokens[1] != "proxy" or shell_tokens(header, comments=True)[-2:] != ["<<", delimiter]):
        return False
    return no_outer_shell_syntax(command)


def process(payload):
    if payload.get("hook_event_name") != "PreToolUse" or payload.get("tool_name") not in (
        "Bash", "bash", "exec_command", "functions.exec_command",
    ):
        return {}
    value = payload.get("tool_input", {})
    command = value.get("command", value.get("cmd")) if isinstance(value, dict) else None
    if not isinstance(command, str) or not command.strip():
        return deny()
    try:
        if wrapped(command):
            return {}
        # Native RTK keeps its own command/permission attestation before a rewrite.
        normalized = {**payload, "tool_name": "Bash", "tool_input": {**value, "command": command}}
        result = subprocess.run(
            [RTK, "hook", "codex"], input=json.dumps(normalized),
            text=True, capture_output=True, timeout=5, check=True,
        )
        output = json.loads(result.stdout) if result.stdout.strip() else {}
        decision = output.get("hookSpecificOutput", {})
        rewritten = decision.get("updatedInput", {}).get("command")
        if decision.get("permissionDecision") == "allow" and isinstance(rewritten, str) and wrapped(rewritten):
            return output
    except (ValueError, OSError, subprocess.SubprocessError):
        pass
    return deny()


if __name__ == "__main__":
    try:
        response = process(json.load(sys.stdin))
    except (ValueError, TypeError, AttributeError):
        response = deny()
    print(json.dumps(response))
