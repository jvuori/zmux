# Rules

## Installation Script Completeness

When tmux config files source other config files (e.g., `keybindings.conf` sources `lock-mode-bindings.conf`), ensure **all sourced files are copied during installation and updates**. Missing sourced files will cause "No such file or directory" errors on startup.

**Action**: Always check that both `install.sh` and `update.sh` copy all configuration files that are referenced via `source-file` directives.

## Script File Completeness

All scripts in the `scripts/` directory that are used by keybindings, systemd service, or other components must be copied during installation and updates.

**Critical scripts that must be copied**:

- `systemd-tmux-start.sh` - Used by XDG autostart
- `tmux-start.sh` - Used by WezTerm/terminal emulators
- `swap-pane-left.sh`, `swap-pane-right.sh` - Used by move mode keybindings
- `lock-mode-indicator.sh`, `toggle-lock-mode.sh` - Used by lock mode
- All other helper scripts referenced in keybindings.conf

## CRITICAL: Avoid Hardcoded Paths

**NEVER** use absolute paths like `/home/username/...` in ANY files. This is a critical portability issue.

### Configuration Files and Scripts

Always use:

- `~` or `$HOME` for home directory references
- Relative paths from `~/.config/tmux/` where appropriate

### Desktop Entry Files (.desktop)

For XDG autostart desktop files, paths in `Exec=` must use one of these methods:

1. **Wrap with shell expansion** (PREFERRED):

   ```ini
   Exec=sh -c "$HOME/.config/tmux/scripts/systemd-tmux-start.sh"
   ```

2. **Use tilde expansion** (if supported):
   ```ini
   Exec=~/.config/tmux/scripts/systemd-tmux-start.sh
   ```

**NEVER** use:

```ini
Exec=/home/username/.config/tmux/scripts/systemd-tmux-start.sh  # ❌ WRONG
```

### Test Files

Test scripts must also use portable paths:

- Use `$HOME` instead of `/home/username`
- Use `$PWD` or `$(pwd)` for current directory
- Example: `tmux new-session -d -s "$TEST_SESSION" -c "$HOME"`

### Documentation

When writing documentation or examples:

- Use `~/.config/...` or `$HOME/.config/...` in examples
- Never include actual usernames in path examples
- If showing output, sanitize usernames to `$USER` or generic placeholders

### Verification

Before committing any file creation or modification:

1. Search for hardcoded home directories: `grep -r "/home/[^/]*/" --include="*.sh" --include="*.desktop" --include="*.conf"`
2. Check all generated files (especially .desktop files from heredocs)
3. Verify variables are properly escaped in heredocs (use single quotes for literal heredocs when needed)
