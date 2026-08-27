# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# Set default editor to Neovim
export VISUAL="nvim"
export EDITOR="$VISUAL"
if command -v wezterm >/dev/null 2>&1; then
    export TERMINAL="wezterm"
fi

# pi-node PATH (for pi coding agent)
export PATH="$HOME/.local/share/pi-node/current/bin:$PATH"


# Ensure ~/.local/bin is in PATH for all login shells
export PATH="$HOME/.local/bin:$PATH"

