"""Offline regression check for the private Threads preservation workflow."""
import json
import os
from pathlib import Path
import stat
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "bin/mero-threads-inventory"


class ThreadsInventoryTests(unittest.TestCase):
    def test_counts_and_private_backup(self):
        with tempfile.TemporaryDirectory() as directory:
            home = Path(directory)

            def put(relative, contents):
                path = home / relative
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(contents)
                return path

            gemini = Path(".gemini/tmp/historic-project")
            old_chat = put(gemini / "chats/session-old.json", "synthetic archive text")
            put(gemini / "chats/session-new.jsonl", "synthetic journal text")
            put(gemini / ".project_root", "/workspace/synthetic")
            put(".gemini/projects.json", "{}")
            credentials = put(".gemini/oauth_creds.json", "synthetic credential")
            old_chat.with_name("session-symlink.json").symlink_to(credentials)
            put("codex-home/archived_sessions/rollout-compressed.jsonl.zst", "fixture")
            put(".pi/agent/settings.json", json.dumps({"sessionDir": str(home / "pi sessions")}))
            put("pi sessions/fixture.jsonl", "fixture")
            agy = Path("custom-agy/session/.system_generated/logs")
            put(agy / "transcript.jsonl", "synthetic Antigravity text")
            put(agy / "transcript_full.jsonl", "synthetic tool output")
            put(agy / "chunks/transcript/00000000.jsonl", "same transcript")

            destination = home / "private archive"
            env = {"HOME": str(home), "PATH": os.environ["PATH"], "CODEX_HOME": str(home / "codex-home")}
            command = [SCRIPT, "--antigravity-root", home / "custom-agy"]
            inventory = subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertNotIn("synthetic archive text", inventory.stdout)
            self.assertFalse(destination.exists())
            rows = json.loads(inventory.stdout)["inventory"]
            files = {row["harness"]: row["files"] for row in rows if row["present"]}
            self.assertEqual(files, {"codex-archived": 1, "pi": 1, "gemini": 2, "antigravity": 2})

            backup = subprocess.run([*command, "--backup", destination], env=env, check=True,
                                    capture_output=True, text=True)
            self.assertNotIn("synthetic credential", backup.stdout)
            manifest = json.loads((destination / "manifest.json").read_text())
            self.assertEqual(manifest, json.loads(backup.stdout))
            archived = {path.name for path in destination.rglob("*") if path.is_file()}
            self.assertEqual(archived, {"session-old.json", "session-new.jsonl", ".project_root",
                                       "projects.json", "transcript.jsonl", "manifest.json"})
            saved_chat = next(destination.rglob("session-old.json"))
            self.assertEqual(saved_chat.read_bytes(), old_chat.read_bytes())
            self.assertEqual(saved_chat.stat().st_mtime_ns, old_chat.stat().st_mtime_ns)
            for path in [destination, *destination.rglob("*")]:
                self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o700 if path.is_dir() else 0o600)

            repeat = subprocess.run([*command, "--backup", destination], env=env, capture_output=True, text=True)
            self.assertEqual(repeat.returncode, 1)
            self.assertIn("File exists", json.loads(repeat.stdout)["errors"][0])
            self.assertEqual(saved_chat.read_bytes(), old_chat.read_bytes())

            full_destination = home / "full archive"
            subprocess.run([*command, "--backup", full_destination, "--include-antigravity-full"],
                           env=env, check=True, capture_output=True)
            self.assertEqual(len(list(full_destination.rglob("transcript_full.jsonl"))), 1)


if __name__ == "__main__":
    unittest.main()
