"""Offline regression checks for config preservation and failure completion."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def run_bash(self, code, home, **extra):
        env = dict(os.environ, HOME=str(home), MERO_TERMINAL_DIR=str(REPO), **extra)
        return subprocess.run(['bash', '-c', code], env=env, text=True,
                              capture_output=True, timeout=120)

    def test_configs_only_preserves_files_and_repeats(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            (home / '.bashrc').write_text('old shell config')
            (home / '.config/herdr').mkdir(parents=True)
            (home / '.config/herdr/config.toml').write_text('old herdr config')
            command = f'bash "{REPO}/install_lite.sh" --configs-only'
            for _ in range(2):
                result = self.run_bash(command, home)
                self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            backups = list((home / 'mero_terminal_backup').iterdir())
            self.assertEqual(len(backups), 1)
            self.assertEqual((backups[0] / '.bashrc').read_text(), 'old shell config')
            self.assertEqual((backups[0] / '.config/herdr/config.toml').read_text(), 'old herdr config')
            for dest, source in [('.bashrc', 'bashrc'), ('.config/nvim', 'nvim'),
                                 ('.config/wezterm', 'wezterm'), ('.tmux.conf', 'tmux.conf'),
                                 ('.codex/config.toml', 'codex/config.toml')]:
                self.assertEqual((home / dest).resolve(), REPO / source)

    def test_missing_config_does_not_skip_later_links(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            code = f'''source "{REPO}/scripts/link-configs.sh"
link_config /nonexistent "$HOME/.missing" || failed=1
link_config "{REPO}/tmux.conf" "$HOME/.tmux.conf"
exit "${{failed:-0}}"
'''
            result = self.run_bash(code, home)
            self.assertEqual(result.returncode, 1)
            self.assertTrue((home / '.tmux.conf').is_symlink())

    def test_memory_guard_refuses_an_unavailable_budget(self):
        with tempfile.TemporaryDirectory() as root:
            result = self.run_bash(f'source "{REPO}/scripts/resource-check.sh"; require_install_memory 999999999', Path(root))
            self.assertEqual(result.returncode, 1)
            self.assertIn('Insufficient available RAM', result.stderr)

    def test_directory_changes_do_not_print_listings(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            source = (REPO / 'bashrc').read_text()
            override_removal = source.split("# Directory changes use Bash's builtin cd", 1)[1].split("# Alias 'cat'", 1)[0]
            code = 'cd() { builtin cd "$@" && echo unwanted-listing; }\n'
            code += override_removal + '\ncd /tmp\necho directory-changed\n'
            result = self.run_bash(code, home)
            self.assertEqual(result.returncode, 0)
            self.assertEqual(result.stdout.strip(), 'directory-changed')

    def test_lite_tool_failures_reach_final_config_verification(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            source = (REPO / 'install_lite.sh').read_text()
            prefix, suffix = source.split('export MERO_LITE=1 CMAKE_BUILD_PARALLEL_LEVEL=1', 1)
            prefix = '\n'.join(f'REPO="{REPO}"' if line.startswith('REPO=') else line for line in prefix.splitlines()) + '\n'
            overrides = r'''
privileged() { return 0; }
ensure_package() { [[ "$1" != rg ]]; }
install_atuin() { return 0; }
install_posh() { return 0; }
install_fastfetch() { return 0; }
install_croc() { return 0; }
install_nvim() { return 0; }
install_treesitter() { return 0; }
herdr() { return 0; }
nvim() { return 0; }
timeout() { [[ "$*" != *nvim* ]]; }
'''
            code = 'sudo() { return 0; }\n' + prefix + overrides
            code += 'export MERO_LITE=1 CMAKE_BUILD_PARALLEL_LEVEL=1' + suffix
            result = self.run_bash(code, home)
            self.assertEqual(result.returncode, 1, result.stderr + result.stdout)
            failures = next(home.glob('.local/state/mero-terminal/lite-*.failures')).read_text()
            self.assertIn('FAILED: rg', failures)
            self.assertIn('FAILED: LazyVim plugins', failures)
            self.assertIn('Finished with failures', result.stdout)
            self.assertTrue((home / '.config/wezterm').is_symlink())
            self.assertTrue((home / '.tmux.conf').is_symlink())

    def test_full_unhandled_failure_is_logged_and_continues(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            # Run the real full-installer initialization, linker and error handler;
            # stop before system installs, then inject a failed install command.
            prefix = (REPO / 'install.sh').read_text().split('# Check for essential tools')[0]
            code = prefix + '''
false
run_sudo() { echo "$*" >> "$HOME/package-attempts"; [[ "$*" != *unavailable* ]]; }
install_packages unavailable valid
link_all_configs "$MERO_TERMINAL_DIR"
echo reached-final-step
if [ -s "$FAILURE_LOG" ]; then exit 1; fi
'''
            result = self.run_bash(code, home)
            self.assertEqual(result.returncode, 1, result.stderr + result.stdout)
            self.assertIn('reached-final-step', result.stdout)
            attempts = (home / 'package-attempts').read_text()
            self.assertIn('unavailable', attempts)
            self.assertIn('valid', attempts)
            self.assertIn('Command failed', (home / 'failed-installations.txt').read_text())
            self.assertTrue((home / '.bashrc').is_symlink())
            self.assertTrue((home / '.config/wezterm').is_symlink())


if __name__ == '__main__':
    unittest.main()
