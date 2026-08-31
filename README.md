# Mero Terminal

This repository contains my personal dotfiles for a portable, universal terminal environment. It is designed to work across **Ubuntu, Debian, Arch Linux, and WSL**, automatically detecting the architecture (x86 or ARM) and distribution to install the correct tools.

## Features

-   **Shell:** Bash with a tracked `oh-my-posh` lean rainbow prompt, `zoxide` navigation, and `atuin` shell history. The prompt is shell-level, so it applies in any Bash session, not just WezTerm.
-   **Terminal:** WezTerm with a tracked config and best-effort default-terminal handoff.
-   **Editor:** Neovim nightly (0.12+) with LazyVim configuration (fully tracked in this repo).
-   **Tools:** `eza` (ls replacement), `bat` (cat replacement), `fzf`, `tmux`, `lazygit`, `lazydocker`, `trash-cli`, `yazi` and `superfile` (`spf`) as independent terminal file managers, `croc` (secure file transfer), `mise` (environment manager), `aichat` (LLM CLI), `fabric` (AI prompt/pattern toolkit), `rtk` (Rust token killer CLI proxy), `antigravity` (agent configs, MCPs, skills, and plugins), and `merodoc-preview` (lightweight Word document preview helper).
-   **Media Viewers:** `chafa` for universal terminal previews, `ueberzugpp` on desktop/GUI machines, Yazi's native video thumbnails, and Neovim media rendering through `image.nvim` with a `chafa` fallback when the terminal cannot do richer graphics.
-   **Universal:** Single script setup for different Linux distributions and architectures.

## Bash Readline Vi Mode

Bash keeps the normal emacs/readline editing mode by default, but includes a tracked vi-mode toggle for fast command-line editing when you want it.

### Behavior:
*   **Default mode:** Bash starts in standard `emacs` mode.
*   **Vi toggle:** `F8` toggles the current shell session between `vi` and `emacs`, and in WezTerm it also injects an automatic `Enter` so the prompt redraws cleanly on a fresh line. In vi mode, `Esc` switches between insert and command mode inside the command line.
*   **Prompt indicator:** When vi mode is active, the prompt bar shows a single green `` icon beside the project language badges.
*   **WezTerm-safe:** WezTerm maps `F8` to a stable shell control sequence, and Bash also keeps the standard terminal F8 escape as a fallback.
*   **Line editor bridge:** In vi command mode, `v` opens the current prompt buffer in `$VISUAL`/`$EDITOR` and writes the edited text back into the command line when you quit the editor. It does not auto-execute the result, so `:wq` returns you to the prompt with the updated command ready.
*   **Readline boundary:** Bash readline vi mode still does not implement true Vim visual selection inside the prompt. The supported high-level path is `Esc`, then `v`, edit in Neovim, then `:wq` back to the prompt buffer.
*   **Portable:** The behavior is tracked in `bashrc`, so fresh installs get it automatically.

### Mero Vim Mode Workflow:
*   **Enter Mero vi mode:** Press `F8`. The prompt redraws on a new line and the green `` marker confirms vi mode is active.
*   **Switch to command mode:** Press `Esc` while editing the current command line.
*   **Open the current line in Neovim:** Press `v` from vi command mode.
*   **Return the edited line to the prompt:** Quit Neovim with `:wq`. The edited command comes back into the shell buffer and waits there for you to run or keep editing.
*   **Leave Mero vi mode:** Press `F8` again to go back to the normal emacs/readline mode.

---

## Yazi (Terminal File Manager)

Yazi is an advanced, fast terminal file manager. This setup automatically installs `yazi` and its companion `ya` utility.

### Features:
*   **Automatic `cd` on exit:** When you quit `yazi`, your shell's current directory will automatically change to the last directory you were browsing in `yazi`.
*   **Predictable `Ctrl+C` exit:** Closing `yazi` with `Ctrl+C` leaves the shell in the directory where Yazi was closed.
*   **Neovim-first editing:** `nvim` is exported as the default `EDITOR`/`VISUAL`, and pressing `Enter` on text/code files in `yazi` opens them in Neovim. DOCX files can route through the same Neovim path as lightweight previews, and legacy `.doc` files fall back to LibreOffice/soffice when it is installed. You can also call `:MeroDoc` directly inside Neovim to reopen a Word file as a preview.
*   **Git status in Yazi:** The official `git.yazi` plugin is installed and shows per-file Git state directly in the file list inside Git repositories.
*   **Selection-friendly mode:** Use `yazi-select` when you want the same file manager view but need to mouse-select/copy text from the terminal instead of letting Yazi capture mouse events.
*   **Opt-in launcher:** `yazi-select` is separate from the normal `yazi` command, so you can keep the regular mouse behavior unless you explicitly want terminal selection.
*   **IDE mode for Neovim:** Run `ide` (or `nvide`) inside any project folder to open the tracked `MeroIde` layout: one Neo-tree sidebar on the left and one real editor buffer in the center. It resumes a recent project file when possible, otherwise falls back to a smart starter file such as `README.md`, `main.*`, `index.*`, `app.*`, or `init.*`, then to the first tracked Git file. Snacks Explorer and netrw are disabled so Neo-tree remains the only explorer path.
*   **Rich previews:** `yazi` includes native image previews, video thumbnails, archive contents, and more, provided the necessary optional dependencies are installed (which `install.sh` handles automatically).
*   **Neovim media:** Image files, Markdown image links, and common video files can render inside Neovim through `3rd/image.nvim` when the terminal supports richer graphics. Videos are previewed by extracting a representative frame and then rendering it through the same backend. If the backend is unavailable, Neovim falls back to `chafa` text rendering automatically. `MERO_IMAGE_BACKEND=chafa|kitty|sixel|ueberzug` can force a backend when you want to test a specific path.
*   **File operations:** Easily copy, move, delete, and manage files.
*   **On-demand Metadata:** Press `Ctrl+i` to instantly show file size and modification time next to files (custom linemode). Press `Shift+i` to hide it.
*   **Post-exit listing:** After `yazi` exits, the shell runs your normal `ls` alias in the resulting directory.
*   **Zoxide jumper:** Press `g`, then `z` inside Yazi to open its native zoxide directory picker. This changes Yazi's active directory directly and works in local terminals, tmux, and SSH sessions. Uppercase `Z` remains Yazi's native shortcut for the same picker; lowercase `z` opens Yazi's fzf file/directory jumper.
*   **Full border:** The official `full-border.yazi` plugin adds a rounded border around the complete file-manager layout. It is pinned in `yazi/package.toml` and installed automatically with the other Yazi packages.

## systemctl-tui (Systemd Manager)

`systemctl-tui` is a lightweight TUI for browsing systemd units and logs, and starting, stopping, or editing services and timers. Run:

```bash
systemctl-tui
```

The installer uses Arch's official package on Arch Linux and the official static release on Debian/Ubuntu for both x86_64 and ARM64.

## Herdr (Agent Multiplexer)

Herdr is installed from the official stable Linux release for x86_64 and ARM64. Its tracked configuration lives in `herdr/config.toml` and is linked to `~/.config/herdr/config.toml`.

The Mero Terminal keymap uses `Ctrl+Space`, then `d` to detach, matching tmux. Multiplexer actions add `Ctrl+Alt+Shift`: `t` creates a tab, `/` splits vertically, `-` splits horizontally, and the arrow keys move pane focus. Tmux uses `PageUp`/`PageDown` for previous/next tab; Herdr uses the equivalent mnemonic `p`/`n` because its config parser does not expose PageUp/PageDown names. The installer also installs Herdr's Codex and Pi integrations when those harness directories exist, and installs the official global Herdr agent skill through `npx skills` or a direct raw-file fallback on lean machines.

Herdr's generated hooks and extensions remain in the owning harness directories (`~/.codex` and `~/.pi`); they are app-managed runtime integration files, not secrets or repository configuration.

---

## Superfile (Lean File Manager)

Superfile is installed alongside Yazi and does not replace it. Use `sf` (alias for the official `spf` command) for a lean, fast, modern file-management TUI; keep Yazi for legacy machines, previews, and more complex filing automation. Superfile is installed from Arch's native `superfile` package or from its official Linux release archive on Debian/Ubuntu.

Superfile's tracked configuration lives in `superfile/config.toml` and `superfile/hotkeys.toml`; the installer symlinks them to `~/.config/superfile/`. Its navigation remains Vim-like, but file actions use deliberate `y`, `p`, `X`, `Delete`, and `Shift+Delete` bindings instead of ambiguous Ctrl shortcuts. `M` changes panel mode, `e` opens the selected file in Neovim, and `G` opens the current directory in Neovim. `Esc` or `q` saves the active directory and exits; `Esc` only cancels while a text prompt is open. `Q` exits without changing the shell directory. `sf` reads Superfile's native saved-directory state after exit, so it does not wrap the TUI or print an exit path. `spf` and `sf` select Superfile's portable ANSI image renderer in WezTerm because WezTerm does not yet support the Kitty Unicode-placeholder method used by Superfile. This avoids the broken placeholder preview and works without a GPU; use Yazi when you want its higher-fidelity native image preview. The app owns its keys while focused, so Bash Vim mode, tmux, and Hyprland bindings are not modified.

---

## WezTerm

WezTerm is now the default terminal installed by `mero_terminal`, with its config tracked in this repo under `wezterm/`. The installer now asks at startup whether you want to install it, which is useful on machines where you already use another terminal emulator such as Termius.

### Features:
*   **Repo-managed config:** The installer symlinks `wezterm/` into `~/.config/wezterm`.
*   **Default-terminal handoff:** The installer sets `TERMINAL=wezterm`, registers a desktop entry, and configures XFCE helper integration so new sessions prefer WezTerm.
*   **XFCE shortcut repair:** On XFCE systems with an existing shortcut config, `Ctrl+Alt+T` is rewritten to launch WezTerm directly instead of relying on the previous terminal helper path.
*   **Channel-aware install path:** `MERO_WEZTERM_CHANNEL=auto|stable|nightly` controls how WezTerm is installed. On Arch, `auto` prefers `wezterm-nightly-bin` when `yay`/`paru` is available and falls back to the native package otherwise. Debian/Ubuntu still falls back to an official WezTerm release if needed.
*   **Pane shortcuts:** `Ctrl+Shift+/` splits horizontally and `Ctrl+Shift+-` splits vertically.
*   **Fast close confirm:** `Alt+w` arms a short close-confirm mode, and pressing `w` again closes the current tab without invoking WezTerm's slower built-in confirmation overlay.
*   **Lean tab locator:** WezTerm keeps its normal tab labels hidden and instead renders a compact bottom-right Roman numeral tracker. It only appears when there is more than one tab, highlights the active tab in cyan, and keeps the strip itself transparent so the numbers feel like a floating HUD element instead of a full tab bar.
*   **Slim scroll bar:** WezTerm also shows a very thin, faint cyan scrollbar on the right for long sessions, keeping the indicator subtle while still making deep scrollback easy to orient.
  Adjust `scroll_bar_width` at the top of `wezterm/wezterm.lua` when you need a wider hit area.
*   **Theme font:** WezTerm uses `CaskaydiaCove Nerd Font Mono` with the larger spacing profile already established in this setup.
*   **Mouse bypass:** WezTerm keeps `Shift` as the mouse-reporting bypass modifier, so terminal-side selection and paste can still be forced when terminal apps capture the mouse.
*   **Wheel tuning:** Plain mouse-wheel scroll in shell scrollback is intentionally slower, while `Ctrl + mouse wheel` is the fast-scroll path.
*   **Wayland renderer override:** On Hyprland/Wayland, WezTerm now defaults to `front_end = "OpenGL"` on this setup because it behaved better than the software fallback during artifact testing. Override with `MERO_WEZTERM_FRONTEND=OpenGL`, `WebGpu`, or `Software` if you want to test another renderer.
*   **Smart decorations:** On Hyprland/Wayland, WezTerm uses `window_decorations = "NONE"` so Hyprland owns the frame fully and WezTerm does not draw its own extra top strip/title area. On other systems, WezTerm falls back to normal `RESIZE` decorations.

---

## Croc (File Transfer)

Croc is a tool that allows any two computers to simply and securely transfer files and folders without port-forwarding or setting up a server.

### Features:
*   **Simple Sending:** Run `croc send <file>` to generate a random code.
*   **Simple Receiving:** On the receiving computer, run `croc <code>` to download the file.
*   **Secure & Fast:** Uses relay servers but encrypts end-to-end using PAKE (Password-Authenticated Key Exchange).

---

## AIChat

AIChat is now a default tracked tool in `mero_terminal`. On Arch it installs from the native `extra/aichat` package, and on Debian/Ubuntu the installer falls back to the latest official GitHub release binary.

### Features:
*   **Tracked config:** `aichat/config.yaml` is repo-managed and linked into `~/.config/aichat/config.yaml`.
*   **Tracked roles:** The default `coder` and `suzy-brain` role prompts are tracked under `aichat/roles/` and linked into `~/.config/aichat/roles/`.
*   **OpenRouter default:** The default model is `openrouter:openrouter/free`. This keeps the HUD portable while still letting OpenRouter pick a free routed model for the prompt.
*   **Secret isolation:** The OpenRouter API key is kept outside the repo in `/opt/mero_terminal/aichat.env`, and Bash sources that file at shell startup so AIChat can load it without ever placing the key in git.
*   **Vi-first UX:** AIChat starts with `vi` keybindings and uses the tracked `coder` role as the REPL prelude.
*   **PDF loading:** `pdftotext` is configured as the default PDF document loader for `.file` / `-f`.

### First-time secret setup:

```bash
sudoedit /opt/mero_terminal/aichat.env
```

Set:

```bash
OPENROUTER_API_KEY="your-real-openrouter-api-key"
```

Useful commands:

```bash
aichat
aichat -r coder
aichat -r suzy-brain
aichat --serve
aichat --list-roles
```

---

## Fabric

Fabric is now a default tracked tool in `mero_terminal`.

### Features:
*   **Arch path:** On Arch, the installer prefers the AUR binary package `fabric-ai-bin`.
*   **Debian/Ubuntu fallback:** On Debian/Ubuntu, the installer falls back to the latest official Fabric binary release.
*   **Unified command:** `mero_terminal` ensures `fabric` works even when the package exposes the binary as `fabric-ai`.

---

## RTK (Rust Token Killer)

RTK is a standalone, blazing-fast Rust CLI proxy that filters and condenses terminal and command outputs (such as `git`, `cargo`, `npm`, `pytest`, `ls`, and `docker`) before they reach LLM context windows.

### Features:
*   **Standalone Binary:** Installed to `/usr/local/bin/rtk` and `$HOME/.local/bin/rtk`, independent of any agent harness.
*   **Compact Output Commands:**
    - `rtk ls`: Token-optimized directory listings.
    - `rtk git status` / `rtk git diff`: Ultra-condensed Git outputs.
    - `rtk test`: Runs tests and prints failures only.
    - `rtk err <cmd>`: Executes commands filtering only errors and warnings.
    - `rtk gain`: Displays historical token savings metrics.

---

## Antigravity (Google Antigravity Agent Configuration)

Antigravity (AGY) global configurations are tracked in this repository under `antigravity/` and symlinked into `~/.gemini/config/`. This allows agent rules, MCP server definitions, custom skills, plugins, and hooks to persist seamlessly across machines.

### Features:
*   **Tracked Configs:** `antigravity/config.json`, `antigravity/mcp_config.json`, and `antigravity/hooks.json` are linked to `~/.gemini/config/`.
*   **MCP Servers:** Preconfigured global integrations for **Serena** (semantic code intelligence) and **Morph** (fast apply & WarpGrep).
*   **Toggleable Plugins:** Bundled plugins for **Headroom** (delicate context compression proxy), **Ponytail** (lazy senior dev mode), and **Caveman** (terse communication mode), managed directly in `config.json`.
*   **Custom Skills:** Integrated skills for **Browser Harness** (direct CDP browser automation), Serena, and Morph.
*   **Custom Registries:** `antigravity/skills.json` and `antigravity/plugins.json` allow declaring explicit search paths and inheritance for skills and plugins.
*   **Global Rules:** `antigravity/rules/AGENTS.md` is linked to `~/.gemini/config/rules/` to enforce unified guidelines across all projects and sessions.
*   **Privacy & Local Isolation:** Runtime state, session transcripts, and token stores in `~/.gemini/antigravity-cli/` remain local to the machine and are never tracked in Git.


---

## LazyDocker

LazyDocker is now included by default in `mero_terminal` when the installer can fetch it.

### Features:
*   **Default install:** The installer downloads the latest official release on Arch, Debian, and Ubuntu when `lazydocker` is not already present.
*   **Selection-friendly launcher:** Use `lazydocker-select` when you want to mouse-select/copy text from the terminal while using LazyDocker.
*   **Mouse capture off:** The selection launcher enables `gui.mouseEvents: true` in a temporary config so your terminal emulator can keep normal selection behavior.
*   **Opt-in launcher:** `lazydocker-select` is separate from the normal `lazydocker` command, so menus and log scrolling stay normal unless you explicitly switch into the copy-friendly mode.

---

## Mise-en-place (Environment Manager)

Mise (formerly `rtx`) is a blazing-fast polyglot tool version manager (like `asdf`) and environment variable manager. It is installed automatically and hooked into Bash.

### Features:
*   **Drop-in Replacement:** Replaces `asdf`, `nvm`, `pyenv`, and more in a single tool.
*   **Fast:** Written in Rust, it activates environments significantly faster than traditional shell scripts.
*   **Auto-Activation:** When you enter a directory with a `.mise.toml` or `.tool-versions` file, `mise` automatically activates the required tool versions.

---

## FZF (Fuzzy Finder)

FZF is deeply integrated into this terminal setup, utilizing `ripgrep` for blazing-fast searches that respect `.gitignore` files, and `bat`/`eza` for live syntax and directory previews.

### Shortcuts:
*   **`CTRL-T`**: Search for files in the current directory tree with a live syntax-highlighted preview. Pressing Enter pastes the file path into your command line.
*   **`ALT-C`**: Search for directories with a live tree-view preview. Pressing Enter instantly `cd`s into that directory.
*   **`**<TAB>`**: Fuzzy auto-completion for any command. Type `cd **` or `vim **` and press `<TAB>` to open the fuzzy finder for paths.

---

## Tmux

Tmux is configured for a robust multiplexing experience with plugins managed by TPM.

### Features:
*   **Prefix:** Set to `CTRL+Space` for better ergonomics.
*   **Splits:** Use `prefix + /` for vertical splits and `prefix + -` for horizontal splits.
*   **Theme:** Dracula theme for a clean aesthetic with True Color support.
*   **Navigation:** Seamless `vim-tmux-navigator` integration (use `CTRL+h/j/k/l` to move between Vim splits and Tmux panes).
*   **Index & Mouse:** Windows and panes start at index `1`. Full mouse support enabled.
*   **Yanking:** `tmux-yank` is set up with vi-mode keybindings, and tmux is configured to push copies into the host clipboard through `wl-copy`, `xclip`, or `xsel` when available. Neovim is also configured with `clipboard=unnamedplus`, so yanks inside Neovim sessions running under tmux follow the same system clipboard path by default.
*   **Auto-Save & Restore:** Uses `tmux-resurrect` and `tmux-continuum` to continuously auto-save your environment every 15 minutes and automatically restore it on startup.
*   **Plugins:** TPM is installed automatically, and the repo installer now installs the declared tmux plugins for you as part of setup.

---

## Fastfetch (Dynamic Responsive System Info)

Fastfetch is configured with an intelligent auto-responsive wrapper that scales its layout and OS logo based on your terminal window width, preventing line wrapping or distorted logos on mobile/phone screens.

### Modes & Subcommands:
*   **Auto-Responsive (Default `fastfetch`):**
    - **Mobile / Narrow (`< 62 cols`):** Uses the `tiny` configuration (small logo placed cleanly at the top, essential metrics, zero text wrapping).
    - **Split-Pane / Half-Screen (`62..104 cols`):** Uses the compact configuration with bounded CPU/GPU values and no package-manager probes.
    - **Full Terminal (`>= 105 cols`):** Uses the clean desktop hardware layout. On `mero-machine`, ArchMerOS branding is always enforced instead of auto-detecting EndeavourOS.
*   **`fastfetch complete` (or `fastfetch full` / `fastfetch -f`):** Displays the full, unconstrained spec sheet with complete details regardless of window size.
*   **`fastfetch compact`:** Explicitly forces the compact side-by-side layout.
*   **`fastfetch tiny`:** Explicitly forces the vertical mobile layout.

Automatic startup layouts omit package counts, themes, icons, cursor details, terminal version strings, and secondary disks. This keeps remote/mobile startup fast and prevents long values from wrapping through the logo. Use `fastfetch complete` when you explicitly want those uncensored details. Ubuntu and Debian machines keep native auto-detected branding; the workstation compact/tiny presets explicitly use ArchMerOS branding.

---

## ⚠️ Prerequisites (Read First)

### Setting a Sudo Password (Cloud/VPS Users)

If you are running this on a fresh Cloud VM (AWS, Oracle, DigitalOcean, etc.) where you logged in via SSH keys, **you might not have a password set**. The installation script requires `sudo` privileges to install packages.

1.  **Test if you need a password:**
    Run `sudo ls`. If it lists files without asking for a password, you can skip this step.

2.  **If it asks for a password (and you don't have one):**
    Run this command to define a password for your **current** user:

    ```bash
    sudo passwd $(whoami)
    ```

3.  **If you are `root` and want to create a NEW user:**
    (Only do this if you are logged in strictly as `root` and want a separate standard user)

    ```bash
    # Replace 'username' with your desired name
    useradd -m -s /bin/bash username
    passwd username
    usermod -aG sudo username
    su - username
    ```

---

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/zacmero/mero_terminal.git ~/mero_terminal
    ```

2.  **Run the installation script:**

    ```bash
    cd ~/mero_terminal
    chmod +x install.sh
    ./install.sh
    ```

    Right after startup, the installer will ask:

    ```text
    Install custom terminal (WezTerm)? [Y/n]
    ```

    Answer `n` on VMs or Termius-based hosts if you do not want WezTerm installed or set as the default terminal.

    To force a specific WezTerm channel during install:

    ```bash
    MERO_WEZTERM_CHANNEL=nightly ./install.sh
    ```

    Valid values are:
    - `auto`
    - `stable`
    - `nightly`

### Migrating from the old `~/dotfiles` layout

If a VM still uses the previous `~/dotfiles` repo layout, you do **not** need to manually delete old symlinks first.

```bash
git clone https://github.com/zacmero/mero_terminal.git ~/mero_terminal
cd ~/mero_terminal
./install.sh
```

The installer now detects existing managed files and directories, backs them up to `~/mero_terminal_backup`, and relinks them to the current repo automatically.

### What the script does:
*   **Detects Environment:** Checks if you are on Arch, Debian/Ubuntu, and whether the chip is Intel/AMD (x64) or ARM.
*   **Installs Dependencies:** Automates the installation of `curl`, `git`, build tools, and related packages using the correct package manager for the host (`pacman` on Arch, `apt` on Debian/Ubuntu). The installer only refreshes package databases before installs; it does not run a full system upgrade.
*   **Installs Tools:** Sets up WezTerm when selected at startup, plus Oh My Posh, Zoxide, Atuin (history), Eza, Neovim, LazyGit, Yazi, Superfile, Chafa, Ueberzugpp (conditionally if GUI is detected), AIChat, and Fabric. Re-running the installer refreshes the important CLI tools instead of only filling in missing ones.
*   **Configures Environment:** Sets up useful aliases (like replacing `ls` with `eza`, `cat` with `bat`, and `rm` with `trash-cli`) to improve your workflow.
*   **Backups & Symlinks:** Automatically backs up and relinks managed shell files and config directories, including `.bashrc`, `.profile`, `.tmux.conf`, `~/.config/nvim`, `~/.config/yazi`, the tracked Superfile files under `~/.config/superfile`, `~/.config/lazygit`, `~/.config/oh-my-posh`, `~/.config/starship.toml`, `~/.config/atuin/config.toml`, the tracked AIChat files under `~/.config/aichat`, and the Antigravity configuration files under `~/.gemini/config`. When WezTerm is enabled, it also manages `~/.config/wezterm`.
*   **Plugin bootstrap:** After linking the tracked configs, the installer runs `Lazy! restore` for Neovim so new machines install the pinned plugin versions from `nvim/lazy-lock.json`, then loads `nvim-treesitter` and installs the tracked Treesitter parsers (`vim` and `vimdoc`) so the Vimscript highlighter stays valid. It also runs `ya pkg install` for Yazi so Git status, the rounded full border, and the Catppuccin Mocha flavor are present from the first install; video preview is native in current Yazi. The installer also bootstraps the lightweight `merodoc-preview` helper so the `:MeroDoc` workflow can render Word docs on demand without adding a heavy Neovim plugin stack.
*   **Repo Path Awareness:** Uses the directory containing `install.sh` as the source of truth, so the script can migrate configs correctly even if the repo was moved from the old `~/dotfiles` path.

### Yazi navigation

Yazi uses the same Catppuccin Mocha palette as Superfile. Launch it with `yazi`
or `y`; leaving with `Ctrl+C` returns Bash in the directory where Yazi was
closed. The tracked Bash function is required because a child process cannot
directly change its parent shell's working directory.

### Shell hook maintenance

Atuin command capture depends on `bash-preexec.sh` owning the Bash `DEBUG` trap after prompt integrations have finished editing `PROMPT_COMMAND`. Keep `bash-preexec.sh` and `atuin init bash` at the end of `bashrc`, after tools such as Oh My Posh, zoxide, and mise. The tracked `bash-preexec.sh` is intentionally patched to tolerate prompt integrations that use array-style `PROMPT_COMMAND`; do not replace it with a pristine upstream copy without preserving that compatibility.

---

## Post-Installation

1.  **Restart your terminal** or load the changes immediately:
    ```bash
    source ~/.bashrc
    ```

2.  **Authenticate with GitHub CLI:**
    Run the following command to log in to GitHub CLI for easier repository manipulation:
    ```bash
    gh auth login
    ```

3.  **Install a Nerd Font:**
    For icons to appear correctly in the prompt (`oh-my-posh`) and file listing (`eza`), you must install a **Nerd Font** on your host machine (the computer you are viewing the terminal from, e.g., Windows, macOS). The `install.sh` script automatically downloads **Cascadia Code Nerd Font** on Linux systems, but you should install the matching font on your local client as well.
    
    *   **Recommended:** [Cascadia Code Nerd Font](https://www.nerdfonts.com/font-downloads)
    *   **VS Code / Terminal Users:** Remember to configure your terminal emulator to use the downloaded font.

---

## Updating

To update your dotfiles on any machine to the latest version from the repository:

```bash
cd ~/mero_terminal
git pull origin master
./install.sh
```

The installer uses Neovim nightly so the tracked `nvim-treesitter` stack remains compatible with Neovim 0.12+.

Commands prefixed with a leading space are intentionally excluded from shell history, and the tracked Atuin config also filters those commands so they are not recorded there either.

## Plugin Workflow

Neovim plugin changes are only persistent when they land in the repo. Use this rule:

*   **Edit the repo** when you add a new plugin, change plugin options, or want behavior to survive on other machines.
*   **Use Lazy locally** when you only want to install the already-tracked plugin versions or refresh the local plugin cache.
*   **Commit `nvim/lazy-lock.json`** when the repo already contains the plugin spec and you want to pin the resolved version for all machines.

## IDE Navigation

Inside the tracked LazyVim setup:

*   **Open IDE mode:** `ide` or `nvide` in a folder. This calls the tracked `:MeroIde` command and skips the dashboard for project launches. Plain `nvim` still keeps the normal LazyVim dashboard.
*   **Web IDE mode:** `ide -web` keeps the same Mero IDE layout, but also starts a local live-preview server on the target folder without trying to guess the project type. It prefers an app's own `dev` script when present, otherwise falls back to `live-server` if installed, and finally to a simple `python3 -m http.server` preview. It prints a readiness line plus the log file path at `~/.cache/mero_terminal/web-preview.log` so you can confirm it started cleanly.
*   **Toggle Neo-tree:** `<leader>e`
*   **Reopen the left explorer for the current folder:** `<leader>fi` or `<leader>ii`
*   **Open OpenCode agent:** `<leader>oa`
*   **Preview the selected file:** Neo-tree preview is manual in IDE mode. Use `P` to toggle preview and `Ctrl-f`/`Ctrl-b` to scroll it.
*   **Move between left explorer, center file, and right agent split:** `Ctrl+h`, `Ctrl+j`, `Ctrl+k`, `Ctrl+l`

The same `Ctrl+h/j/k/l` navigation also works when the right-side agent window is in terminal mode.

## Neovim Save Flow

The tracked Neovim setup now includes:

*   **`Ctrl+S`**: Save the current file. If the buffer has no path yet, it falls back to the Save As flow.
*   **`Ctrl+Shift+S`**: Opens a picker-backed Save As flow. First you pick a file or directory, then you get a path prompt with completion for the final target.

These mappings are tuned for terminal Neovim usage in `wezterm`. The shell config also disables XON/XOFF flow control so `Ctrl+S` reaches Neovim instead of freezing the terminal.

## Visual Web Work

The tracked Neovim setup now includes a small front-end and visual-work layer for when you need to inspect or build UI-heavy code without falling back to VS Code:

*   **Colorizer:** Hex/RGB/HSL values are highlighted inline in CSS, HTML, JS/TS, React, Vue, Svelte, and Astro buffers.
*   **Color picker:** `ccc.nvim` provides a floating color picker and converters for hex, RGB, and HSL.
*   **Auto tags:** HTML-like buffers auto-close and auto-rename paired tags.
*   **Markdown and LaTeX rendering:** `render-markdown.nvim` renders Markdown tables, common syntax, and LaTeX math blocks in a cleaner, terminal-friendly view. The installer pins the `latex` Treesitter parser and installs `pylatexenc` for formula conversion.
*   **Web LSPs:** `cssls`, `html`, `tailwindcss`, `emmet_language_server`, and `tsserver` are enabled through the tracked LazyVim layer.

Useful keys:

*   `<leader>cp`: open the color picker
*   `<leader>ch`: toggle live color highlighting
*   `<leader>cc`: convert the current color under the cursor

## Neovim IDE Flow

- `ide`: open Neovim on the current directory with Neo-tree on the left
- `nvide`: alias for `ide`
- `<leader>e`: toggle Neo-tree on the current working directory
- `<leader>ge`: open Neo-tree Git status source
- `<leader>fi`: reopen the current working directory in the left explorer
- `<leader>oa`: open the `opencode.nvim` UI

## Yazi Git Status

- official plugin: `git.yazi`
- package lock: `yazi/package.toml`
- config files: `yazi/init.lua` and `yazi/yazi.toml`

## Git Workflow

- `<leader>ge`: open Neo-tree Git status source
- `<leader>gn`: open Neogit in a split, similar to a source-control panel
- `<leader>gd`: open Diffview for repository diff review
- `<leader>gD`: close Diffview

## Git Visuals

- Neo-tree file rows show explicit Git state symbols
- Neo-tree folder rows do not behave like VS Code's richer mixed-state aggregate badges; use `<leader>ge` when you want the fuller repo change view
- editor buffers now use stronger `gitsigns.nvim` markers with signcolumn + number highlights for faster change scanning

## Minimap

- the IDE now has a right-side minimap powered by `mini.map`
- it highlights Git changes, diagnostics, and current search matches
- it opens automatically for normal editing buffers
- it stays out of Neo-tree, Trouble, terminals, and other utility panes

Commands:

- `<leader>mm`: toggle the minimap
- `<leader>mM`: close the minimap
- `<leader>mf`: focus the minimap for quick navigation

If you want it off in the current session:

- press `<leader>mm` to toggle it off
- or `<leader>mM` to force-close it

Minimap interaction note:

- `mini.map` does not support mouse-dragging the scrollbar by design
- use `<leader>mf` to focus the minimap instead
- while focused, move to the area you want, then:
- `<CR>` accepts the new position
- `<Esc>` returns to the original position
- `<leader>gh`: open file history in Diffview
- `<leader>gg`: LazyGit remains available from LazyVim when `lazygit` is installed
