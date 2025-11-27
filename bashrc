[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
*i*) ;;
*) return ;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
# HISTCONTROL=ignoreboth

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

#fzf folder navigation + lazyvin fast open:
alias v='fzf | xargs -r nvim'

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

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

export BROWSER=explorer.exe

# pnpm
export PNPM_HOME="/home/zacmero/.local/share/pnpm"
case ":$PATH:" in
*":$PNPM_HOME:"*) ;;
*) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
export PATH="$HOME/.bun/bin:$PATH"
eval "$(starship init bash)"
eval "$(zoxide init bash)"

# FZF Manual Setup (Corrected Path)
# Load FZF key bindings
if [ -f /usr/share/doc/fzf/examples/key-bindings.bash ]; then
  source /usr/share/doc/fzf/examples/key-bindings.bash
fi

# Load FZF auto-completion
if [ -f /usr/share/bash-completion/completions/fzf ]; then
  source /usr/share/bash-completion/completions/fzf
fi

export ATUIN_BIN_DIR="$HOME/.atuin/bin"
export PATH="$ATUIN_BIN_DIR:$PATH"
eval "$(atuin init bash)"

export PATH="/home/zacmero/.local/bin:$PATH"
fastfetch

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
  if [ -r /etc/os-release ]; then
    batcat /etc/os-release
  elif [ -r /etc/issue ]; then
    batcat /etc/issue
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

# Alias 'cat' to 'batcat' (the command for 'bat' on Ubuntu/Debian)
# This provides syntax highlighting and other features.
alias cat='batcat'

source /home/zacmero/.config/broot/launcher/bash/br

# opencode
export PATH=/home/zacmero/.opencode/bin:$PATH
