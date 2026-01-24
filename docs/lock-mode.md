# Lock Mode - Application Input Pass-Through

Lock mode is zmux's implementation of Zellij's "Lock mode" feature. It allows you to temporarily disable all tmux keybindings so that keyboard input passes directly to your application.

## The Problem Lock Mode Solves

Many applications have their own keybindings that conflict with tmux:

- **fzf**: Uses `Ctrl+p` to find files, `Ctrl+n` to navigate down
- **vim/neovim**: Uses `Ctrl+p` for completion, `Ctrl+s` for search
- **lazygit**: Uses `Ctrl+l` for toggle logs, `Ctrl+h` for help
- **Neovim with Telescope**: Uses `Ctrl+p` to open fuzzy finder
- **Many CLI tools**: Use `Ctrl+` combinations for features

Without lock mode, tmux intercepts these keys before your application sees them. For example:

- You press `Ctrl+p` in vim expecting it to trigger word completion
- Instead, tmux enters **pane mode** and your app never sees the keystroke
- Result: 😞 Application keybindings don't work

## How Lock Mode Works

### Activation

Press `Ctrl+g` to toggle lock mode:

```
Normal Mode ←→ Lock Mode (Ctrl+g)
```

### Visual Indicator

When lock mode is active, the status bar shows:

```
🖥️  session-name 🔒 LOCK
```

### Behavior

**When Lock Mode is OFF (Normal):**

- ✅ All tmux keybindings work: `Ctrl+p`, `Ctrl+n`, `Ctrl+h`, `Ctrl+t`, `Ctrl+s`, `Ctrl+o`
- ❌ Application keybindings that conflict with tmux don't work
- ✅ You can use tmux features normally

**When Lock Mode is ON:**

- ❌ Tmux keybindings are disabled: `Ctrl+p`, `Ctrl+n`, `Ctrl+h`, `Ctrl+t`, `Ctrl+s`, `Ctrl+o` are NOT active
- ✅ All keyboard input goes directly to your application
- ✅ You can use all application keybindings
- ✅ Only `Ctrl+g` works to toggle lock mode off
- ⚠️ You cannot use tmux features while locked

## Use Cases

### Use Case 1: Using fzf with Ctrl+p

```bash
# In a normal shell with fzf installed
# Try to open fzf with Ctrl+p

# Without lock mode:
Ctrl+p  → tmux enters pane mode (fzf doesn't activate)

# With lock mode:
Ctrl+g  → Enable lock mode
Ctrl+p  → fzf opens and searches
<pick a file>
Ctrl+g  → Disable lock mode, back to normal tmux
```

### Use Case 2: Vim/Neovim Completion

```bash
# In vim inside a tmux pane
# Using Ctrl+p for word completion

# Without lock mode:
Ctrl+p  → tmux enters pane mode (vim doesn't get completion)

# With lock mode:
Ctrl+g  → Enable lock mode
Ctrl+p  → vim shows word completion menu
<select completion>
Ctrl+g  → Disable lock mode
```

### Use Case 3: Neovim with Telescope

```bash
# In neovim with telescope plugin
# Using Ctrl+p to open file picker

# Without lock mode:
Ctrl+p  → tmux enters pane mode (telescope doesn't open)

# With lock mode:
Ctrl+g     → Enable lock mode
Ctrl+p     → Telescope fuzzy finder opens
<find and open file>
Ctrl+g     → Disable lock mode
```

### Use Case 4: lazygit in a tmux Pane

```bash
# Running lazygit inside tmux
# lazygit uses many Ctrl+* keybindings

# Without lock mode:
Most lazygit keybindings don't work because tmux intercepts them

# With lock mode:
Ctrl+g     → Enable lock mode (now you're in the lazygit world)
<use all lazygit keybindings normally>
Ctrl+g     → Disable lock mode (back to tmux world)
```

## Implementation Details

### Files Involved

- **Script**: `~/.config/tmux/scripts/toggle-lock-mode.sh` - Toggles lock mode state
- **Config**: `~/.config/tmux/keybindings.conf` - Defines `Ctrl+g` binding
- **Status**: `~/.config/tmux/statusbar.conf` - Shows 🔒 LOCK indicator

### How It Works Internally

1. **State Tracking**: Uses a tmux session variable `@lock_mode` to track state (0=unlocked, 1=locked)
2. **Key Table Switching**: When locked, switches to a special `locked` key table
3. **Locked Table**: Only has `Ctrl+g` bound; all other keys pass through
4. **Status Bar**: Shows lock indicator by checking the `@lock_mode` variable

### Technical Design

```
User presses Ctrl+g
        ↓
toggle-lock-mode.sh script runs
        ↓
Check @lock_mode session variable
        ↓
If unlocked (0):
  - Set @lock_mode=1
  - Switch to locked key table
  - Display "Locked" message
        ↓
If locked (1):
  - Set @lock_mode=0
  - Switch to root key table
  - Display "Unlocked" message
        ↓
Visual indicator updates in status bar
```

## Troubleshooting

### Lock Mode Doesn't Toggle

**Problem**: Pressing `Ctrl+g` doesn't toggle lock mode

**Solutions**:

1. Check that the toggle script exists: `ls -l ~/.config/tmux/scripts/toggle-lock-mode.sh`
2. Verify the keybinding: `tmux list-keys | grep "C-g"`
3. Reload config: `tmux source-file ~/.tmux.conf`

### Lock Mode Indicator Doesn't Show

**Problem**: Status bar doesn't show 🔒 LOCK when locked

**Solutions**:

1. Ensure status bar is visible: `tmux show-options | grep status-position`
2. Check status bar config: `grep @lock_mode ~/.config/tmux/statusbar.conf`
3. Status bar may take a moment to update; wait 1 second

### Still Can't Use Application Keybindings

**Problem**: Keybindings still don't work even with lock mode on

**Solutions**:

1. Verify you pressed `Ctrl+g` and see the 🔒 LOCK indicator
2. Make sure the application actually supports that keybinding
3. Some terminal configurations may still intercept keys (e.g., iTerm2 key mappings)
4. Try a simpler keybinding first (e.g., `Ctrl+l`) to verify lock mode is working

### Accidentally Locked, Need to Unlock

**Solution**: Press `Ctrl+g` to toggle lock mode off (this is the only keybinding that works in locked mode)

## Comparison with Zellij

| Feature                        | Lock Mode | Zellij Lock Mode   |
| ------------------------------ | --------- | ------------------ |
| Activation key                 | `Ctrl+g`  | `Ctrl+g` (default) |
| Visual indicator               | 🔒 LOCK   | LOCK (text)        |
| Application input pass-through | ✅ Yes    | ✅ Yes             |
| Toggle key works when locked   | ✅ Yes    | ✅ Yes             |
| Status bar indication          | ✅ Yes    | ✅ Yes             |

## Tips & Tricks

### Quick Toggle in Muscle Memory

After using lock mode for a while, `Ctrl+g` becomes automatic:

- Working with an application that needs keybindings? `Ctrl+g`
- Done? `Ctrl+g` again
- It becomes as natural as switching between modes in vim

### Combining with Other Modes

You can still use lock mode with other tmux features:

- Lock mode doesn't affect mouse support
- You can still click panes/tabs with mouse
- Use lock mode only when you specifically need app keybindings

### Creating Custom Lock-Friendly Workflows

Many users create scripts that automatically enable lock mode for specific apps:

```bash
# Example: Open fzf with automatic lock mode
fzf-lock() {
    tmux send-keys -t $TMUX_PANE C-g  # Enable lock
    fzf "$@"
    tmux send-keys -t $TMUX_PANE C-g  # Disable lock
}
```

## See Also

- [Complete Keymap Reference](keymap.md)
- [Philosophy Behind zmux Design](philosophy.md)
- [Differences vs Zellij](differences-vs-zellij.md)
