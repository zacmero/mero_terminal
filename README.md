# Mero Terminal

This repository contains my personal dotfiles for a portable desktop environment.

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/zacmero/mero_terminal.git ~/dotfiles
    ```

2.  **Run the installation script:**

    ```bash
    cd ~/dotfiles
    ./install.sh
    ```

## Symlinking

These dotfiles are meant to be symlinked from your home directory. This allows you to keep your configurations in a version-controlled repository while the system can still find them in their expected locations.

To create the symbolic links, you can use the following script. It will back up any existing dotfiles to a `~/dotfiles_backup` directory and then create the necessary symlinks.

```bash
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
```

### How to use the script

1.  Save the script as `symlink.sh` in your `~/dotfiles` directory.
2.  Make the script executable:

    ```bash
    chmod +x symlink.sh
    ```

3.  Run the script:

    ```bash
    ./symlink.sh
    ```
