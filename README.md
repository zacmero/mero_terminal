# Mero Terminal

This repository contains my personal dotfiles for a portable, universal terminal environment. It is designed to work across **Ubuntu, Debian, Arch Linux, and WSL**, automatically detecting the architecture (x86 or ARM) and distribution to install the correct tools.

## Features

-   **Shell:** Bash with `starship` prompt, `zoxide` navigation, and `atuin` shell history.
-   **Editor:** Neovim (Latest Stable) with LazyVim configuration.
-   **Tools:** `eza` (ls replacement), `bat` (cat replacement), `fzf`, `lazygit`, `trash-cli`, `yazi` (terminal file manager).
-   **Image Viewers:** `chafa` and `ueberzugpp` for robust terminal image previews.
-   **Universal:** Single script setup for different Linux distributions and architectures.

---

## Yazi (Terminal File Manager)

Yazi is an advanced, fast terminal file manager. This setup automatically installs `yazi` and its companion `ya` utility.

### Features:
*   **Automatic `cd` on exit:** When you quit `yazi`, your shell's current directory will automatically change to the last directory you were browsing in `yazi`.
*   **Rich previews:** `yazi` includes support for image previews, video thumbnails, archive contents, and more, provided you have the necessary optional dependencies installed (which the `install.sh` script handles automatically).
*   **File operations:** Easily copy, move, delete, and manage files.

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
    git clone https://github.com/zacmero/mero_terminal.git ~/dotfiles
    ```

2.  **Run the installation script:**

    ```bash
    cd ~/dotfiles
    chmod +x install.sh
    ./install.sh
    ```

### What the script does:
*   **Detects Environment:** Checks if you are on Arch, Debian/Ubuntu, and whether the chip is Intel/AMD (x64) or ARM.
*   **Installs Dependencies:** Automates the installation of `curl`, `git`, build tools, etc.
*   **Installs Tools:** Sets up Starship, Zoxide, Atuin (history), Eza, Neovim, LazyGit, Yazi, Chafa, and Ueberzugpp (fetching the latest binaries compatible with your system where applicable).
*   **Configures Environment:** Sets up useful aliases (like replacing `ls` with `eza`, `cat` with `bat`, and `rm` with `trash-cli`) to improve your workflow.
*   **Backups & Symlinks:** Automatically backs up your existing `.bashrc` and `.profile` to `~/dotfiles_backup` and links the new ones.

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
    For icons to appear correctly in the prompt (`starship`) and file listing (`eza`), you must install a **Nerd Font** on your host machine (the computer you are viewing the terminal from, e.g., Windows, macOS).
    
    *   **Recommended:** [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)
    *   **VS Code / Terminal Users:** Remember to configure your terminal emulator to use the downloaded font.

---

## Updating

To update your dotfiles on any machine to the latest version from the repository:

```bash
cd ~/dotfiles
git pull origin master
./install.sh
