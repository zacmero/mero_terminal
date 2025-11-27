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

# Install neovim (latest stable)
echo "Installing Neovim..."
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim
sudo tar -C /opt -xzf nvim-linux64.tar.gz
rm nvim-linux64.tar.gz
# Symlink nvim
if [ -f /usr/local/bin/nvim ]; then
    sudo rm /usr/local/bin/nvim
fi
sudo ln -s /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim

# Install LazyVim
echo "Installing LazyVim..."
if [ -d "$HOME/.config/nvim" ]; then
    BACKUP_DIR="$HOME/.config/nvim.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backing up existing nvim config to $BACKUP_DIR"
    mv "$HOME/.config/nvim" "$BACKUP_DIR"
fi
git clone https://github.com/LazyVim/starter "$HOME/.config/nvim"

# Install eza
echo "Installing eza..."
EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
curl -L -o eza.tar.gz "$EZA_URL"
tar -xzf eza.tar.gz
sudo mv eza /usr/local/bin/eza
rm eza.tar.gz

# Install broot
echo "Installing broot..."
curl -L -o broot https://dystroy.org/broot/download/x86_64-linux/broot
chmod +x broot
sudo mv broot /usr/local/bin/broot

echo "All tools and extensions have been installed."
