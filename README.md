# Mero Terminal

This repository contains my personal dotfiles for a portable, universal terminal environment. It is designed to work across **Ubuntu, Debian, Arch Linux, and WSL**, automatically detecting the architecture (x86 or ARM) and distribution to install the correct tools.

## Features

-   **Shell:** Bash with `starship` prompt and `zoxide` navigation.
-   **Editor:** Neovim (Latest Stable) with LazyVim configuration.
-   **Tools:** `eza` (ls replacement), `bat` (cat replacement), `fzf`, `lazygit`, `trash-cli`.
-   **Universal:** Single script setup for different Linux distributions and architectures.

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
*   **Installs Tools:** Sets up Starship, Zoxide, Eza, Neovim, LazyGit (fetching the latest binaries compatible with your system).
*   **Backups & Symlinks:** Automatically backs up your existing `.bashrc` and `.profile` to `~/dotfiles_backup` and links the new ones.

---

## Post-Installation

1.  **Restart your terminal** or load the changes immediately:
    ```bash
    source ~/.bashrc
    ```

2.  **Install a Nerd Font:**
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
