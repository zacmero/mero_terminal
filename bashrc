# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# Allow Ctrl+S / Ctrl+Q to reach terminal apps like Neovim instead of
# triggering terminal flow control.
if tty -s; then
  stty -ixon -ixoff 2>/dev/null || true
fi

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
export HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
  debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
xterm-color | *-256color) color_prompt=yes ;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
  if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
    # We have color support; assume it's compliant with Ecma-48
    # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
    # a case would tend to support setf rather than setaf.)
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [ "$color_prompt" = yes ]; then
  PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]: F\[\033[01;34m\]\w\[\033[00m\]\$ '
else
  PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm* | rxvt*)
  PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
  ;;
*) ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  #alias ls='ls --color=auto' -> using eza now
  #alias dir='dir --color=auto'
  #alias vdir='vdir --color=auto'

  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
#alias ll='ls -alF'
#alias la='ls -A'
#alias l='ls -CF'

# --- Colorize 'man' pages (Dracula Theme) ---

# This flag tells 'less' to interpret ANSI color codes
export LESS="-R"

# This tells 'groff' (the formatter for 'man') to not use old-style formatting
export GROFF_NO_SGR=1

# These variables tell 'less' what color codes to use for text attributes
export LESS_TERMCAP_mb=$'\e[1;35m'    # Start "blinking" -> Bright Pink
export LESS_TERMCAP_md=$'\e[1;36m'    # Start "bold" (headings) -> Bright Cyan
export LESS_TERMCAP_me=$'\e[0m'       # End "blinking/bold"
export LESS_TERMCAP_so=$'\e[1;45;33m' # Start "standout" (search) -> Yellow on Purple
export LESS_TERMCAP_se=$'\e[0m'       # End "standout"
export LESS_TERMCAP_us=$'\e[1;32m'    # Start "underline" (flags) -> Bright Green
export LESS_TERMCAP_ue=$'\e[0m'       # End "underline"

# --- New 'eza' Aliases (Recommended) ---

# Replace 'ls' with 'eza'
# --icons: Adds icons (requires a Nerd Font)
# --git: Adds git status
alias ls='eza --icons --git'

# 'll' -> Long list, all files, with header
# -l: long format
# -a: all files (including hidden)
# -h: header (adds column titles)
alias ll='eza -la -h --icons --git'

# 'la' -> List all files (grid view)
alias la='eza -a --icons --git'

# 'l' -> Long list, no hidden files
# (This is a common and useful one)
alias l='eza -l -h --icons --git'

# 'lt' -> Tree view
# -T: tree
alias lt='eza -T'

# Superfile launcher that returns the shell to the directory saved by its
# cd_quit action. This keeps Superfile on the native terminal so its preview
# renderer receives the real terminal dimensions instead of an extra PTY.
spf() {
  # WezTerm lacks the Kitty Unicode-placeholder feature Superfile requires.
  # Mask it only for Superfile so it selects the portable ANSI renderer.
  if [ "${TERM_PROGRAM:-}" = "WezTerm" ]; then
    TERM_PROGRAM=MeroTerminal command spf "$@"
  else
    command spf "$@"
  fi
}

sf() {
  local superfile_state_dir superfile_lastdir_file
  local superfile_lastdir superfile_dir superfile_status

  superfile_state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/superfile"
  superfile_lastdir_file="$superfile_state_dir/lastdir"

  spf "$@"
  superfile_status=$?
  if [ "$superfile_status" -ne 0 ]; then
    return "$superfile_status"
  fi

  [ -r "$superfile_lastdir_file" ] || return 0
  superfile_lastdir=$(<"$superfile_lastdir_file")
  case "$superfile_lastdir" in
    "cd '"*"'") superfile_dir=${superfile_lastdir:4:-1} ;;
    *) return 0 ;;
  esac

  if [ -n "$superfile_dir" ] && [ -d "$superfile_dir" ]; then
    cd -- "$superfile_dir" || return
  fi
}

#fzf folder navigation + lazyvin fast open:
# Keep single-letter `v` free for shell/vi workflows.
alias vf='fzf | xargs -r nvim'

#Vim Mode:
# Bash readline native editing-mode toggle.
# - Bash starts in emacs mode.
# - F8 toggles vi/emacs; in vi mode Esc switches insert/command inside the line.
set -o emacs
export MERO_READLINE_MODE=emacs

_mero_edit_readline_buffer() {
  local tmp_file editor

  tmp_file="$(mktemp "${TMPDIR:-/tmp}/mero-readline.XXXXXX")" || return
  printf '%s' "${READLINE_LINE:-}" >"$tmp_file"

  editor="${VISUAL:-${EDITOR:-nvim}}"

  # Run the editor against a temp file, then pull the edited content back into
  # the current Readline buffer instead of executing it immediately.
  bash -lc "$editor \"\$1\"" _ "$tmp_file"

  if [ -f "$tmp_file" ]; then
    READLINE_LINE="$(cat "$tmp_file")"
    READLINE_POINT=${#READLINE_LINE}
    READLINE_MARK=0
    command rm -f "$tmp_file"
  fi
}

toggle_readline_mode() {
  local current_mode
  current_mode="$(set -o | awk '/^vi[[:space:]]/ { print $2 }' | head -n1)"

  if [[ "$current_mode" == "on" ]]; then
    set -o emacs
    export MERO_READLINE_MODE=emacs
  else
    set -o vi
    export MERO_READLINE_MODE=vi
  fi
}

if [[ $- == *i* ]]; then
  # In vi-command mode, `v` opens the current prompt buffer in $VISUAL/$EDITOR
  # and writes the result back into Readline without auto-executing it.
  bind -m vi-command -x '"v": _mero_edit_readline_buffer'
  # WezTerm maps F8 to Ctrl+_ so the toggle is stable across terminal modes.
  bind -m emacs -x '"\C-_": toggle_readline_mode'
  bind -x '"\C-_": toggle_readline_mode'
  bind -m vi-insert -x '"\C-_": toggle_readline_mode'
  bind -m vi-command -x '"\C-_": toggle_readline_mode'
  # Keep the standard F8 escape as a fallback for terminals outside WezTerm.
  bind -m emacs -x '"\e[19~": toggle_readline_mode'
  bind -x '"\e[19~": toggle_readline_mode'
  bind -m vi-insert -x '"\e[19~": toggle_readline_mode'
  bind -m vi-command -x '"\e[19~": toggle_readline_mode'
fi

_mero_package_manager() {
  local dir=$1

  if [ -f "$dir/bun.lockb" ] || [ -f "$dir/bun.lock" ]; then
    echo bun
  elif [ -f "$dir/pnpm-lock.yaml" ]; then
    echo pnpm
  elif [ -f "$dir/yarn.lock" ]; then
    echo yarn
  else
    echo npm
  fi
}

_mero_package_script_exists() {
  local dir=$1
  local script=$2

  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const fs = require("fs");
    const pkg = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    process.exit(pkg.scripts && pkg.scripts[process.argv[2]] ? 0 : 1);
  ' "$dir/package.json" "$script" >/dev/null 2>&1
}

_mero_start_web_preview() {
  local dir=$1
  local pm
  local log_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mero_terminal"
  local log_file="$log_dir/web-preview.log"
  local status_file="$log_dir/web-preview.status"
  local port="${MERO_WEB_PREVIEW_PORT:-4173}"
  local url="http://127.0.0.1:$port"
  local ready=0
  local attempts=0
  local server_label=""

  mkdir -p "$log_dir" 2>/dev/null || {
    log_dir="/tmp/mero_terminal"
    log_file="$log_dir/web-preview.log"
    status_file="$log_dir/web-preview.status"
    mkdir -p "$log_dir"
  }
  pm=$(_mero_package_manager "$dir")

  if [ -f "$dir/package.json" ] && _mero_package_script_exists "$dir" dev; then
    case "$pm" in
    bun)
      (cd "$dir" && nohup bun run dev -- --host 127.0.0.1 --port "$port" >"$log_file" 2>&1 &)
      ;;
    pnpm)
      (cd "$dir" && nohup pnpm run dev -- --host 127.0.0.1 --port "$port" >"$log_file" 2>&1 &)
      ;;
    yarn)
      (cd "$dir" && nohup yarn dev --host 127.0.0.1 --port "$port" >"$log_file" 2>&1 &)
      ;;
    *)
      (cd "$dir" && nohup npm run dev -- --host 127.0.0.1 --port "$port" >"$log_file" 2>&1 &)
      ;;
    esac
    server_label="dev script"
    ready=1
  fi

  if [ "$ready" = 0 ] && command -v live-server >/dev/null 2>&1; then
    (cd "$dir" && nohup live-server --host=127.0.0.1 --port="$port" --no-browser >"$log_file" 2>&1 &)
    server_label="live-server"
    ready=1
  fi

  if [ "$ready" = 0 ] && command -v python3 >/dev/null 2>&1; then
    (cd "$dir" && nohup python3 -u -m http.server "$port" --bind 127.0.0.1 >"$log_file" 2>&1 &)
    server_label="python http.server"
    ready=1
  fi

  if [ "$ready" = 0 ]; then
    echo "Web preview requested, but no preview server tool is available."
    return 1
  fi

  if command -v curl >/dev/null 2>&1; then
    while [ "$attempts" -lt 40 ]; do
      if curl -fsS "$url" >/dev/null 2>&1; then
        printf '%s\n%s\n%s\n' "$url" "$server_label" "$log_file" >"$status_file"
        echo "Web preview ready: $url ($server_label)"
        echo "Web preview log: $log_file"
        return 0
      fi
      attempts=$((attempts + 1))
      sleep 0.25
    done
  fi

  printf '%s\n%s\n%s\n' "$url" "$server_label" "$log_file" >"$status_file"
  echo "Web preview starting: $url ($server_label)"
  echo "Web preview log: $log_file"
  return 0
}

web-status() {
  local status_file="${XDG_CACHE_HOME:-$HOME/.cache}/mero_terminal/web-preview.status"
  if [ -r "$status_file" ]; then
    sed -n '1,3p' "$status_file"
    return 0
  fi
  echo "No web preview status file found."
  return 1
}

ide() {
  local web_mode=0
  local target="."
  local resolved

  case "${1:-}" in
  -web | --web)
    web_mode=1
    shift
    ;;
  esac

  target="${1:-.}"
  resolved="$(realpath "$target" 2>/dev/null || printf '%s' "$target")"

  if [ "$web_mode" = "1" ]; then
    _mero_start_web_preview "$resolved"
    if command -v xdg-open >/dev/null 2>&1 && [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]; then
      (
        sleep 1
        xdg-open "http://127.0.0.1:${MERO_WEB_PREVIEW_PORT:-4173}" >/dev/null 2>&1 &
      ) || true
    fi
  fi

  MERO_IDE_TARGET="$resolved" nvim "+MeroIde"
}

alias nvide='ide'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\[0-9\]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
  . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# --- PATHS & EXPORTS (Universal) ---

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Default Browser (WSL Friendly)
export BROWSER=explorer.exe

# Default editor for interactive shells and tools like Yazi.
export VISUAL="nvim"
export EDITOR="$VISUAL"
if command -v wezterm >/dev/null 2>&1; then
  export TERMINAL="wezterm"
fi

# PNPM
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac

# --- FZF SUPERCHARGED SETUP ---
# 1. Base Configuration (Colors & Backends)
# Use ripgrep instead of find for lightning-fast searches that respect .gitignore
export FZF_DEFAULT_COMMAND="rg --files --hidden --glob '!.git' --glob '!node_modules' --glob '!/mnt/*'"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
# FZF_ALT_C: Find directories (falling back to find, but pruning WSL mounts and hidden dirs)
export FZF_ALT_C_COMMAND="find . -mindepth 1 -maxdepth 5 -type d \( -name .git -o -name node_modules -o -path '/mnt/*' \) -prune -o -print"

# 2. Previews
# Press CTRL-T to see file previews with bat syntax highlighting
export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always {}' --preview-window=right:60% --bind 'ctrl-/:change-preview-window(down|hidden|)'"
# Press ALT-C to see directory tree previews with eza
export FZF_ALT_C_OPTS="--preview 'eza -T -L 2 --icons {}' --preview-window=right:40% --bind 'ctrl-/:change-preview-window(down|hidden|)'"

# 3. Fuzzy Autocompletion (**<TAB>) Overrides
# Make **<TAB> use ripgrep for path completions
_fzf_compgen_path() {
  rg --files --hidden --glob '!.git' --glob '!node_modules' --glob '!/mnt/*' "$1" 2>/dev/null
}
_fzf_compgen_dir() {
  find "$1" -mindepth 1 -maxdepth 5 -type d \( -name .git -o -name node_modules -o -path '/mnt/*' \) -prune -o -print 2>/dev/null
}

# 4. Load System Scripts (Supports both APT and GitHub installs)
if [ -f ~/.fzf/shell/key-bindings.bash ]; then
  source ~/.fzf/shell/key-bindings.bash
elif [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

if [ -f ~/.fzf/shell/completion.bash ]; then
  source ~/.fzf/shell/completion.bash
elif [ -f /usr/share/bash-completion/completions/fzf ]; then
  source /usr/share/bash-completion/completions/fzf
fi
# ------------------------------

# --- TMUX SETUP ---
# Force UTF-8 drawing for icons (especially for themes like Dracula)
alias tmux='tmux -u'
# Helper aliases
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'
# ------------------

# BUN
export PATH="$HOME/.bun/bin:$PATH"

# ATUIN
export ATUIN_BIN_DIR="$HOME/.atuin/bin"
export PATH="$ATUIN_BIN_DIR:$PATH"

# CARGO (Rust - often needed for eza/bat alternatives)
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# LOCAL BIN (Your personal scripts)
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# AIChat uses a tracked config, while secrets live outside the repo.
export AICHAT_CONFIG_DIR="$HOME/.config/aichat"
export AICHAT_CONFIG_FILE="$AICHAT_CONFIG_DIR/config.yaml"
export AICHAT_ROLES_DIR="$AICHAT_CONFIG_DIR/roles"
unset AICHAT_ENV_FILE
[ -r "/opt/mero_terminal/aichat.env" ] && source "/opt/mero_terminal/aichat.env"

if command -v fabric-ai >/dev/null 2>&1 && ! command -v fabric >/dev/null 2>&1; then
  alias fabric='fabric-ai'
fi

alias ai='aichat'

# OPENCODE
export PATH="$HOME/.opencode/bin:$PATH"

# Oh My Posh (P10K-style), with Starship kept only as a fallback.
if command -v oh-my-posh >/dev/null 2>&1; then
  POSH_THEME="$HOME/.config/oh-my-posh/mero-rainbow-lean.omp.json"

  if [ -f "$POSH_THEME" ]; then
    export POSH_THEME
    eval "$(oh-my-posh init bash --config "$POSH_THEME")"
  else
    eval "$(oh-my-posh init bash --config powerlevel10k_rainbow)"
  fi
elif command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

eval "$(zoxide init bash)"
if command -v fastfetch >/dev/null 2>&1 && [ -t 1 ] && [ -z "${MERO_FASTFETCH_SHOWN:-}" ]; then
  export MERO_FASTFETCH_SHOWN=1
  fastfetch
fi

# Ensure /usr/local/bin is in PATH for globally installed tools like Yazi
export PATH="/usr/local/bin:$PATH"

#################################################################
# ADDITIONS FROM CHRIS TITUS'S BASHRC
#################################################################

# --- Enhanced Colors and Formatting ---

# To have colors for ls, grep, etc.
export CLICOLOR=1

# Detailed color definitions for 'ls' command based on file type
export LS_COLORS='no=00:fi=00:di=00;34:ln=01;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:ex=01;32:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.deb=01;31:*.rpm=01;31:*.jar=01;31:*.jpg=01;35:*.jpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.avi=01;35:*.fli=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.ogg=01;35:*.mp3=01;35:*.wav=01;35:*.xml=00;31:'

# Color for manpages to make them easier to read
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

# --- Safety and Utility Aliases ---

# Use trash-cli instead of permanently deleting files with rm
alias rm='trash -v'

# Quick navigation aliases
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias py='python3'

# --- Custom Functions ---

# Show the current distribution
distribution() {
  if [ -r /etc/os-release ]; then
    source /etc/os-release
    if [ -n "$ID" ]; then
      echo "$ID"
    fi
  fi
}

# Show the current version of the operating system (Corrected to use batcat)
ver() {
  local bat_cmd=""
  if command -v bat >/dev/null 2>&1; then
    bat_cmd="bat"
  elif command -v batcat >/dev/null 2>&1; then
    bat_cmd="batcat"
  fi

  if [ -r /etc/os-release ]; then
    if [ -n "$bat_cmd" ]; then
      "$bat_cmd" /etc/os-release
    else
      command cat /etc/os-release
    fi
  elif [ -r /etc/issue ]; then
    if [ -n "$bat_cmd" ]; then
      "$bat_cmd" /etc/issue
    else
      command cat /etc/issue
    fi
  else
    echo "Error: Cannot determine OS version."
  fi
}

# Extracts any archive file
extract() {
  for archive in "$@"; do
    if [ -f "$archive" ]; then
      case $archive in
      *.tar.bz2) tar xvjf "$archive" ;;
      *.tar.gz) tar xvzf "$archive" ;;
      *.bz2) bunzip2 "$archive" ;;
      *.rar) rar x "$archive" ;;
      *.gz) gunzip "$archive" ;;
      *.tar) tar xvf "$archive" ;;
      *.tbz2) tar xvjf "$archive" ;;
      *.tgz) tar xvzf "$archive" ;;
      *.zip) unzip "$archive" ;;
      *.Z) uncompress "$archive" ;;
      *.7z) 7z x "$archive" ;;
      *) echo "don't know how to extract '$archive'..." ;;
      esac
    else
      echo "'$archive' is not a valid file!"
    fi
  done
}

# Copy file with a progress bar
cpp() {
  set -e
  strace -q -ewrite cp -- "${1}" "${2}" 2>&1 |
    awk '{
        count += $NF
        if (count % 10 == 0) {
            percent = count / total_size * 100
            printf "%3d%% [", percent
            for (i=0;i<=percent;i++)
                printf "="
            printf ">"
            for (i=percent;i<100;i++)
                printf " "
            printf "]\r"
        }
    }
    END { print "" }' total_size="$(stat -c '%s' "${1}")" count=0
}

# --- Command Overrides ---

# Automatically do an 'ls' after each 'cd'
cd() {
  if [ -n "$1" ]; then
    builtin cd "$@" && ls
  else
    builtin cd ~ && ls
  fi
}

# Alias 'cat' to whichever bat binary exists on the current distro.
if command -v bat >/dev/null 2>&1; then
  alias cat='bat'
elif command -v batcat >/dev/null 2>&1; then
  alias cat='batcat'
fi

# Only source it if the file actually exists (prevents errors on new machines)
if [ -f "$HOME/.config/broot/launcher/bash/br" ]; then
  source "$HOME/.config/broot/launcher/bash/br"
fi

# OpenClaw Completion
# source <(openclaw completion --shell bash)
export PATH="$HOME/bin:$PATH"
# OpenClaw - Auto-load NVM and run
openclaw() {
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
  nvm use 22 >/dev/null
  command openclaw "$@"
}

alias claw="openclaw"

# Mise-en-place (Environment & Tool Manager)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
elif [ -f "$HOME/.local/bin/mise" ]; then
  eval "$("$HOME/.local/bin/mise" activate bash)"
fi

# bash-preexec must be loaded after tools that rewrite PROMPT_COMMAND, and
# before Atuin registers its preexec/precmd hooks.
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
eval "$(atuin init bash)"

# >>> Codex installer >>>
export PATH="$HOME/.local/bin:$PATH"
# <<< Codex installer <<<
codexh() {
  if [ "${1:-}" = "savings" ]; then
    local port stats mode failures log_file failure found=0

    for port in 18994 18996 18995; do
      stats="$(command curl -fsS --max-time 1 "http://127.0.0.1:${port}/stats" 2>/dev/null)" || continue
      found=1
      case "$port" in
        18996) mode="token" ;;
        18995) mode="cache" ;;
        *) mode="unknown" ;;
      esac

      printf '%s\n' "$stats" | command jq -r --arg port "$port" --arg mode "$mode" '
        def n: . // 0;
        def pct($part; $whole):
          if $whole > 0 then (($part * 10000 / $whole | round) / 100 | tostring) + "%" else "n/a" end;
        .codex_ws as $ws |
        ($ws.frame_tokens_saved_sum | n) as $saved |
        ($ws.frame_attempted_tokens_sum | n) as $attempted_tokens |
        ($ws.frames_compressed_total | n) as $applied |
        ($ws.frames_failed_total | n) as $failed |
        ($ws.frames_attempted_total | n) as $frames |
        ($ws.frame_elapsed_ms.average | n) as $avg_ms |
        ($ws.frame_elapsed_ms.max | n) as $max_ms |
        ($ws.units_modified_total | n) as $units_modified |
        ($ws.units_total | n) as $units |
        ($ws.units_kompress_attempted_total | n) as $kompress_attempted |
        ($ws.units_to_kompress_total | n) as $kompress_candidates |
        (.prefix_cache.totals.cache_read_tokens | n) as $cache_reads |
        "Headroom proxy :\($port) [\($mode)]",
        "  tool-result compression: \($saved) tokens saved (\(pct($saved; $attempted_tokens))) from \($attempted_tokens) eligible tokens",
        "  frames: \($applied)/\($frames) compressed (\(pct($applied; $frames))); \($failed) failed open",
        "  compression time: \($avg_ms) ms/frame average; \($max_ms) ms maximum",
        "  units: \($units_modified)/\($units) modified; Kompress \($kompress_attempted)/\($kompress_candidates) attempted",
        "  provider prefix-cache reads: \($cache_reads) tokens (not compression or proven quota savings)"
      '

      failures="$(printf '%s\n' "$stats" | command jq -r '.codex_ws.frames_failed_total // 0')"
      if [ "$failures" -gt 0 ] 2>/dev/null; then
        failure=""
        for log_file in \
          "$HOME/.local/state/mero-headroom/proxy-${mode}-${port}.log" \
          "$HOME/.local/state/mero-headroom/proxy-${port}.log"; do
          [ -f "$log_file" ] || continue
          failure="$(command rg -i -S 'WS /v1/responses .*compression (failed|timed out)|WS /v1/responses .*failed; forwarding original' "$log_file" 2>/dev/null | command tail -n 1)"
          [ -n "$failure" ] && break
        done
        if [ -n "$failure" ]; then
          printf '  latest failure: %s\n' "$(printf '%s\n' "$failure" | command sed -E 's/^\[[^]]+\] //')"
        else
          printf '%s\n' '  failure diagnosis: no matching proxy log entry; Headroom exposes only an aggregate counter after the event.'
        fi
      fi
    done

    [ "$found" -eq 1 ] || printf '%s\n' 'No reachable Headroom proxy on ports 18994, 18996, or 18995.'
    return
  fi
  command codex-headroom "$@"
}

codexh() {
  if [ "${1:-}" = "savings" ]; then
    shift
    command /home/zacmero/projects/mero-headroom/scripts/codexh-savings "$@"
    return
  fi
  command codex-headroom "$@"
}
