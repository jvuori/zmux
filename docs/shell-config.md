# Shell Configuration for zmux

zmux uses `Ctrl+p`, `Ctrl+n`, `Ctrl+h`, `Ctrl+t`, `Ctrl+s`, and `Ctrl+o` as direct keybindings (like Zellij). However, these keys are often used by your shell (bash/zsh) for command history and editing, which can prevent tmux from intercepting them.

## The Problem

When you're typing in a shell inside tmux, the shell's readline library intercepts these key combinations before tmux can handle them:
- `Ctrl+p` - Previous command (readline)
- `Ctrl+n` - Next command (readline)
- `Ctrl+h` - Backspace (readline)
- `Ctrl+s` - Flow control (terminal)
- `Ctrl+g` - Abort (readline)

## Solutions

### Option 1: Automatic Setup (Recommended)

Run the setup script:

```bash
./setup-shell.sh
```

This will:
1. Create `~/.config/zmux/shell-config` with the necessary configuration
2. Add a source line to your `~/.bashrc` or `~/.zshrc`:
   ```bash
   [ -f ~/.config/zmux/shell-config ] && source ~/.config/zmux/shell-config  # zmux shell config
   ```

**To disable zmux keybindings:**
Simply comment out the source line in your `~/.bashrc` or `~/.zshrc`:
```bash
# [ -f ~/.config/zmux/shell-config ] && source ~/.config/zmux/shell-config  # zmux shell config
```

**To re-enable:**
Uncomment the line.

After adding, reload your shell config:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### Option 2: Manual Setup

If you prefer to add the configuration directly to your `~/.bashrc` or `~/.zshrc`:

**For Bash:**
```bash
# Disable readline shortcuts that conflict with zmux
# Only disable when inside tmux
if [ -n "$TMUX" ]; then
    bind '"\C-p": ""'
    bind '"\C-n": ""'
    bind '"\C-h": ""'
    bind '"\C-g": ""'
    # Use Alt+Arrow for history instead
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi
```

**For Zsh:**
```zsh
# Disable readline shortcuts that conflict with zmux
# Only disable when inside tmux
if [ -n "$TMUX" ]; then
    bindkey -r '^P'
    bindkey -r '^N'
    bindkey -r '^H'
    bindkey -r '^G'
    # Use Alt+Arrow for history instead
    bindkey '^[[A' history-search-backward
    bindkey '^[[B' history-search-forward
fi
```

### Option 2: Use Alternative Keys

If you prefer to keep your shell shortcuts, you can modify zmux to use different keys. Edit `~/.config/tmux/keybindings.conf` and change:

```bash
# Change from Ctrl+p to Ctrl+Space+p (or another combination)
bind -n C-Space switch-client -T pane
```

### Option 3: Use Prefix Mode (Traditional tmux)

If you prefer the traditional tmux approach, you can use prefix mode instead of direct keybindings. This requires pressing a prefix key first (like `Ctrl+g`), then the mode key.

## Verification

After configuring your shell:

1. **Reload your shell config:**
   ```bash
   source ~/.bashrc  # or source ~/.zshrc
   ```

2. **Reload tmux config:**
   - Press your current prefix (probably `Ctrl+b`)
   - Type: `:source-file ~/.tmux.conf`

3. **Test the keybindings:**
   - `Ctrl+p` should enter pane mode (not show previous command)
   - `Ctrl+n` should enter resize mode (not show next command)
   - `Ctrl+g` should lock/unlock (not abort)

## Alternative: Use Escape Sequences

Some terminals support escape sequences that work better. You can configure tmux to use these, but it requires terminal-specific configuration.

## Notes

- These changes only apply when you're inside a tmux session (`$TMUX` is set)
- Outside tmux, your normal shell shortcuts will still work
- You can still use `Alt+Arrow` or `Up/Down` arrows for command history

