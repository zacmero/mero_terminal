# Mero Terminal

This repository contains my personal dotfiles for a portable, universal terminal environment. It is designed to work across **Ubuntu, Debian, Arch Linux, and WSL**, automatically detecting the architecture (x86 or ARM) and distribution to install the correct tools.

## Features

-   **Shell:** Bash with `starship` prompt, `zoxide` navigation, and `atuin` shell history.
-   **Terminal:** WezTerm with a tracked config and best-effort default-terminal handoff.
-   **Editor:** Neovim (Latest Stable) with LazyVim configuration (fully tracked in this repo).
-   **Tools:** `eza` (ls replacement), `bat` (cat replacement), `fzf`, `tmux`, `lazygit`, `trash-cli`, `yazi` (terminal file manager), `croc` (secure file transfer), `mise` (environment manager).
-   **Image Viewers:** `chafa` for terminal image previews over SSH/headless VMs, and dynamically installs `ueberzugpp` on desktop/GUI machines.
-   **Universal:** Single script setup for different Linux distributions and architectures.

---

## Yazi (Terminal File Manager)

Yazi is an advanced, fast terminal file manager. This setup automatically installs `yazi` and its companion `ya` utility.

### Features:
*   **Automatic `cd` on exit:** When you quit `yazi`, your shell's current directory will automatically change to the last directory you were browsing in `yazi`.
*   **Neovim-first editing:** `nvim` is exported as the default `EDITOR`/`VISUAL`, and pressing `Enter` on text/code files in `yazi` opens them in Neovim.
*   **Rich previews:** `yazi` includes support for image previews, video thumbnails, archive contents, and more, provided you have the necessary optional dependencies installed (which the `install.sh` script handles automatically).
*   **File operations:** Easily copy, move, delete, and manage files.
*   **On-demand Metadata:** Press `Ctrl+i` to instantly show file size and modification time next to files (custom linemode). Press `Shift+i` to hide it.

---

## WezTerm

WezTerm is now the default terminal installed by `mero_terminal`, with its config tracked in this repo under `wezterm/`. The installer now asks at startup whether you want to install it, which is useful on machines where you already use another terminal emulator such as Termius.

### Features:
*   **Repo-managed config:** The installer symlinks `wezterm/` into `~/.config/wezterm`.
*   **Default-terminal handoff:** The installer sets `TERMINAL=wezterm`, registers a desktop entry, and configures XFCE helper integration so new sessions prefer WezTerm.
*   **XFCE shortcut repair:** On XFCE systems with an existing shortcut config, `Ctrl+Alt+T` is rewritten to launch WezTerm directly instead of relying on the previous terminal helper path.
*   **Cross-distro install path:** Arch uses the native package, while Debian/Ubuntu falls back to an official WezTerm release if needed.
*   **Pane shortcuts:** `Ctrl+Shift+/` splits horizontally and `Ctrl+Shift+-` splits vertically.
*   **Lean surface:** The internal tab bar is disabled so the terminal stays visually minimal and relies on the window manager and shell context instead.
*   **Theme font:** WezTerm uses `CaskaydiaCove Nerd Font Mono` to stay aligned with the rest of this setup.

---

## Croc (File Transfer)

Croc is a tool that allows any two computers to simply and securely transfer files and folders without port-forwarding or setting up a server.

### Features:
*   **Simple Sending:** Run `croc send <file>` to generate a random code.
*   **Simple Receiving:** On the receiving computer, run `croc <code>` to download the file.
*   **Secure & Fast:** Uses relay servers but encrypts end-to-end using PAKE (Password-Authenticated Key Exchange).

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
*   **Yanking:** `tmux-yank` is set up with vi-mode keybindings.
*   **Auto-Save & Restore:** Uses `tmux-resurrect` and `tmux-continuum` to continuously auto-save your environment every 15 minutes and automatically restore it on startup.
*   **Plugins:** TPM is installed automatically, and the repo installer now installs the declared tmux plugins for you as part of setup.

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
*   **Installs Dependencies:** Automates the installation of `curl`, `git`, build tools, and related packages using the correct package manager for the host (`pacman` on Arch, `apt` on Debian/Ubuntu).
*   **Installs Tools:** Sets up WezTerm when selected at startup, plus Starship, Zoxide, Atuin (history), Eza, Neovim, LazyGit, Yazi, Chafa, and Ueberzugpp (conditionally if GUI is detected).
*   **Configures Environment:** Sets up useful aliases (like replacing `ls` with `eza`, `cat` with `bat`, and `rm` with `trash-cli`) to improve your workflow.
*   **Backups & Symlinks:** Automatically backs up and relinks managed shell files and config directories, including `.bashrc`, `.profile`, `.tmux.conf`, `~/.config/nvim`, `~/.config/yazi`, `~/.config/starship.toml`, and `~/.config/atuin/config.toml`. When WezTerm is enabled, it also manages `~/.config/wezterm`.
*   **Repo Path Awareness:** Uses the directory containing `install.sh` as the source of truth, so the script can migrate configs correctly even if the repo was moved from the old `~/dotfiles` path.

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
    For icons to appear correctly in the prompt (`starship`) and file listing (`eza`), you must install a **Nerd Font** on your host machine (the computer you are viewing the terminal from, e.g., Windows, macOS). The `install.sh` script automatically downloads **Cascadia Code Nerd Font** on Linux systems, but you should install it on your local client as well.
    
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

Commands prefixed with a leading space are intentionally excluded from shell history, and the tracked Atuin config also filters those commands so they are not recorded there either.
