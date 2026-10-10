#!/usr/bin/env bash
# Lightweight, unattended setup. Run as your login user (not sudo ./install_lite.sh).
set -uo pipefail
REPO=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export PATH="$HOME/.local/bin:$HOME/.atuin/bin:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"
export EDITOR=nvim VISUAL=nvim
STATE="$HOME/.local/state/mero-terminal"
mkdir -p "$STATE" || exit 1
LOG="$STATE/lite-$(date +%Y%m%d_%H%M%S)-$$.log"
FAILURES="$STATE/lite-$(date +%Y%m%d_%H%M%S)-$$.failures"
: > "$FAILURES"
exec > >(tee -a "$LOG") 2>&1
failed() { printf 'FAILED: %s\n' "$*" | tee -a "$FAILURES"; }
step() { local label=$1; shift; "$@" || { failed "$label"; return 1; }; }
privileged() { if (( EUID == 0 )); then "$@"; else sudo -n "$@"; fi; }
source "$REPO/scripts/link-configs.sh" || exit 1
source "$REPO/scripts/resource-check.sh" || exit 1
step 'managed configuration symlinks' link_all_configs "$REPO" || true
step 'lite session config' link_config "$REPO/lite-session.sh" "$HOME/.config/mero-terminal/session.sh" || true
if [[ ${1:-} == --configs-only ]]; then
    [[ ! -s "$FAILURES" ]]; exit $?
fi
if [[ $# != 0 ]]; then echo 'Usage: ./install_lite.sh [--configs-only]'; exit 2; fi
case $(uname -m) in
    x86_64) ARCH=x86_64; NVIM_ARCH=x86_64; POSH_ARCH=amd64 ;;
    aarch64|arm64) ARCH=aarch64; NVIM_ARCH=arm64; POSH_ARCH=arm64 ;;
    *) failed 'unsupported architecture'; exit 1 ;;
esac
if [[ -f /etc/arch-release ]]; then
    DISTRO=arch
elif [[ -f /etc/debian_version ]]; then
    DISTRO=debian
else failed 'supported distributions: Debian/Ubuntu and Arch'; exit 1; fi
if (( EUID != 0 )) && ! sudo -n true 2>/dev/null; then
    failed 'system packages need root or passwordless/cached sudo; configurations were still linked'
    exit 1
fi
if ! require_install_memory 163840; then
    failed 'insufficient RAM for package setup (all configs are linked)'
    exit 1
fi
WORK=$(mktemp -d) || exit 1
trap 'rm -rf -- "$WORK"' EXIT
fetch() { curl --fail --location --retry 2 --connect-timeout 15 --max-time 180 "$1" -o "$2"; }
package() {
    require_install_memory 163840 || return 1
    if [[ $DISTRO == arch ]]; then
        privileged pacman -S --needed --noconfirm "$@"
    else
        privileged env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@"
    fi
}
ensure_package() {
    require_install_memory 163840 || return 1
    local command=$1 name=$2
    command -v "$command" >/dev/null 2>&1 && return 0
    package "$name" && command -v "$command" >/dev/null 2>&1
}
release_binary() {
    local repository=$1 asset=$2 binary=$3 dir path
    dir=$(mktemp -d "$WORK/release.XXXXXX") || return 1
    fetch "https://github.com/$repository/releases/latest/download/$asset" "$dir/archive.tar.gz" || return 1
    tar -xzf "$dir/archive.tar.gz" -C "$dir" || return 1
    path=$(find "$dir" -type f -name "$binary" -print -quit)
    [[ -n $path ]] || return 1
    local destination="$HOME/.local/bin/$binary"
    if [[ $binary == fastfetch ]]; then
        mkdir -p "$HOME/.local/lib/mero-terminal" || return 1
        destination="$HOME/.local/lib/mero-terminal/fastfetch"
    fi
    install -m755 "$path" "$destination" || return 1
    "$destination" --version >/dev/null 2>&1
}
install_atuin() {
    # Preserve the newer per-user version and its existing history/database.
    command -v atuin >/dev/null 2>&1 && atuin --version >/dev/null 2>&1 && return 0
    release_binary atuinsh/atuin "atuin-$ARCH-unknown-linux-musl.tar.gz" atuin
}
install_posh() {
    command -v oh-my-posh >/dev/null 2>&1 && return 0
    fetch "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-$POSH_ARCH" "$WORK/posh" &&
        install -m755 "$WORK/posh" "$HOME/.local/bin/oh-my-posh"
}
install_fastfetch() {
    # The repository wrapper does not count as an installed real binary.
    [[ -x /usr/bin/fastfetch || -x /usr/local/bin/fastfetch || -x "$HOME/.local/lib/mero-terminal/fastfetch" ]] && fastfetch --version >/dev/null 2>&1 && return 0
    package fastfetch && /usr/bin/fastfetch --version >/dev/null 2>&1 && return 0
    release_binary fastfetch-cli/fastfetch "fastfetch-linux-$ARCH.tar.gz" fastfetch || return 1
    # Preserve the responsive wrapper, with the downloaded binary in a separate path.
    mkdir -p "$HOME/.local/lib/mero-terminal" || return 1
    link_config "$REPO/bin/fastfetch" "$HOME/.local/bin/fastfetch"
}
install_croc() {
    command -v croc >/dev/null 2>&1 && return 0
    # Asset names include the release version; use GitHub's API rather than guessed URLs.
    local url
    fetch https://api.github.com/repos/schollz/croc/releases/latest "$WORK/croc.json" || return 1
    url=$(python3 - "$WORK/croc.json" "$ARCH" <<'PY'
import json, sys
suffix = 'Linux-64bit.tar.gz' if sys.argv[2] == 'x86_64' else 'Linux-ARM64.tar.gz'
print(next((a['browser_download_url'] for a in json.load(open(sys.argv[1]))['assets'] if a['name'].endswith(suffix)), ''))
PY
) || return 1
    [[ -n $url ]] || return 1
    fetch "$url" "$WORK/croc.tar.gz" && tar -xzf "$WORK/croc.tar.gz" -C "$WORK" &&
        install -m755 "$WORK/croc" "$HOME/.local/bin/croc"
}
install_nvim() {
    # Match the existing config's 0.12+ requirement. Keep a usable old editor on failure.
    if command -v nvim >/dev/null 2>&1 && nvim --clean --headless '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)' >/dev/null 2>&1; then return 0; fi
    local asset="nvim-linux-$NVIM_ARCH" channel=${MERO_NVIM_CHANNEL:-nightly} target
    target="$HOME/.local/lib/mero-terminal/$asset-$channel"
    fetch "https://github.com/neovim/neovim/releases/download/$channel/$asset.tar.gz" "$WORK/nvim.tar.gz" || return 1
    tar -xzf "$WORK/nvim.tar.gz" -C "$WORK" || return 1
    "$WORK/$asset/bin/nvim" --clean --headless '+lua os.exit(vim.fn.has("nvim-0.12") == 1 and 0 or 1)' || return 1
    mkdir -p "$target" || return 1
    cp -a "$WORK/$asset/." "$target/" || return 1
    link_config "$target/bin/nvim" "$HOME/.local/bin/nvim"
}
export MERO_LITE=1 CMAKE_BUILD_PARALLEL_LEVEL=1 MAKEFLAGS=-j1 CARGO_BUILD_JOBS=1
if [[ $DISTRO == arch ]]; then
    # Avoid an unsupported partial Arch upgrade.
    step 'package database/system refresh' privileged pacman -Syu --noconfirm || true
else step 'package database refresh' privileged env DEBIAN_FRONTEND=noninteractive apt-get update || true; fi
for spec in git:git curl:curl tar:tar gzip:gzip python3:python3 unzip:unzip timeout:coreutils tmux:tmux rg:ripgrep gh:gh zoxide:zoxide; do
    tool=${spec%%:*}; pkg=${spec#*:}
    if [[ $DISTRO == arch ]]; then
        [[ $pkg == gh ]] && pkg=github-cli
        [[ $pkg == python3 ]] && pkg=python
    fi
    step "$tool" ensure_package "$tool" "$pkg" || true
done
if [[ $DISTRO == arch ]]; then step fd ensure_package fd fd || true
else
    step fd ensure_package fdfind fd-find || true
    if command -v fdfind >/dev/null 2>&1; then step 'fd alias' link_config "$(command -v fdfind)" "$HOME/.local/bin/fd" || true; fi
fi
if [[ $DISTRO == arch ]]; then
    step 'TLS certificates' ensure_package update-ca-trust ca-certificates || true
else
    step 'TLS certificates' ensure_package update-ca-certificates ca-certificates || true
fi
step Atuin install_atuin || true
step 'Oh My Posh prompt' install_posh || true
step fastfetch install_fastfetch || true
step croc install_croc || true
if ! command -v herdr >/dev/null 2>&1; then
    step 'Herdr download' fetch "https://github.com/herdrdev/herdr/releases/latest/download/herdr-linux-$ARCH" "$WORK/herdr" &&
        step Herdr install -m755 "$WORK/herdr" "$HOME/.local/bin/herdr" || true
fi
step 'Herdr verification' herdr --version || true
if [[ ! -x "$HOME/.tmux/plugins/tpm/tpm" ]]; then
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        step 'preserve incomplete TPM checkout' mv "$HOME/.tmux/plugins/tpm" "$HOME/.tmux/plugins/tpm.incomplete.$(date +%s)" || true
    fi
    step TPM timeout 180 git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" || true
fi
if [[ -x "$HOME/.tmux/plugins/tpm/bin/install_plugins" ]]; then
    step 'tmux plugins' timeout 300 "$HOME/.tmux/plugins/tpm/bin/install_plugins" || true
fi
step Neovim install_nvim || true
if command -v nvim >/dev/null 2>&1; then
    # Bound unattended plugin setup; run one build at a time on small machines.
    export MERO_BOOTSTRAP=1
    export MERO_NVIM_CHECK="$REPO/scripts/check-nvim-install.lua"
    export MERO_NVIM_PARSERS="$REPO/scripts/check-nvim-parsers.lua"
    step 'LazyVim plugins' timeout 900 nvim --headless '+Lazy! install' '+lua dofile(vim.env.MERO_NVIM_CHECK)' +qa || true
    step 'bundled Tree-sitter parsers' timeout 60 nvim --headless '+lua dofile(vim.env.MERO_NVIM_PARSERS)' +qa || true
else failed 'LazyVim plugins: no Neovim binary'; fi
# Repair any helper link replaced by a release fallback.
step 'final configuration verification' link_all_configs "$REPO" || true
printf '\nInstallation log: %s\n' "$LOG"
if [[ -s $FAILURES ]]; then
    printf 'Finished with failures (rerun safely): %s\n' "$FAILURES"
    cat "$FAILURES"
    exit 1
fi
printf 'Lite installation complete. Start a new Bash session.\n'
