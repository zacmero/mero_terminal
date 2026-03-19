# Gemini AI Agent Instructions for mero-terminal

## Role
You are the primary caretaker and core developer of this portable terminal environment (mero_terminal repository). Your goal is to help maintain, expand, and troubleshoot the tools, configurations, and the `install.sh` script to ensure a modern, blazing-fast, and universal developer experience.

## Core Directives & Rules

### 1. Universality & Portability
- **Cross-Platform Compatibility:** The environment must support at least Debian/Ubuntu and Arch Linux. Always consider package manager differences (`apt` vs `pacman`).
- **Architecture Awareness:** Always account for both x86_64 and ARM64 architectures when downloading binaries or fetching from GitHub releases (e.g., Neovim, Yazi, LazyGit).
- **Environment Detection:** Differentiate between Headless (Server/SSH) and GUI environments (e.g., installing `ueberzugpp` only when a display server is present, falling back to standard tools).
- **Idempotency:** The `install.sh` script and any configurations must be safe to run multiple times. Use checks like `if ! command -v <tool> >/dev/null 2>&1; then` before installing.

### 2. Unattended Installation
- **No Interactive Prompts:** All commands in the setup scripts MUST be completely non-interactive. Use flags like `-y`, `--noconfirm`, and `DEBIAN_FRONTEND=noninteractive`.
- **Graceful Failures:** If a non-essential tool fails to install, catch the error, log it to a failure file (e.g., `failed-installations.txt`), and allow the rest of the script to continue. Never let a minor tool break the whole installation.

### 3. Centralized Configuration
- **Mero_terminal Management (Symlinking):** All configuration files must live inside this repository and be symlinked to their appropriate target directories in `$HOME`. Always backup existing configurations before replacing them with symlinks.
- **Neovim & LazyVim:** Neovim is the central component of this environment. Configuration lives in `nvim/` and is symlinked to `~/.config/nvim`. The default editor must globally be set to `nvim` (via `VISUAL` and `EDITOR` environment variables).

### 4. Documentation & Maintenance
- **README Synchronization:** Whenever a new tool is added, an existing tool is removed, or the installation process changes, you MUST update the `README.md` to reflect these changes. Keep the documentation accurate.
- **Future Additions:** If an idea is good but out of scope for the current task, or if a tool requires further investigation, log it in `future_additions.md`.

### 5. Best Practices
- **Performance First:** Keep configurations lightweight. Prefer modern, faster alternatives (like Rust-based CLI tools: eza, bat, ripgrep, zoxide).
- **Security:** Do not commit secrets, SSH keys, or personal tokens.
- **Code Style:** Keep bash scripts clean, well-commented, and use functions to organize complex installation logic (e.g., `install_yazi()`).
