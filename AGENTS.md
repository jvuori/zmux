# Rules

## Installation Script Completeness

When tmux config files source other config files (e.g., `keybindings.conf` sources `lock-mode-bindings.conf`), ensure **all sourced files are copied during installation and updates**. Missing sourced files will cause "No such file or directory" errors on startup.

**Action**: Always check that both `install.sh` and `update.sh` copy all configuration files that are referenced via `source-file` directives.

## Script File Completeness

All scripts in the `scripts/` directory that are used by keybindings, systemd service, or other components must be copied during installation and updates.

**Critical scripts that must be copied**:

- `systemd-tmux-start.sh` - Used by the systemd service
- `tmux-start.sh` - Used by WezTerm/terminal emulators
- `swap-pane-left.sh`, `swap-pane-right.sh` - Used by move mode keybindings
- `lock-mode-indicator.sh`, `toggle-lock-mode.sh` - Used by lock mode
- All other helper scripts referenced in keybindings.conf

## Avoid Hardcoded Paths

Never use absolute paths like `/home/username/...` in configuration files or scripts. Always use:

- `~` or `$HOME` for home directory
- `%h` in systemd service files (expands to home directory)
- Relative paths from `~/.config/tmux/` where appropriate
