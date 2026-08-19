#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

INSTALL_WEZTERM="${MERO_INSTALL_WEZTERM:-}"
WEZTERM_CHANNEL="${MERO_WEZTERM_CHANNEL:-auto}"
NVIM_CHANNEL="${MERO_NVIM_CHANNEL:-nightly}"

prompt_yes_no() {
    local prompt_text=$1
    local default_answer=${2:-y}
    local answer=""

    while true; do
        if [ "$default_answer" = "y" ]; then
            read -r -p "$prompt_text [Y/n] " answer
            answer=${answer:-y}
        else
            read -r -p "$prompt_text [y/N] " answer
            answer=${answer:-n}
        fi

        case "$answer" in
            y|Y|yes|YES)
                return 0
                ;;
            n|N|no|NO)
                return 1
                ;;
            *)
                echo "Please answer y or n."
                ;;
        esac
    done
}

# --- 1. PRE-FLIGHT CHECKS ---

echo "--- Mero Terminal Setup ---"

if [ -z "$INSTALL_WEZTERM" ]; then
    if [ -t 0 ]; then
        if prompt_yes_no "Install custom terminal (WezTerm)?" "y"; then
            INSTALL_WEZTERM=1
        else
            INSTALL_WEZTERM=0
        fi
    else
        INSTALL_WEZTERM=1
    fi
fi

echo "WezTerm installation: $([ "$INSTALL_WEZTERM" = "1" ] && echo enabled || echo skipped)"
echo "WezTerm channel: $WEZTERM_CHANNEL"

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
    UPDATE_CMD=(pacman -Sy --noconfirm)
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

install_aur_package() {
    local package_name=$1

    if [ "$DISTRO" != "Arch" ]; then
        return 1
    fi

    if [ "$EUID" -eq 0 ]; then
        echo "AUR installs are skipped when running the installer as root."
        return 1
    fi

    if command -v yay >/dev/null 2>&1; then
        yay -S --noconfirm --needed "$package_name"
        return $?
    fi

    if command -v paru >/dev/null 2>&1; then
        paru -S --noconfirm --needed "$package_name"
        return $?
    fi

    return 1
}

install_package_group() {
    local group=$1

    case "$group" in
        base)
            case "$DISTRO" in
                "Arch")
                    install_packages git curl base-devel unzip tar gzip python python-pip tmux file
                    ;;
                "Debian")
                    install_packages git curl build-essential unzip tar gzip python3 python3-venv python3-pip tmux file
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
        aichat)
            case "$DISTRO" in
                "Arch") install_packages aichat ;;
                "Debian") return 1 ;;
            esac
            ;;
        wezterm)
            case "$DISTRO" in
                "Arch") install_packages wezterm ;;
                "Debian") install_packages libegl1-mesa libxkbcommon0 ;;
            esac
            ;;
        yazi-optional)
            case "$DISTRO" in
                "Arch")
                    install_packages file ffmpeg p7zip jq poppler fd ripgrep resvg imagemagick wl-clipboard xclip xsel
                    ;;
                "Debian")
                    install_packages file ffmpeg p7zip-full jq poppler-utils fd-find ripgrep imagemagick wl-clipboard xclip xsel
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

install_oh_my_posh() {
    echo "Installing Oh My Posh..."

    if command -v brew >/dev/null 2>&1; then
        if brew install jandedobbeleer/oh-my-posh/oh-my-posh; then
            return 0
        fi
    fi

    if [ "$DISTRO" = "Arch" ]; then
        if install_packages oh-my-posh; then
            return 0
        fi
    fi

    curl -fsSL https://ohmyposh.dev/install.sh | bash -s -- -d "$HOME/.local/bin"
}

install_aichat_release_fallback() {
    local temp_dir asset_url asset_name extract_dir binary_path arch_pattern release_info
    temp_dir=$(mktemp -d)

    case "$ARCH_TYPE" in
        x64) arch_pattern='(x86_64|amd64)' ;;
        arm64) arch_pattern='(aarch64|arm64)' ;;
        *)
            rm -rf "$temp_dir"
            return 1
            ;;
    esac

    release_info=$(curl -fsSL "https://api.github.com/repos/sigoden/aichat/releases/latest") || {
        rm -rf "$temp_dir"
        return 1
    }

    asset_url=$(printf '%s\n' "$release_info" \
        | grep -oE 'https://[^"]+' \
        | grep -E "/aichat-.*${arch_pattern}.*unknown-linux-(gnu|musl)\.tar\.gz$" \
        | head -n1)

    if [ -z "$asset_url" ]; then
        asset_url=$(printf '%s\n' "$release_info" \
            | grep -oE 'https://[^"]+' \
            | grep -E "/aichat-.*${arch_pattern}.*linux.*\.(tar\.gz|tgz)$" \
            | head -n1)
    fi

    if [ -z "$asset_url" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    asset_name=${asset_url##*/}

    if ! curl -fLo "$temp_dir/$asset_name" "$asset_url"; then
        rm -rf "$temp_dir"
        return 1
    fi

    extract_dir="$temp_dir/extract"
    mkdir -p "$extract_dir"

    if ! tar -xzf "$temp_dir/$asset_name" -C "$extract_dir"; then
        rm -rf "$temp_dir"
        return 1
    fi

    binary_path=$(find "$extract_dir" -type f -name aichat | head -n1)
    if [ -z "$binary_path" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    run_sudo install -Dm755 "$binary_path" /usr/local/bin/aichat || {
        rm -rf "$temp_dir"
        return 1
    }

    rm -rf "$temp_dir"
}

install_aichat() {
    case "$DISTRO" in
        "Arch")
            install_package_group aichat || install_aichat_release_fallback
            ;;
        "Debian")
            install_aichat_release_fallback
            ;;
        *)
            return 1
            ;;
    esac
}

install_fabric() {
    local temp_dir asset_url asset_name arch_suffix release_info download_path

    if [ "$DISTRO" = "Arch" ] && install_aur_package fabric-ai-bin; then
        if command -v fabric-ai >/dev/null 2>&1 && ! command -v fabric >/dev/null 2>&1; then
            run_sudo ln -sf "$(command -v fabric-ai)" /usr/local/bin/fabric || true
        fi
        return 0
    fi

    case "$ARCH_TYPE" in
        x64) arch_suffix="amd64" ;;
        arm64) arch_suffix="arm64" ;;
        *) return 1 ;;
    esac

    temp_dir=$(mktemp -d)
    release_info=$(curl -fsSL "https://api.github.com/repos/danielmiessler/Fabric/releases/latest") || {
        rm -rf "$temp_dir"
        return 1
    }

    asset_url=$(printf '%s\n' "$release_info" \
        | grep -oE 'https://[^"]+' \
        | grep -E "/fabric-linux-${arch_suffix}$" \
        | head -n1)

    if [ -z "$asset_url" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    asset_name=${asset_url##*/}
    download_path="$temp_dir/$asset_name"

    if ! curl -fLo "$download_path" "$asset_url"; then
        rm -rf "$temp_dir"
        return 1
    fi

    run_sudo install -Dm755 "$download_path" /usr/local/bin/fabric-ai || {
        rm -rf "$temp_dir"
        return 1
    }
    run_sudo ln -sf /usr/local/bin/fabric-ai /usr/local/bin/fabric || true

    rm -rf "$temp_dir"
}

install_lazydocker() {
    local temp_dir release_info asset_url asset_name download_path arch_suffix binary_path

    case "$ARCH" in
        x86_64) arch_suffix="x86_64" ;;
        aarch64) arch_suffix="arm64" ;;
        armv7l) arch_suffix="armv7" ;;
        *) return 1 ;;
    esac

    temp_dir=$(mktemp -d)
    release_info=$(curl -fsSL "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest") || {
        rm -rf "$temp_dir"
        return 1
    }

    asset_url=$(printf '%s\n' "$release_info" \
        | grep -oE 'https://[^"]+/lazydocker_[0-9.]+_Linux_'"$arch_suffix"'\.tar\.gz' \
        | head -n1)

    if [ -z "$asset_url" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    asset_name=${asset_url##*/}
    download_path="$temp_dir/$asset_name"

    if ! curl -fLo "$download_path" "$asset_url"; then
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$download_path" -C "$temp_dir" || {
        rm -rf "$temp_dir"
        return 1
    }

    binary_path=$(find "$temp_dir" -type f -name lazydocker | head -n1)
    if [ -z "$binary_path" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    run_sudo install -Dm755 "$binary_path" /usr/local/bin/lazydocker || {
        rm -rf "$temp_dir"
        return 1
    }
    run_sudo install -Dm755 "$binary_path" /usr/local/bin/lazydocker.real || true

    rm -rf "$temp_dir"
}

install_doc_preview_tools() {
    echo "Installing DOC preview helper..."

    if ! command -v python3 >/dev/null 2>&1; then
        return 1
    fi

    if [ "$EUID" -eq 0 ]; then
        if [ -n "${SUDO_USER:-}" ]; then
            sudo -u "$SUDO_USER" python3 -m pip install --user --upgrade mammoth || return 1
        else
            return 1
        fi
    else
        python3 -m pip install --user --upgrade mammoth || return 1
    fi
}

install_latex_rendering_tools() {
    echo "Installing LaTeX rendering helper..."

    if ! command -v python3 >/dev/null 2>&1 || ! python3 -m pip --version >/dev/null 2>&1; then
        return 1
    fi

    local pip_args=(install --user --upgrade pylatexenc)
    if python3 -m pip install --help 2>/dev/null | grep -q -- "--break-system-packages"; then
        pip_args+=(--break-system-packages)
    fi

    if [ "$EUID" -eq 0 ]; then
        if [ -n "${SUDO_USER:-}" ]; then
            sudo -u "$SUDO_USER" python3 -m pip "${pip_args[@]}" || return 1
        else
            return 1
        fi
    else
        python3 -m pip "${pip_args[@]}" || return 1
    fi
}

install_treesitter_cli() {
    echo "Installing Tree-sitter CLI..."

    if command -v tree-sitter >/dev/null 2>&1; then
        local version
        version=$(tree-sitter --version 2>/dev/null | awk '{print $2}')
        # Need >= 0.22.0 for 'build' subcommand (0.20.8 only has 'build-wasm')
        if [ -n "$version" ] && printf '%s\n' "0.22.0" "$version" | sort -V | head -1 | grep -q "^0\.22\.0$"; then
            echo "Found tree-sitter $version (>= 0.22.0), skipping install"
            return 0
        fi
    fi

    local ts_url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-x64.gz"
    if [ "$ARCH_TYPE" = "arm64" ]; then
        ts_url="https://github.com/tree-sitter/tree-sitter/releases/latest/download/tree-sitter-linux-arm64.gz"
    fi

    local temp_file
    temp_file=$(mktemp)
    if curl -fL "$ts_url" -o "$temp_file" && gunzip -c "$temp_file" > "$temp_file.bin" && run_sudo install -m755 "$temp_file.bin" /usr/local/bin/tree-sitter; then
        rm -f "$temp_file" "$temp_file.bin"
        echo "Tree-sitter CLI installed from GitHub releases"
        return 0
    fi

    rm -f "$temp_file" "$temp_file.bin"
    echo "Falling back to package manager for tree-sitter-cli..."
    case "$DISTRO" in
        "Arch") install_packages tree-sitter-cli ;;
        "Debian") install_packages tree-sitter-cli ;;
        *) return 1 ;;
    esac
}

ensure_aichat_secret_file() {
    local secret_dir=/opt/mero_terminal
    local secret_file=$secret_dir/aichat.env
    local temp_file
    local owner_user=${SUDO_USER:-$USER}

    if [ -f "$secret_file" ] && [ -r "$secret_file" ]; then
        return 0
    fi

    temp_file=$(mktemp)
    cat > "$temp_file" <<'EOF'
# AIChat secret environment
# Set your real OpenRouter key here. This file is intentionally outside the repo.
OPENROUTER_API_KEY=YOUR_OPENROUTER_API_KEY_HERE
EOF

    run_sudo mkdir -p "$secret_dir"
    run_sudo install -Dm600 "$temp_file" "$secret_file"
    run_sudo chown "$owner_user":"$owner_user" "$secret_file" || true
    rm -f "$temp_file"
}

download_font_file() {
    local destination=$1
    local url=$2

    [ -f "$destination" ] && return 0

    curl -fLo "$destination" "$url"
}

set_xfce_helper() {
    local helpers_file="$HOME/.config/xfce4/helpers.rc"

    mkdir -p "$(dirname "$helpers_file")"

    if [ ! -f "$helpers_file" ]; then
        printf 'TerminalEmulator=wezterm\n' > "$helpers_file"
        return
    fi

    if grep -q '^TerminalEmulator=' "$helpers_file"; then
        sed -i 's/^TerminalEmulator=.*/TerminalEmulator=wezterm/' "$helpers_file"
    else
        printf '\nTerminalEmulator=wezterm\n' >> "$helpers_file"
    fi
}

set_xfce_terminal_shortcut() {
    local wezterm_bin=$1
    local shortcut_file="$HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml"

    [ -n "$wezterm_bin" ] || return 0
    [ -f "$shortcut_file" ] || return 0

    if grep -q 'name="&lt;Primary&gt;&lt;Alt&gt;t"' "$shortcut_file"; then
        perl -0pi -e 's{^[ \t]*<property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="[^"]*"/>}{      <property name="&lt;Primary&gt;&lt;Alt&gt;t" type="string" value="'"$wezterm_bin"' start --always-new-process"/>}m' "$shortcut_file"
    fi
}

install_wezterm_release_fallback() {
    local temp_dir release_info asset_url asset_name binary_path
    temp_dir=$(mktemp -d)

    release_info=$(curl -fsSL "https://api.github.com/repos/wez/wezterm/releases/latest") || {
        rm -rf "$temp_dir"
        return 1
    }

    case "$ARCH_TYPE" in
        x64)
            asset_url=$(printf '%s' "$release_info" \
                | grep -oP '"browser_download_url": "\K[^"]+' \
                | grep -E '/(WezTerm|wezterm)-.*((Ubuntu|Debian).*(AppImage|\.deb)|linux.*x86_64.*\.(tar\.xz|tar\.gz)|x86_64.*\.(AppImage|deb))$' \
                | head -n1)
            ;;
        arm64)
            asset_url=$(printf '%s' "$release_info" \
                | grep -oP '"browser_download_url": "\K[^"]+' \
                | grep -iE '/(WezTerm|wezterm)-.*((Ubuntu|Debian|linux).*(aarch64|arm64).*(AppImage|\.deb|tar\.xz|tar\.gz)|(aarch64|arm64).*\.(AppImage|deb|tar\.xz|tar\.gz))$' \
                | head -n1)
            ;;
    esac

    if [ -z "$asset_url" ]; then
        rm -rf "$temp_dir"
        return 1
    fi

    asset_name=$(basename "$asset_url")
    if ! curl -fL "$asset_url" -o "$temp_dir/$asset_name"; then
        rm -rf "$temp_dir"
        return 1
    fi

    case "$asset_name" in
        *.AppImage)
            run_sudo install -Dm755 "$temp_dir/$asset_name" /usr/local/bin/wezterm || {
                rm -rf "$temp_dir"
                return 1
            }
            run_sudo ln -sf /usr/local/bin/wezterm /usr/local/bin/wezterm-gui || true
            ;;
        *.deb)
            run_sudo dpkg -i "$temp_dir/$asset_name" || {
                run_sudo env DEBIAN_FRONTEND=noninteractive apt-get install -f -y || {
                    rm -rf "$temp_dir"
                    return 1
                }
                run_sudo dpkg -i "$temp_dir/$asset_name" || {
                    rm -rf "$temp_dir"
                    return 1
                }
            }
            ;;
        *.tar.xz|*.tar.gz)
            mkdir -p "$temp_dir/extract"
            tar -xf "$temp_dir/$asset_name" -C "$temp_dir/extract" || {
                rm -rf "$temp_dir"
                return 1
            }
            binary_path=$(find "$temp_dir/extract" -type f \( -name wezterm -o -name wezterm-gui \) | head -n1)
            if [ -z "$binary_path" ]; then
                rm -rf "$temp_dir"
                return 1
            fi
            run_sudo install -Dm755 "$binary_path" /usr/local/bin/wezterm || {
                rm -rf "$temp_dir"
                return 1
            }
            run_sudo ln -sf /usr/local/bin/wezterm /usr/local/bin/wezterm-gui || true
            ;;
        *)
            rm -rf "$temp_dir"
            return 1
            ;;
    esac

    rm -rf "$temp_dir"
}

install_wezterm() {
    echo "Installing WezTerm..."

    case "$DISTRO" in
        "Arch")
            case "$WEZTERM_CHANNEL" in
                nightly)
                    install_aur_package wezterm-nightly-bin || install_package_group wezterm
                    ;;
                stable)
                    install_package_group wezterm
                    ;;
                auto|*)
                    install_aur_package wezterm-nightly-bin || install_package_group wezterm
                    ;;
            esac
            ;;
        "Debian")
            install_package_group wezterm || true
            if ! command -v wezterm >/dev/null 2>&1; then
                install_wezterm_release_fallback
            fi
            ;;
    esac
}

set_default_terminal() {
    local wezterm_bin=""

    wezterm_bin=$(command -v wezterm 2>/dev/null || true)
    if [ -z "$wezterm_bin" ]; then
        echo "WezTerm binary not found. Skipping default terminal configuration."
        return
    fi

    if command -v update-alternatives >/dev/null 2>&1; then
        run_sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator "$wezterm_bin" 70 || true
        run_sudo update-alternatives --set x-terminal-emulator "$wezterm_bin" || true
    fi

    mkdir -p "$HOME/.local/share/xfce4/helpers"
    link_path "$MERO_TERMINAL_DIR/xfce/helpers/wezterm.desktop" "$HOME/.local/share/xfce4/helpers/wezterm.desktop" "XFCE WezTerm helper"
    set_xfce_helper
    set_xfce_terminal_shortcut "$wezterm_bin"

    mkdir -p "$HOME/.local/share/applications"
    link_path "$MERO_TERMINAL_DIR/applications/org.wezfurlong.wezterm.desktop" "$HOME/.local/share/applications/org.wezfurlong.wezterm.desktop" "WezTerm desktop entry"

    if command -v update-desktop-database >/dev/null 2>&1; then
        update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true
    fi
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
echo "Refreshing package databases..."
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

# Oh My Posh
if ! command -v oh-my-posh >/dev/null 2>&1; then
    install_oh_my_posh || log_optional_failure "Oh My Posh"
fi

# Zoxide
echo "Installing Zoxide..."
curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash || log_optional_failure "Zoxide"

# Atuin
echo "Installing Atuin..."
curl --proto '=https' --tlsv1.2 -lsSf https://setup.atuin.sh | sh || log_optional_failure "Atuin"

# FZF
if [ ! -d "$HOME/.fzf" ]; then
    echo "Installing FZF..."
    if git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf; then
        # bashrc loads bindings through compatible system/local paths. Do not
        # append the version-specific ~/.fzf.bash source line to managed bashrc.
        ~/.fzf/install --all --no-bash || log_optional_failure "FZF"
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
echo "Installing Croc..."
curl -fsSL https://getcroc.schollz.com | bash || log_optional_failure "Croc"

# GitHub CLI
if ! command -v gh >/dev/null 2>&1; then
    echo "Installing GitHub CLI..."
    install_package_group github-cli || log_optional_failure "GitHub CLI"
fi

# AIChat
echo "Installing AIChat..."
install_aichat || log_optional_failure "AIChat"

# Fabric
echo "Installing Fabric..."
install_fabric || log_optional_failure "Fabric"
if command -v fabric-ai >/dev/null 2>&1 && ! command -v fabric >/dev/null 2>&1; then
    run_sudo ln -sf "$(command -v fabric-ai)" /usr/local/bin/fabric || true
fi

install_doc_preview_tools || log_optional_failure "DOC preview helper"
install_latex_rendering_tools || log_optional_failure "LaTeX rendering helper"
install_treesitter_cli || log_optional_failure "Tree-sitter CLI"
run_sudo install -Dm755 "$MERO_TERMINAL_DIR/bin/merodoc-preview" /usr/local/bin/merodoc-preview || true

# WezTerm
if [ "$INSTALL_WEZTERM" = "1" ]; then
    install_wezterm || log_optional_failure "WezTerm"
fi

# --- LazyGit Installation (Universal) ---
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

    # Ensure lazygit config exists in repo
    if [ ! -f "$MERO_TERMINAL_DIR/lazygit/config.yml" ]; then
        echo "Creating default lazygit config.yml..."
        mkdir -p "$MERO_TERMINAL_DIR/lazygit"
        cat > "$MERO_TERMINAL_DIR/lazygit/config.yml" <<'EOF'
gui:
  nerdFontsVersion: "3"
  showFileTree: true
  showRandomTip: false
  theme:
    activeBorderColor:
      - "#7cb8ff"
      - bold
    inactiveBorderColor:
      - "#315c78"
    optionsTextColor:
      - "#e8e8e8"
    selectedLineBgColor:
      - "#214969"
    cherryPickedCommitBgColor:
      - "#44FFB1"
    cherryPickedCommitFgColor:
      - "#161a1f"
    defaultFgColor:
      - "#e8e8e8"
    searchMatchBgColor:
      - "#4a86d9"
    searchMatchFgColor:
      - "#0f1317"
    unstagedChangesColor:
      - "#E52E2E"
    stagedChangesColor:
      - "#44FFB1"
EOF
    fi
fi

# --- LazyDocker Installation (Universal) ---
echo "Installing LazyDocker..."
install_lazydocker || log_optional_failure "LazyDocker"

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
    run_sudo install -Dm755 "$EXTRACTED_DIR/yazi" "$YAZI_INSTALL_DIR/yazi"
    run_sudo install -Dm755 "$EXTRACTED_DIR/yazi" "$YAZI_INSTALL_DIR/yazi.real"
    run_sudo install -Dm755 "$EXTRACTED_DIR/ya" "$YAZI_INSTALL_DIR/ya"

    echo "Cleaning up temporary Yazi files..."
    rm -rf "$TEMP_DIR"
    echo "Yazi installed."
}

# Call Yazi installation function
install_yazi || log_optional_failure "Yazi"

# --- Superfile Installation (independent file manager) ---
install_superfile() {
    echo "Installing Superfile..."

    if [ "$DISTRO" = "Arch" ]; then
        install_packages superfile
        return
    fi

    local superfile_arch
    case "$ARCH" in
        x86_64) superfile_arch="amd64" ;;
        aarch64) superfile_arch="arm64" ;;
        *) echo "Unsupported architecture for Superfile: $ARCH"; return 1 ;;
    esac

    local release_info
    local version
    local package_name
    local temp_dir
    local binary_path

    release_info=$(curl -fsS https://api.github.com/repos/yorukot/superfile/releases/latest) || return 1
    version=$(echo "$release_info" | grep -oP '"tag_name"[[:space:]]*:[[:space:]]*"v\K[^"]+' | head -n1)
    [ -n "$version" ] || return 1

    package_name="superfile-linux-v${version}-${superfile_arch}"
    temp_dir=$(mktemp -d)
    if ! curl -fL -o "$temp_dir/$package_name.tar.gz" \
        "https://github.com/yorukot/superfile/releases/download/v${version}/${package_name}.tar.gz"; then
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$temp_dir/$package_name.tar.gz" -C "$temp_dir" || {
        rm -rf "$temp_dir"
        return 1
    }
    binary_path=$(find "$temp_dir" -type f -name spf | head -n1)
    [ -n "$binary_path" ] || {
        rm -rf "$temp_dir"
        return 1
    }

    run_sudo install -Dm755 "$binary_path" /usr/local/bin/spf || {
        rm -rf "$temp_dir"
        return 1
    }
    rm -rf "$temp_dir"
}

install_superfile || log_optional_failure "Superfile"

# --- systemctl-tui (systemd service manager) ---
install_systemctl_tui() {
    echo "Installing systemctl-tui..."

    if [ "$DISTRO" = "Arch" ]; then
        install_packages systemctl-tui
        return
    fi

    local asset temp_dir binary_path
    case "$ARCH" in
        x86_64) asset="systemctl-tui-x86_64-unknown-linux-musl.tar.gz" ;;
        aarch64) asset="systemctl-tui-aarch64-unknown-linux-musl.tar.gz" ;;
        *)
            echo "Unsupported architecture for systemctl-tui: $ARCH"
            return 1
            ;;
    esac

    temp_dir=$(mktemp -d)
    if ! curl -fL --retry 3 -o "$temp_dir/systemctl-tui.tar.gz" \
        "https://github.com/rgwood/systemctl-tui/releases/latest/download/$asset"; then
        rm -rf "$temp_dir"
        return 1
    fi

    tar -xzf "$temp_dir/systemctl-tui.tar.gz" -C "$temp_dir" || {
        rm -rf "$temp_dir"
        return 1
    }
    binary_path=$(find "$temp_dir" -type f -name systemctl-tui | head -n1)
    [ -n "$binary_path" ] || {
        rm -rf "$temp_dir"
        return 1
    }

    run_sudo install -Dm755 "$binary_path" /usr/local/bin/systemctl-tui || {
        rm -rf "$temp_dir"
        return 1
    }
    rm -rf "$temp_dir"
}

install_systemctl_tui || log_optional_failure "systemctl-tui"

# --- Herdr agent multiplexer ---
install_herdr() {
    echo "Installing Herdr..."
    local herdr_asset herdr_url temp_dir

    case "$ARCH_TYPE" in
        x64) herdr_asset="herdr-linux-x86_64" ;;
        arm64) herdr_asset="herdr-linux-aarch64" ;;
        *) return 1 ;;
    esac

    herdr_url="https://github.com/ogulcancelik/herdr/releases/latest/download/${herdr_asset}"
    temp_dir=$(mktemp -d)
    if ! curl -fL --retry 3 -o "$temp_dir/herdr" "$herdr_url"; then
        rm -rf "$temp_dir"
        return 1
    fi
    run_sudo install -Dm755 "$temp_dir/herdr" /usr/local/bin/herdr || {
        rm -rf "$temp_dir"
        return 1
    }
    rm -rf "$temp_dir"
}

install_herdr || log_optional_failure "Herdr"

install_herdr_integrations() {
    command -v herdr >/dev/null 2>&1 || return 1

    local codex_home pi_home skill_parent skill_tmp skill_installed
    codex_home="${CODEX_HOME:-$HOME/.codex}"
    pi_home="${PI_CODING_AGENT_DIR:-$HOME/.pi}"

    if [ -d "$codex_home" ]; then
        herdr integration install codex || log_optional_failure "Herdr Codex integration"
    fi
    if [ -d "$pi_home" ]; then
        herdr integration install pi || log_optional_failure "Herdr Pi integration"
    fi

    skill_installed=0
    if command -v npx >/dev/null 2>&1; then
        npx --yes skills add ogulcancelik/herdr --skill herdr -g && skill_installed=1
    fi

    # The official installer currently requires Node 22.20+. Keep a raw-file
    # fallback so older VMs still receive the same Herdr skill.
    if [ "$skill_installed" -eq 0 ]; then
        skill_tmp=$(mktemp -d)
        if ! curl -fsSL https://raw.githubusercontent.com/ogulcancelik/herdr/master/SKILL.md \
            -o "$skill_tmp/SKILL.md"; then
            rm -rf "$skill_tmp"
            return 1
        fi

        for skill_parent in "$HOME/.agents/skills" "$codex_home/skills" "$pi_home/agent/skills"; do
            if [ -L "$skill_parent" ] && [ ! -e "$skill_parent" ]; then
                mv "$skill_parent" "${skill_parent}.broken-$(date +%Y%m%d-%H%M%S)"
            fi
            mkdir -p "$skill_parent/herdr"
            install -m644 "$skill_tmp/SKILL.md" "$skill_parent/herdr/SKILL.md"
        done
        rm -rf "$skill_tmp"
    fi
}

echo "Installing optional Yazi dependencies (file, ffmpeg, ripgrep, etc)..."
install_package_group yazi-optional || log_optional_failure "Yazi optional dependencies"




# --- 3. COMPLEX INSTALLS (Eza, Fastfetch, Neovim) ---

# Nerd Fonts for terminal UI
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

# Neovim (nightly by default; nvim-treesitter main requires Neovim 0.12+)
echo "Installing/Updating Neovim..."
NVIM_DIR="/opt/nvim"
NVIM_TAR=""

if [ "$ARCH_TYPE" = "x64" ]; then
    NVIM_TAR="nvim-linux-x86_64.tar.gz"
elif [ "$ARCH_TYPE" = "arm64" ]; then
    NVIM_TAR="nvim-linux-arm64.tar.gz"
fi

if [ -n "$NVIM_TAR" ]; then
    echo "Downloading Neovim ($NVIM_CHANNEL, $NVIM_TAR)..."
    if curl -fLO "https://github.com/neovim/neovim/releases/download/$NVIM_CHANNEL/$NVIM_TAR" \
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
if [ "$INSTALL_WEZTERM" = "1" ]; then
    link_path "$MERO_TERMINAL_DIR/wezterm" "$HOME/.config/wezterm" "WezTerm configuration"
fi
link_path "$MERO_TERMINAL_DIR/yazi" "$HOME/.config/yazi" "Yazi configuration"
mkdir -p "$HOME/.config/herdr"
link_path "$MERO_TERMINAL_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml" "Herdr configuration"
install_herdr_integrations || log_optional_failure "Herdr integrations"
mkdir -p "$HOME/.config/superfile"
link_path "$MERO_TERMINAL_DIR/superfile/config.toml" "$HOME/.config/superfile/config.toml" "Superfile configuration"
link_path "$MERO_TERMINAL_DIR/superfile/hotkeys.toml" "$HOME/.config/superfile/hotkeys.toml" "Superfile hotkeys"
link_path "$MERO_TERMINAL_DIR/lazygit" "$HOME/.config/lazygit" "LazyGit configuration"
link_path "$MERO_TERMINAL_DIR/oh-my-posh" "$HOME/.config/oh-my-posh" "Oh My Posh configuration"
link_path "$MERO_TERMINAL_DIR/fastfetch" "$HOME/.config/fastfetch" "Fastfetch configuration"
link_path "$MERO_TERMINAL_DIR/starship.toml" "$HOME/.config/starship.toml" "Starship configuration"
link_path "$MERO_TERMINAL_DIR/atuin/config.toml" "$HOME/.config/atuin/config.toml" "Atuin configuration"
mkdir -p "$HOME/.config/aichat/roles"
link_path "$MERO_TERMINAL_DIR/aichat/config.yaml" "$HOME/.config/aichat/config.yaml" "AIChat configuration"
link_path "$MERO_TERMINAL_DIR/aichat/roles/coder.md" "$HOME/.config/aichat/roles/coder.md" "AIChat coder role"
link_path "$MERO_TERMINAL_DIR/aichat/roles/suzy-brain.md" "$HOME/.config/aichat/roles/suzy-brain.md" "AIChat suzy-brain role"
ensure_aichat_secret_file
if [ -r /opt/mero_terminal/aichat.env ]; then
    sed -E 's/^([A-Za-z_][A-Za-z0-9_]*)="(.*)"$/=/' /opt/mero_terminal/aichat.env > "$HOME/.config/aichat/.env"
fi
if command -v aichat >/dev/null 2>&1; then
    run_sudo ln -sf "$(command -v aichat)" /usr/local/bin/ai || true
fi

# Antigravity (AGY) configuration
mkdir -p "$HOME/.gemini/config"
link_path "$MERO_TERMINAL_DIR/antigravity/config.json" "$HOME/.gemini/config/config.json" "Antigravity configuration"
link_path "$MERO_TERMINAL_DIR/antigravity/mcp_config.json" "$HOME/.gemini/config/mcp_config.json" "Antigravity MCP configuration"
link_path "$MERO_TERMINAL_DIR/antigravity/hooks.json" "$HOME/.gemini/config/hooks.json" "Antigravity hooks configuration"
link_path "$MERO_TERMINAL_DIR/antigravity/skills.json" "$HOME/.gemini/config/skills.json" "Antigravity skills registry"
link_path "$MERO_TERMINAL_DIR/antigravity/plugins.json" "$HOME/.gemini/config/plugins.json" "Antigravity plugins registry"
link_path "$MERO_TERMINAL_DIR/antigravity/rules" "$HOME/.gemini/config/rules" "Antigravity rules"
link_path "$MERO_TERMINAL_DIR/antigravity/skills" "$HOME/.gemini/config/skills" "Antigravity skills"
link_path "$MERO_TERMINAL_DIR/antigravity/plugins" "$HOME/.gemini/config/plugins" "Antigravity plugins"

run_sudo install -Dm755 "$MERO_TERMINAL_DIR/bin/yazi-select" /usr/local/bin/yazi-select || true
run_sudo install -Dm755 "$MERO_TERMINAL_DIR/bin/lazydocker-select" /usr/local/bin/lazydocker-select || true
run_sudo install -Dm755 "$MERO_TERMINAL_DIR/bin/fastfetch" /usr/local/bin/fastfetch || true
if command -v nvim >/dev/null 2>&1; then
    echo "Syncing Neovim plugins..."
    # This also restores the tracked Neovim image stack (3rd/image.nvim plus the
    # chafa fallback bridge), so fresh machines get image previews immediately.
    nvim --headless "+Lazy! restore" +qa || log_optional_failure "Neovim plugins"
    echo "Installing Neovim Treesitter parsers..."
    nvim --headless "+Lazy load nvim-treesitter" "+lua local ts=require('nvim-treesitter'); if ts.install then ts.install({'latex', 'vim', 'vimdoc'}):wait(300000) else vim.cmd('TSInstall! latex vim vimdoc') end" +qa || log_optional_failure "Neovim Treesitter parsers"
    VIM_TS_QUERY="$HOME/.local/share/nvim/lazy/nvim-treesitter/runtime/queries/vim/highlights.scm"
    if [ -f "$VIM_TS_QUERY" ]; then
        sed -i '/^[[:space:]]*"tab"$/d' "$VIM_TS_QUERY"
    fi
fi

if command -v ya >/dev/null 2>&1; then
    echo "Installing Yazi plugins..."
    ya pkg install || log_optional_failure "Yazi plugins"
fi

mkdir -p "$HOME/.local/bin"
if [ "$INSTALL_WEZTERM" = "1" ]; then
    set_default_terminal
fi

# TMUX Package Manager (TPM)
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "Installing TMUX Package Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm || log_optional_failure "TPM"
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

if [ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]; then
    echo "Installing tmux plugins via TPM..."
    "$HOME/.tmux/plugins/tpm/bin/install_plugins" || log_optional_failure "tmux plugins"
fi

# Apply a quick patch to tmux-resurrect to hide the annoying "file not found" message on new installs
if [ -f "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh" ]; then
    sed -i '/display_message "Tmux resurrect file not found!"/d' "$HOME/.tmux/plugins/tmux-resurrect/scripts/restore.sh"
fi

echo "--- Setup Complete! Restart your terminal. ---"

if [ -s "$HOME/failed-installations.txt" ]; then
    echo ""
    echo "⚠️  WARNING: Some non-essential packages failed to install:"
    cat "$HOME/failed-installations.txt"
    echo "Check your network or mirrors and try installing them manually later."
fi
