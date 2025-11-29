#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- 1. PRE-FLIGHT CHECKS ---

echo "--- Mero Terminal Setup ---"

# Detect Architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  ARCH_TYPE="x64" ;;
    aarch64) ARCH_TYPE="arm64" ;;
    *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac
echo "Detected Architecture: $ARCH_TYPE"

# Function to run commands with sudo if not root
run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
            sudo "$@"
        else
            echo "Error: sudo is not installed and you are not root."
            echo "Please install sudo or run as root."
            exit 1
        fi
    fi
}

# Check for essential tools
echo "Checking prerequisites..."
if ! command -v git >/dev/null 2>&1; then
    echo "Git not found. Installing..."
    run_sudo apt-get update && run_sudo apt-get install -y git
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Curl not found. Installing..."
    run_sudo apt-get install -y curl
fi

# Update System
echo "Updating package lists..."
run_sudo apt-get update
run_sudo apt-get install -y build-essential unzip tar gzip python3-venv tmux

# --- 2. TOOLS INSTALLATION ---

# Install specific tools based on logic

# NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# PNPM
if ! command -v pnpm >/dev/null 2>&1; then
    echo "Installing PNPM..."
    curl -fsSL https://get.pnpm.io/install.sh | sh -
fi

# Bun
if [ ! -d "$HOME/.bun" ]; then
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
fi

# Starship
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing Starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

# Zoxide
if ! command -v zoxide >/dev/null 2>&1; then
    echo "Installing Zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# Atuin
if ! command -v atuin >/dev/null 2>&1; then
    echo "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -lsSf https://setup.atuin.sh | sh
fi

# FZF
if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing FZF..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --all
fi

# Bat (Batcat)
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    echo "Installing Bat..."
    run_sudo apt-get install -y bat
    # Alias batcat to bat if needed in local bin
    mkdir -p ~/.local/bin
    ln -sf /usr/bin/batcat ~/.local/bin/bat
fi

# Trash-cli
if ! command -v trash >/dev/null 2>&1; then
    run_sudo apt-get install -y trash-cli
fi

# --- 3. COMPLEX INSTALLS (Eza, Fastfetch, Neovim) ---

# Fastfetch
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Installing Fastfetch..."
    if run_sudo add-apt-repository --yes ppa:zhangsongcui3371/fastfetch; then
        run_sudo apt-get update
        run_sudo apt-get install -y fastfetch
    else
        echo "PPA failed (likely Debian/WSL). Downloading binary..."
        # Fallback logic here if needed, or skip
    fi
fi

# Eza (Universal Method: gpg key)
if ! command -v eza >/dev/null 2>&1; then
    echo "Installing Eza..."
    run_sudo apt-get update
    run_sudo apt-get install -y gpg
    
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | run_sudo tee /etc/apt/sources.list.d/gierens.list
    run_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    run_sudo apt-get update
    run_sudo apt-get install -y eza
fi

# Neovim (Latest Stable)
echo "Installing/Updating Neovim..."
# Detect if we should use AppImage (simpler) or Tarball
# Most modern distros support FUSE, so AppImage is best. If not, Tarball.
NVIM_DIR="/opt/nvim"

if [ "$ARCH_TYPE" == "x64" ]; then
    echo "Downloading Neovim for x64..."
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
    run_sudo rm -rf $NVIM_DIR
    run_sudo tar -C /opt -xzf nvim-linux64.tar.gz
    run_sudo mv /opt/nvim-linux64 $NVIM_DIR
    rm nvim-linux64.tar.gz
else
    # ARM logic (building from source is often safer, but lets try binary)
    # Neovim doesn't always provide official ARM binaries in the main release tag usually.
    # Fallback to apt for ARM if binary not found, or use snap
    echo "ARM Detected. Using APT for Neovim (Warning: might be older) or Snap."
    run_sudo apt-get install -y neovim
fi

# Symlink NVIM
if [ -f "$NVIM_DIR/bin/nvim" ]; then
    run_sudo ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
fi

# LazyVim
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"
fi

# --- 4. SYMLINKING DOTFILES ---

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

echo "Creating backup directory at $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"

link_file() {
    local filename=$1
    local source_path="$DOTFILES_DIR/$filename"
    local dest_path="$HOME/.$filename"

    # Verify source file exists in the repo
    if [ ! -f "$source_path" ]; then
        echo "Warning: Source file '$filename' not found in $DOTFILES_DIR. Skipping."
        return
    fi

    # Backup existing file or symlink if it exists
    if [ -e "$dest_path" ] || [ -L "$dest_path" ]; then
        echo "Backing up existing .$filename..."
        mv "$dest_path" "$BACKUP_DIR/"
    fi

    # Create the symbolic link
    echo "Linking $filename -> .$filename"
    ln -s "$source_path" "$dest_path"
}

# Ensure we are in the right directory
if [ -d "$DOTFILES_DIR" ]; then
    # List of files to symlink (Add exactly the filenames you have in the repo)
    link_file "bashrc"
    link_file "profile"
    link_file "bash-preexec.sh" 
else
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
fi

echo "--- Setup Complete! Restart your terminal. ---"
