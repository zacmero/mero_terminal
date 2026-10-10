#!/usr/bin/env bash
# Shared by both installers. Never replace an existing config without a backup.
link_config() {
    local source=$1 destination=$2 relative
    [[ -e "$source" || -L "$source" ]] || { printf 'Missing config: %s\n' "$source" >&2; return 1; }
    if [[ -L "$destination" && $(readlink -f "$destination") == "$(readlink -f "$source")" ]]; then
        return 0
    fi
    mkdir -p "$(dirname "$destination")" || return 1
    if [[ -e "$destination" || -L "$destination" ]]; then
        relative=${destination#"$HOME/"}
        mkdir -p "$CONFIG_BACKUP/$(dirname "$relative")" || return 1
        mv -- "$destination" "$CONFIG_BACKUP/$relative" || return 1
    fi
    ln -s -- "$source" "$destination"
}

link_all_configs() {
    local repo=$1 entry source target failed=0
    CONFIG_BACKUP="${CONFIG_BACKUP:-$HOME/mero_terminal_backup/$(date +%Y%m%d_%H%M%S)_$$}"
    while IFS='|' read -r source target; do
        [[ -n "$source" ]] || continue
        link_config "$repo/$source" "$HOME/$target" || failed=1
    done <<'LINKS'
codex/config.toml|.codex/config.toml
bashrc|.bashrc
profile|.profile
bash-preexec.sh|.bash-preexec.sh
tmux.conf|.tmux.conf
nvim|.config/nvim
wezterm|.config/wezterm
yazi|.config/yazi
herdr/config.toml|.config/herdr/config.toml
superfile/config.toml|.config/superfile/config.toml
superfile/hotkeys.toml|.config/superfile/hotkeys.toml
lazygit|.config/lazygit
oh-my-posh|.config/oh-my-posh
fastfetch|.config/fastfetch
starship.toml|.config/starship.toml
atuin/config.toml|.config/atuin/config.toml
opencode/opencode.json|.config/opencode/opencode.json
aichat/config.yaml|.config/aichat/config.yaml
aichat/roles/coder.md|.config/aichat/roles/coder.md
aichat/roles/suzy-brain.md|.config/aichat/roles/suzy-brain.md
antigravity/config.json|.gemini/config/config.json
antigravity/mcp_config.json|.gemini/config/mcp_config.json
antigravity/hooks.json|.gemini/config/hooks.json
antigravity/skills.json|.gemini/config/skills.json
antigravity/plugins.json|.gemini/config/plugins.json
antigravity/rules|.gemini/config/rules
antigravity/skills|.gemini/config/skills
antigravity/plugins|.gemini/config/plugins
xfce/helpers/wezterm.desktop|.local/share/xfce4/helpers/wezterm.desktop
applications/org.wezfurlong.wezterm.desktop|.local/share/applications/org.wezfurlong.wezterm.desktop
LINKS
    # Repository helper scripts stay available even when their underlying tools aren't.
    for entry in "$repo"/bin/*; do
        [[ -f "$entry" ]] || continue
        # Prefer the Codex-specific launcher once, avoiding link churn on reruns.
        [[ -f "$repo/codex/bin/${entry##*/}" ]] && continue
        link_config "$entry" "$HOME/.local/bin/${entry##*/}" || failed=1
    done
    for entry in "$repo"/codex/bin/*; do
        [[ -f "$entry" ]] || continue
        link_config "$entry" "$HOME/.local/bin/${entry##*/}" || failed=1
    done
    return "$failed"
}
