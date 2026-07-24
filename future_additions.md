fd --> tool for make "find" better
stow --> tool for managin mero_terminal: https://www.youtube.com/watch?v=y6XCebnB9g
figlet/toilet --> nice text to display
lolcat --> You can pipe anything into this to make it rainbow.
mapscii --> A literal world map made of ASCII characters that you can zoom into.
faker --> create fake data direclty on terminal or to feed applications.
grex --> create regex on demand.
wezterm ricing pass --> add a more intentional visual design, keymaps, and workflow polish after the base install path is stable.
Tmux-Floax --> floating terminal pane over the current one, with persistent memory.

OBS: all of these msut be installed in a portable way0 and described on the README.md after installed.


---

### Issues Fixed (Post-Install Debugging)

1. **tree-sitter CLI version mismatch** (v0.20.8 from Ubuntu apt)
   - Ubuntu/Debian `tree-sitter-cli` package is v0.20.8 which only has `build-wasm`, not `build` subcommand
   - Neovim's nvim-treesitter (main branch) expects `tree-sitter build` for compiling parsers
   - Fix: Install latest tree-sitter (v0.26.11) from GitHub releases to ~/.local/bin
   - Lesson: Don't rely on distro package for tree-sitter CLI; pin to known-working version

2. **image.nvim luarocks/hererocks failures**
   - image.nvim tries to build with luarocks which requires hererocks (Lua 5.1)
   - hererocks often fails on fresh systems due to missing Lua toolchain
   - Fix: Disable rocks in plugin config: `build = false, opts = { rocks = { hererocks = false, enabled = false } }`
   - Lesson: External Lua dependency chains are fragile; prefer pure-Lua or prebuilt alternatives

3. **pi-node hardcoded version path in bashrc**
   - bashrc had `/home/cris/.local/share/pi-node/node-v22.23.1-linux-x64/bin`
   - pi-node updates change the version directory, breaking the PATH
   - Fix: Use symlink `/home/cris/.local/share/pi-node/current/bin` which pi-node manages
   - Lesson: Always use the `current` symlink for versioned tool managers

4. **Cascadia Code Nerd Font not installed**
   - wezterm config uses `CaskaydiaCove Nerd Font Mono` but installer didn't download it
   - Fix: Add font download to install.sh (already present but wasn't running)
   - Lesson: Font installation should be verified, not assumed

5. **Duplicate PATH entries in bashrc**
   - PNPM_HOME, BUN_INSTALL, LOCAL_BIN added multiple times
   - Fix: Consolidate to single declarations
   - Lesson: Audit bashrc for idempotency on re-source

6. **lazygit config missing from repo**
   - install.sh symlinks ~/.config/lazygit but repo had empty lazygit/ dir
   - Fix: Add tracked config.yml matching wezterm/oh-my-posh theme
   - Lesson: All symlinked configs must have source files in repo