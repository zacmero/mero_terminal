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
    UPDATE_CMD=(pacman -Syu --noconfirm)
elif [ -f /etc/debian_version ]; then
    DISTRO="Debian"
    UPDATE_CMD=(apt-get update)
else
    echo "Unsupported OS. Only Arch and Debian/Ubuntu are supported."
    exit 1
fi

echo "Detected Distribution: $DISTRO"

# --- END OF CHECKS ---

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MERO_TERMINAL_DIR="${MERO_TERMINAL_DIR:-$SCRIPT_DIR}"
BACKUP_DIR="$HOME/mero_terminal_backup/$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR_INITIALIZED=0

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

log_optional_failure() {
    local label=$1
    echo "WARNING: Failed to install or configure $label. Continuing..."
    echo "$label" >> "$HOME/failed-installations.txt"
}

update_system_packages() {
    run_sudo "${UPDATE_CMD[@]}"
}

install_packages() {
    if [ "$#" -eq 0 ]; then
        return
    fi

    case "$DISTRO" in
        "Arch")
            run_sudo pacman -S --noconfirm --needed "$@"
            ;;
        "Debian")
            run_sudo apt-get install -y "$@"
            ;;
    esac
}

install_package_group() {
    local group=$1

    case "$group" in
        base)
            case "$DISTRO" in
                "Arch")
                    install_packages git curl base-devel unzip tar gzip python tmux file
                    ;;
                "Debian")
                    install_packages git curl build-essential unzip tar gzip python3 python3-venv tmux file
                    ;;
            esac
            ;;
        bat)
            case "$DISTRO" in
                "Arch") install_packages bat ;;
                "Debian") install_packages bat ;;
            esac
            ;;
        trash)
            case "$DISTRO" in
                "Arch") install_packages trash-cli ;;
                "Debian") install_packages trash-cli ;;
            esac
            ;;
        github-cli)
            case "$DISTRO" in
                "Arch") install_packages github-cli ;;
                "Debian") install_packages gh ;;
            esac
            ;;
        yazi-optional)
            case "$DISTRO" in
                "Arch")
                    install_packages file ffmpeg p7zip jq poppler fd ripgrep resvg imagemagick xclip
                    ;;
                "Debian")
                    install_packages file ffmpeg p7zip-full jq poppler-utils fd-find ripgrep imagemagick xclip
                    ;;
            esac
            ;;
        fastfetch)
            case "$DISTRO" in
                "Arch")
                    install_packages fastfetch
                    ;;
                "Debian")
                    if run_sudo add-apt-repository --yes ppa:zhangsongcui3371/fastfetch; then
                        update_system_packages
                        run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y fastfetch || {
                            echo "WARNING: Failed to install fastfetch."
                            echo "fastfetch (System Info)" >> "$HOME/failed-installations.txt"
                        }
                    else
                        echo "PPA failed (likely Debian/WSL). Logging error and continuing..."
                        echo "fastfetch (System Info)" >> "$HOME/failed-installations.txt"
                    fi
                    ;;
            esac
            ;;
        eza)
            case "$DISTRO" in
                "Arch")
                    install_packages eza
                    ;;
                "Debian")
                    update_system_packages
                    install_packages gpg
                    run_sudo mkdir -p /etc/apt/keyrings
                    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | run_sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | run_sudo tee /etc/apt/sources.list.d/gierens.list
                    run_sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                    update_system_packages
                    install_packages eza
                    ;;
            esac
            ;;
        *)
            echo "Unknown package group: $group"
            return 1
            ;;
    esac
}

ensure_backup_dir() {
    if [ "$BACKUP_DIR_INITIALIZED" -eq 0 ]; then
        echo "Creating backup directory at $BACKUP_DIR..."
        mkdir -p "$BACKUP_DIR"
        BACKUP_DIR_INITIALIZED=1
    fi
}

link_path() {
    local source_path=$1
    local dest_path=$2
    local label=${3:-$(basename "$dest_path")}
    local desired_target=""
    local current_target=""

    if [ ! -e "$source_path" ] && [ ! -L "$source_path" ]; then
        echo "Warning: Source for $label not found at $source_path. Skipping."
        return
    fi

    mkdir -p "$(dirname "$dest_path")"
    desired_target=$(readlink -f "$source_path" 2>/dev/null || printf '%s' "$source_path")

    if [ -L "$dest_path" ] || [ -e "$dest_path" ]; then
        current_target=$(readlink -f "$dest_path" 2>/dev/null || true)
        if [ -n "$current_target" ] && [ "$current_target" = "$desired_target" ]; then
            echo "$label already linked correctly."
            return
        fi

        ensure_backup_dir
        echo "Backing up existing $label..."
        mv "$dest_path" "$BACKUP_DIR/"
    fi

    echo "Linking $label -> $source_path"
    ln -s "$source_path" "$dest_path"
}

# Function to detect if the machine has a GUI / Desktop Environment installed
has_gui() {
    # Check active display variables
    if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        return 0
    fi
    # Check for installed display managers / sessions
    if [ -d "/usr/share/xsessions" ] && [ "$(ls -A /usr/share/xsessions 2>/dev/null)" ]; then
        return 0
    fi
    if [ -d "/usr/share/wayland-sessions" ] && [ "$(ls -A /usr/share/wayland-sessions 2>/dev/null)" ]; then
        return 0
    fi
    # Check for WSLg (Windows Subsystem for Linux GUI)
    if [ -d "/mnt/wslg" ]; then
        return 0
    fi
    
    return 1
}

# Check for essential tools
echo "Checking prerequisites..."
if ! command -v git >/dev/null 2>&1; then
    echo "Git not found. Installing..."
    update_system_packages
    install_package_group base
fi

if ! command -v curl >/dev/null 2>&1; then
    echo "Curl not found. Installing..."
    install_package_group base
fi

# Update System
echo "Updating package lists..."
update_system_packages
install_package_group base

# --- 2. TOOLS INSTALLATION ---

# Install specific tools based on logic

# Mise-en-place (Environment & Tool Manager)
if [ ! -f "$HOME/.local/bin/mise" ] && ! command -v mise >/dev/null 2>&1; then
    echo "Installing Mise..."
    curl -fsSL https://mise.run | sh || log_optional_failure "Mise"
fi

# NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    mkdir -p "$HOME/.nvm"
    export NVM_DIR="$HOME/.nvm"
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash || log_optional_failure "NVM"
fi

# PNPM
if ! command -v pnpm >/dev/null 2>&1; then
    echo "Installing PNPM..."
    curl -fsSL https://get.pnpm.io/install.sh | sh - || log_optional_failure "PNPM"
fi

# Bun
if [ ! -d "$HOME/.bun" ]; then
    echo "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash || log_optional_failure "Bun"
fi

# Starship
if ! command -v starship >/dev/null 2>&1; then
    echo "Installing Starship..."
    curl -fsSL https://starship.rs/install.sh | sh -s -- -y || log_optional_failure "Starship"
fi

# Zoxide
if ! command -v zoxide >/dev/null 2>&1; then
    echo "Installing Zoxide..."
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log_optional_failure "Zoxide"
fi

# Atuin
if ! command -v atuin >/dev/null 2>&1; then
    echo "Installing Atuin..."
    curl --proto '=https' --tlsv1.2 -lsSf https://setup.atuin.sh | sh || log_optional_failure "Atuin"
fi

# FZF
if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing FZF..."
    if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
        ~/.fzf/install --all || log_optional_failure "FZF"
    else
        log_optional_failure "FZF"
    fi
fi

# Bat (Batcat)
if ! command -v bat >/dev/null 2>&1 && ! command -v batcat >/dev/null 2>&1; then
    echo "Installing Bat..."
    install_package_group bat || log_optional_failure "Bat"
    mkdir -p ~/.local/bin
    if command -v batcat >/dev/null 2>&1; then
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi
fi

# Trash-cli
if ! command -v trash >/dev/null 2>&1; then
    install_package_group trash || log_optional_failure "trash-cli"
fi

# Croc (Universal File Transfer)
if ! command -v croc >/dev/null 2>&1; then
    echo "Installing Croc..."
    curl -fsSL https://getcroc.schollz.com | bash || log_optional_failure "Croc"
fi

# GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    install_package_group github-cli || log_optional_failure "GitHub CLI"
fi

# --- LazyGit Installation (Universal) ---
if ! command -v lazygit >/dev/null 2>&1; then
    echo "Installing LazyGit..."
    
    # Get the latest version tag from GitHub
    LAZYGIT_VERSION=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') || true
    if [ -z "$LAZYGIT_VERSION" ]; then
        log_optional_failure "LazyGit"
    else
    
    # Detect architecture for the download URL
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)  LAZYGIT_ARCH="x86_64" ;;
        aarch64) LAZYGIT_ARCH="arm64" ;;
        armv7l)  LAZYGIT_ARCH="armv6" ;; # Raspberry Pi Zero/Old models
        *)       echo "Unsupported architecture for LazyGit: $ARCH"; exit 1 ;;
    esac

    echo "Downloading LazyGit v${LAZYGIT_VERSION} for ${LAZYGIT_ARCH}..."
    
        if curl -fLo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz" \
            && tar xf lazygit.tar.gz lazygit \
            && run_sudo install lazygit /usr/local/bin; then
            rm lazygit lazygit.tar.gz
            echo "LazyGit installed successfully!"
        else
            rm -f lazygit lazygit.tar.gz
            log_optional_failure "LazyGit"
        fi
    fi
fi

# --- Image Viewers (chafa, ueberzugpp) ---
install_image_viewers() {
    echo "Installing Image Viewer (chafa)..."
    case "$DISTRO" in
        "Arch")
            if ! command -v chafa >/dev/null 2>&1; then
                install_packages chafa
            fi
            ;;
        "Debian")
            if ! command -v chafa >/dev/null 2>&1; then
                install_packages chafa
            fi
            ;;
    esac

    if has_gui; then
        echo "GUI Detected! Attempting to install ueberzugpp (Advanced Image Viewer)..."
        case "$DISTRO" in
            "Arch")
                if ! command -v ueberzugpp >/dev/null 2>&1; then
                    install_packages ueberzugpp || {
                        echo "WARNING: Failed to install ueberzugpp."
                        echo "ueberzugpp (GUI Image Viewer)" >> "$HOME/failed-installations.txt"
                    }
                fi
                ;;
            "Debian")
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
                    update_system_packages || true
                    
                    # We also ignore apt install errors here because this mirror is notoriously flaky
                    # If it fails, we log it and continue instead of crashing the whole install script
                    run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y ueberzugpp || {
                        echo "WARNING: Failed to install ueberzugpp. The OBS mirror might be down."
                        echo "ueberzugpp (GUI Image Viewer)" >> "$HOME/failed-installations.txt"
                    }
                fi
                ;;
        esac
    else
        echo "No GUI detected (Headless Server). Skipping ueberzugpp installation."
    fi
}

install_image_viewers || log_optional_failure "Image viewers"

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
    echo "Yazi installed."
}

# Call Yazi installation function
if ! command -v yazi >/dev/null 2>&1; then
    install_yazi || log_optional_failure "Yazi"
fi

echo "Installing optional Yazi dependencies (file, ffmpeg, ripgrep, etc)..."
install_package_group yazi-optional || log_optional_failure "Yazi optional dependencies"




# --- 3. COMPLEX INSTALLS (Eza, Fastfetch, Neovim) ---

# Cascadia Code Nerd Font
FONT_DIR="$HOME/.local/share/fonts"
if [ ! -f "$FONT_DIR/CaskaydiaCoveNerdFont-Regular.ttf" ]; then
    echo "Installing Cascadia Code Nerd Font..."
    mkdir -p "$FONT_DIR"
    if curl -fLo "$FONT_DIR/CascadiaCode.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip \
        && unzip -qo "$FONT_DIR/CascadiaCode.zip" -d "$FONT_DIR"; then
        rm "$FONT_DIR/CascadiaCode.zip"
        if command -v fc-cache >/dev/null 2>&1; then
            fc-cache -fv "$FONT_DIR" || true
        fi
    else
        rm -f "$FONT_DIR/CascadiaCode.zip"
        log_optional_failure "Cascadia Code Nerd Font"
    fi
fi

# Fastfetch
if ! command -v fastfetch >/dev/null 2>&1; then
    echo "Installing Fastfetch..."
    install_package_group fastfetch || log_optional_failure "Fastfetch"
fi

# Eza (Universal Method: gpg key)
if ! command -v eza >/dev/null 2>&1; then
    echo "Installing Eza..."
    install_package_group eza || log_optional_failure "Eza"
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
    if curl -fLO "https://github.com/neovim/neovim/releases/latest/download/$NVIM_TAR" \
        && run_sudo rm -rf "$NVIM_DIR" \
        && run_sudo tar -C /opt -xzf "$NVIM_TAR" \
        && run_sudo mv "/opt/${NVIM_TAR%.tar.gz}" "$NVIM_DIR"; then
        rm "$NVIM_TAR"
    else
        rm -f "$NVIM_TAR"
        echo "WARNING: Failed to download Neovim. Check your internet connection or GitHub status."
        echo "Neovim (Editor)" >> "$HOME/failed-installations.txt"
    fi
else
    echo "ARM or Unknown Detected without binary. Using system package for Neovim (Warning: might be older)."
    install_packages neovim || log_optional_failure "Neovim (package fallback)"
fi

# Symlink NVIM
if [ -f "$NVIM_DIR/bin/nvim" ]; then
    run_sudo ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
fi

# Managed config symlinks
link_path "$MERO_TERMINAL_DIR/nvim" "$HOME/.config/nvim" "Neovim configuration"
link_path "$MERO_TERMINAL_DIR/yazi" "$HOME/.config/yazi" "Yazi configuration"
link_path "$MERO_TERMINAL_DIR/starship.toml" "$HOME/.config/starship.toml" "Starship configuration"
mkdir -p "$HOME/.local/bin"

# TMUX Package Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TMUX Package Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || log_optional_failure "TPM"
fi

# Apply a quick patch to tmux-resurrect to hide the annoying "file not found" message on new installs
if [ -f "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" ]; then
    sed -i 's/display_message "Tmux resurrect file not found!"//g' "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
fi

# --- 4. SYMLINKING MERO_TERMINAL ---

if [ -d "$MERO_TERMINAL_DIR" ]; then
    link_path "$MERO_TERMINAL_DIR/bashrc" "$HOME/.bashrc" ".bashrc"
    link_path "$MERO_TERMINAL_DIR/profile" "$HOME/.profile" ".profile"
    link_path "$MERO_TERMINAL_DIR/bash-preexec.sh" "$HOME/.bash-preexec.sh" ".bash-preexec.sh"
    link_path "$MERO_TERMINAL_DIR/tmux.conf" "$HOME/.tmux.conf" ".tmux.conf"
else
    echo "Error: Mero_terminal directory not found at $MERO_TERMINAL_DIR"
fi

echo "--- Setup Complete! Restart your terminal. ---"

if [ -s "$HOME/failed-installations.txt" ]; then
    echo ""
    echo "⚠️  WARNING: Some non-essential packages failed to install:"
    cat "$HOME/failed-installations.txt"
    echo "Check your network or mirrors and try installing them manually later."
fi
