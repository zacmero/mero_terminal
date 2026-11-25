"""Offline regression checks for config preservation and failure completion."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def run_bash(self, code, home, **extra):
        env = dict(os.environ, HOME=str(home), MERO_TERMINAL_DIR=str(REPO))
        for name in ('XDG_CONFIG_HOME', 'ATUIN_CONFIG_DIR', 'ATUIN_HOME'):
            env.pop(name, None)
        env.update(extra)
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
                                 ('.codex/config.toml', 'codex/config.toml'),
                                 ('.atuin/config.toml', 'atuin/config.toml'),
                                 ('.config/mero/pi-atuin-mcp.mjs', 'pi/atuin-mcp.mjs')]:
                self.assertEqual((home / dest).resolve(), REPO / source)

    def test_configs_only_keeps_custom_atuin_settings(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            config_dir = home / 'config elsewhere'
            config_dir.mkdir()
            config = config_dir / 'config.toml'
            original = 'data_dir = "/mnt/atuin"\nsecrets_filter = true\n'
            config.write_text(original)
            result = self.run_bash(f'bash "{REPO}/install_lite.sh" --configs-only', home,
                                   ATUIN_CONFIG_DIR=str(config_dir))
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            self.assertFalse(config.is_symlink())
            self.assertEqual(config.read_text(), original)
            self.assertFalse((home / '.atuin/config.toml').exists())

    def test_atuin_config_path_follows_existing_and_custom_locations(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            legacy = home / '.config/atuin/config.toml'
            modern = home / '.atuin/config.toml'
            custom = home / 'custom atuin'
            command = f'source "{REPO}/scripts/link-configs.sh"; atuin_config_path'
            legacy.parent.mkdir(parents=True)
            legacy.touch()
            self.assertEqual(self.run_bash(command, home).stdout.strip(), str(legacy))
            modern.parent.mkdir()
            modern.touch()
            self.assertEqual(self.run_bash(command, home).stdout.strip(), str(modern))
            self.assertEqual(self.run_bash(command, home, ATUIN_HOME=str(custom)).stdout.strip(),
                             str(custom / 'config.toml'))

    def mock_atuin(self, home, version):
        binary = home / '.atuin/bin/atuin'
        binary.parent.mkdir(parents=True)
        binary.write_text(f'''#!/bin/sh
case "$*" in
    --version) echo "atuin {version}" ;;
    'threads --help') exit 0 ;;
    *) exit 1 ;;
esac
''')
        binary.chmod(0o755)
        return binary

    def test_standalone_atuin_updater_keeps_compatible_managed_binary(self):
        for version in ['18.25.1', '18.26.0']:
            with self.subTest(version=version), tempfile.TemporaryDirectory() as root:
                home = Path(root)
                binary = self.mock_atuin(home, version)
                code = f'curl() {{ exit 42; }}; export -f curl; bash "{REPO}/install.sh" --update-atuin'
                for _ in range(2):
                    result = self.run_bash(code, home)
                    self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
                    self.assertIn(f'atuin {version}', result.stdout)
                self.assertEqual((home / '.local/bin/atuin').resolve(), binary)

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

    def test_bash_prefers_managed_atuin_after_loading_preexec(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            for directory, output in [(home / '.local/bin', 'managed'), (home / 'system', 'stale')]:
                directory.mkdir(parents=True)
                binary = directory / 'atuin'
                binary.write_text(f'#!/bin/sh\nprintf "echo {output}\\n"\n')
                binary.chmod(0o755)
            (home / '.bash-preexec.sh').write_text('echo preexec\n')
            source = (REPO / 'bashrc').read_text()
            startup = source.split('# >>> Codex installer >>>', 1)[1].split('codexh() {', 1)[0]
            result = self.run_bash('PATH="$HOME/system:$PATH"\n' + startup, home)
            self.assertEqual(result.returncode, 0, result.stderr + result.stdout)
            self.assertEqual(result.stdout.splitlines(), ['preexec', 'managed'])

    def test_lite_tool_failures_reach_final_config_verification(self):
        with tempfile.TemporaryDirectory() as root:
            home = Path(root)
            self.mock_atuin(home, '18.25.1')
            source = (REPO / 'install_lite.sh').read_text()
            prefix, suffix = source.split('export MERO_LITE=1 CMAKE_BUILD_PARALLEL_LEVEL=1', 1)
            prefix = '\n'.join(f'REPO="{REPO}"' if line.startswith('REPO=') else line for line in prefix.splitlines()) + '\n'
            overrides = r'''
privileged() { return 0; }
ensure_package() { [[ "$1" != rg ]]; }
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
