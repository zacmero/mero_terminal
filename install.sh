#!/bin/bash

# This script installs the tools and extensions found in the bashrc file.

# Update package lists
sudo apt-get update

# Install essential build tools
sudo apt-get install -y build-essential

# Install lesspipe
sudo apt-get install -y lesspipe

# Install nvm (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -

# Install bun
curl -fsSL https://bun.sh/install | bash

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Install zoxide
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash

# Install fzf
sudo apt-get install -y fzf

# Install atuin
bash <(curl https://raw.githubusercontent.com/ellie/atuin/main/install.sh)

# Install fastfetch
sudo apt-get install -y fastfetch

# Install trash-cli
sudo apt-get install -y trash-cli

# Install bat (as batcat)
sudo apt-get install -y bat

# Install neovim
sudo apt-get install -y neovim

echo "All tools and extensions have been installed."
