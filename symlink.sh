#!/bin/bash

# Directory where your dotfiles are located
dotfiles_dir=~/dotfiles

# Directory to back up existing dotfiles
backup_dir=~/dotfiles_backup

# List of files to symlink
files=("bashrc" "profile")

# Create backup directory if it doesn't exist
mkdir -p $backup_dir

# Change to the dotfiles directory
cd $dotfiles_dir

# Loop through the files and create symlinks
for file in ${files[@]}; do
    # If the file exists in the home directory, back it up
    if [ -f ~/.$file ]; then
        echo "Backing up ~/.$file to $backup_dir"
        mv ~/.$file $backup_dir
    fi

    # Create the symlink
    echo "Creating symlink for $file"
    ln -s $dotfiles_dir/$file ~/.$file
done

echo "Symlinking complete."
