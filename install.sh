#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- 1. PRE-FLIGHT CHECKS ---

echo "--- Mero Terminal Setup ---"

# Clear any previous failed installation logs
rm -f "$HOME/failed-installations.txt"
touch "$HOME/failed-installations.txt"

# 1.1 Detect Architecture (x86 vs ARM)
ARCH=$(uname -m)
case $ARCH in
    x86_64)  
        ARCH_TYPE="x64" 
        LAZYGIT_ARCH="x86_64"
        ;;
    aarch64) 
        ARCH_TYPE="arm64" 
        LAZYGIT_ARCH="arm64"
        ;;
    *)       
        echo "Unsupported architecture: $ARCH"
        exit 1 
        ;;
esac
echo "Detected Architecture: $ARCH_TYPE"

# 1.2 Detect Distribution (Ubuntu/Debian vs Arch)
if [ -f /etc/arch-release ]; then
    DISTRO="Arch"
    # Arch commands
    INSTALL_CMD="sudo pacman -S --noconfirm"
    UPDATE_CMD="sudo pacman -Syu"
elif [ -f /etc/debian_version ]; then
    DISTRO="Debian"
    # Ubuntu/Debian commands
    INSTALL_CMD="sudo apt-get install -y"
    UPDATE_CMD="sudo apt-get update"
else
    echo "Unsupported OS. Only Arch and Debian/Ubuntu are supported."
    exit 1
fi

echo "Detected Distribution: $DISTRO"

# --- END OF CHECKS ---

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

# GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    run_sudo apt-get install -y gh
fi

# --- LazyGit Installation (Universal) ---
if ! command -v lazygit >/dev/null 2>&1; then
    echo "Installing LazyGit..."
    
    # Get the latest version tag from GitHub
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    
    # Detect architecture for the download URL
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  LAZYGIT_ARCH="x86_64" ;;
        aarch64) LAZYGIT_ARCH="arm64" ;;
        armv7l)  LAZYGIT_ARCH="armv6" ;; # Raspberry Pi Zero/Old models
        *)       echo "Unsupported architecture for LazyGit: $ARCH"; exit 1 ;;
    esac

    echo "Downloading LazyGit v${LAZYGIT_VERSION} for ${LAZYGIT_ARCH}..."
    
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
    
    echo "LazyGit installed successfully!"
fi

# --- Image Viewers (chafa, ueberzugpp) ---
install_image_viewers() {
    echo "Installing Image Viewers (chafa, ueberzugpp)..."
    case "$DISTRO" in
        "Arch")
            if ! command -v chafa >/dev/null 2>&1 || ! command -v ueberzugpp >/dev/null 2>&1; then
                $INSTALL_CMD chafa ueberzugpp
            fi
            ;;
        "Debian")
            if ! command -v chafa >/dev/null 2>&1; then
                $INSTALL_CMD chafa
            fi
            
            if ! command -v ueberzugpp >/dev/null 2>&1; then
                local UBUNTU_VERSION
                if command -v lsb_release >/dev/null 2>&1; then
                    UBUNTU_VERSION=$(lsb_release -rs)
                else
                    UBUNTU_VERSION="22.04" # Fallback
                fi
                
                local OBS_REPO="xUbuntu_$UBUNTU_VERSION"
                echo "Adding OBS repo for ueberzugpp ($OBS_REPO)..."
                echo "deb http://download.opensuse.org/repositories/home:/justkidding/${OBS_REPO}/ /" | run_sudo tee /etc/apt/sources.list.d/home:justkidding.list
                curl -fsSL "https://download.opensuse.org/repositories/home:justkidding/${OBS_REPO}/Release.key" | gpg --dearmor | run_sudo tee /etc/apt/trusted.gpg.d/home_justkidding.gpg > /dev/null
                
                # We ignore apt update errors here as github cli repo might be broken on user's machine
                run_sudo apt-get update || true
                
                # We also ignore apt install errors here because this mirror is notoriously flaky
                # If it fails, we log it and continue instead of crashing the whole install script
                run_sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ueberzugpp || {
                    echo "WARNING: Failed to install ueberzugpp. The OBS mirror might be down."
                    echo "ueberzugpp (Image Viewer)" >> "$HOME/failed-installations.txt"
                }
            fi
            ;;
    esac
}

install_image_viewers

# --- Yazi Installation ---
install_yazi() {
    echo "Installing Yazi..."
    local YAZI_INSTALL_DIR="/usr/local/bin"
    local TEMP_DIR=$(mktemp -d)
    local YAZI_ARCH_DL="" # Architecture for Yazi download URL

    case "$ARCH" in # Using the previously detected ARCH (uname -m)
        x86_64)
            YAZI_ARCH_DL="x86_64"
            ;;
        aarch64)
            YAZI_ARCH_DL="aarch64"
            ;;
        *)
            echo "Error: Unsupported architecture for Yazi: $ARCH. Skipping Yazi installation."
            rm -rf "$TEMP_DIR"
            return 1
            ;;
    esac

    local github_api_url="https://api.github.com/repos/sxyazi/yazi/releases/latest"
    local release_info=$(curl -s "$github_api_url")
    local YAZI_ZIP_URL=""
    local BUILD_TYPE="gnu"

    if [ -z "$release_info" ]; then
        echo "Error: Could not fetch Yazi release information from GitHub. Skipping Yazi installation."
        rm -rf "$TEMP_DIR"
        return 1
    fi

    YAZI_ZIP_URL=$(echo "$release_info" | grep -oP "https://github.com/sxyazi/yazi/releases/download/v\d+\.\d+\.\d+/yazi-${YAZI_ARCH_DL}-unknown-linux-gnu\.zip")

    if [ -z "$YAZI_ZIP_URL" ]; then
        echo "Warning: No 'gnu' build found for $YAZI_ARCH_DL. Trying 'musl' build."
        BUILD_TYPE="musl"
        YAZI_ZIP_URL=$(echo "$release_info" | grep -oP "https://github.com/sxyazi/yazi/releases/download/v\d+\.\d+\.\d+/yazi-${YAZI_ARCH_DL}-unknown-linux-musl\.zip")
    fi

    if [ -z "$YAZI_ZIP_URL" ]; then
        echo "Error: Could not find a suitable Yazi binary for $YAZI_ARCH_DL. Skipping Yazi installation."
        rm -rf "$TEMP_DIR"
        return 1
    fi

    echo "Downloading Yazi from $YAZI_ZIP_URL..."
    curl -L -o "$TEMP_DIR/yazi.zip" "$YAZI_ZIP_URL"

    echo "Extracting Yazi..."
    unzip -q "$TEMP_DIR/yazi.zip" -d "$TEMP_DIR"
    local EXTRACTED_DIR="$TEMP_DIR/yazi-${YAZI_ARCH_DL}-unknown-linux-${BUILD_TYPE}"

    echo "Moving yazi and ya binaries to $YAZI_INSTALL_DIR..."
    run_sudo mv "$EXTRACTED_DIR/yazi" "$YAZI_INSTALL_DIR/"
    run_sudo mv "$EXTRACTED_DIR/ya" "$YAZI_INSTALL_DIR/"

    echo "Setting permissions for yazi and ya..."
    run_sudo chmod +x "$YAZI_INSTALL_DIR/yazi"
    run_sudo chmod +x "$YAZI_INSTALL_DIR/ya"

    echo "Cleaning up temporary Yazi files..."
    rm -rf "$TEMP_DIR"

    echo "Installing optional Yazi dependencies..."
    case "$DISTRO" in
        "Arch")
            $INSTALL_CMD file ffmpeg p7zip jq poppler fd ripgrep resvg imagemagick xclip
            ;;
        "Debian")
            $INSTALL_CMD file ffmpeg p7zip-full jq poppler-utils fd-find ripgrep resvg imagemagick xclip
            ;;
    esac
    echo "Yazi and its dependencies installed."
}

# Call Yazi installation function
if ! command -v yazi >/dev/null 2>&1; then
    install_yazi
fi




# --- 3. COMPLEX INSTALLS (Eza, Fastfetch, Neovim) ---

# Cascadia Code Nerd Font
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/CaskaydiaCoveNerdFont-Regular.ttf" ]; then
    echo "Installing Cascadia Code Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -fLo "$FONT_DIR/CascadiaCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip
    unzip -qo "$FONT_DIR/CascadiaCode.zip" -d "$FONT_DIR"
    rm "$FONT_DIR/CascadiaCode.zip"
    if command -v fc-cache >/dev/null 2>&1; then
        fc-cache -fv "$FONT_DIR"
    fi
fi

# Fastfetch
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Installing Fastfetch..."
    if run_sudo add-apt-repository --yes ppa:zhangsongcui3371/fastfetch; then
        run_sudo apt-get update
        run_sudo DEBIAN_FRONTEND=noninteractive apt-get install -y fastfetch || {
            echo "WARNING: Failed to install fastfetch."
            echo "fastfetch (System Info)" >> "$HOME/failed-installations.txt"
        }
    else
        echo "PPA failed (likely Debian/WSL). Logging error and continuing..."
        echo "fastfetch (System Info)" >> "$HOME/failed-installations.txt"
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
NVIM_DIR="/opt/nvim"
NVIM_TAR=""

if [ "$ARCH_TYPE" = "x64" ]; then
    NVIM_TAR="nvim-linux-x86_64.tar.gz"
elif [ "$ARCH_TYPE" = "arm64" ]; then
    NVIM_TAR="nvim-linux-arm64.tar.gz"
fi

if [ -n "$NVIM_TAR" ]; then
    echo "Downloading Neovim ($NVIM_TAR)..."
    if curl -fLO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR"; then
        run_sudo rm -rf $NVIM_DIR
        run_sudo tar -C /opt -xzf "$NVIM_TAR"
        run_sudo mv /opt/${NVIM_TAR%.tar.gz} $NVIM_DIR
        rm "$NVIM_TAR"
    else
        echo "WARNING: Failed to download Neovim. Check your internet connection or GitHub status."
        echo "Neovim (Editor)" >> "$HOME/failed-installations.txt"
    fi
else
    echo "ARM or Unknown Detected without binary. Using APT for Neovim (Warning: might be older)."
    run_sudo apt-get install -y neovim
fi

# Symlink NVIM
if [ -f "$NVIM_DIR/bin/nvim" ]; then
    run_sudo ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
fi

# LazyVim (Symlink from dotfiles)
if [ ! -d "$HOME/.config/nvim" ]; then
    echo "Setting up Neovim configuration..."
    ln -s "$HOME/dotfiles/nvim" "$HOME/.config/nvim"
fi

# TMUX Package Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TMUX Package Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Apply a quick patch to tmux-resurrect to hide the annoying "file not found" message on new installs
if [ -f "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" ]; then
    sed -i 's/display_message "Tmux resurrect file not found!"//g' "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
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
    link_file "tmux.conf"
else
    echo "Error: Dotfiles directory not found at $DOTFILES_DIR"
fi

echo "--- Setup Complete! Restart your terminal. ---"

if [ -s "$HOME/failed-installations.txt" ]; then
    echo ""
    echo "⚠️  WARNING: Some non-essential packages failed to install:"
    cat "$HOME/failed-installations.txt"
    echo "Check your network or mirrors and try installing them manually later."
fi
