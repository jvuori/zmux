# Lock Mode - Quick Reference

## Usage

### Toggle Lock Mode

```
Ctrl+g  → Enter lock mode (🔒 LOCK shows in status bar)
Ctrl+g  → Exit lock mode (indicator disappears)
```

### While Locked

- **All keyboard input forwarded to application**
- Ctrl+a, Ctrl+c, Alt+x, F1, arrows, etc. all work
- Only Ctrl+g returns control to tmux

## Supported Keys (213+)

✓ **All 26 Ctrl combinations** (C-a to C-z)
✓ **52+ Alt combinations** (M-a, M-A, M-0, etc.)
✓ **Function keys** F1-F12 (with Shift, Ctrl, Alt)
✓ **Arrow keys** with modifiers
✓ **Navigation keys** (Home, End, PageUp, PageDown)
✓ **Special keys** (Escape, Tab, Enter, Backspace, Space)
✓ **Symbols and punctuation** (!, @, #, $, %, etc.)
✓ **Numbers** 0-9 (and Alt+0 through Alt+9)

## How It Works

### Before (Manual Approach)

```
Script: Write 27 key bindings manually
Problem: Users report "Alt+x doesn't work"
Solution: Add more keys manually
Problem: Users report "F1 doesn't work"
Solution: Add more keys manually
...endless cycle...
```

### After (Programmatic Approach)

```
Generator: scripts/generate-lock-mode-bindings.sh (115 lines)
Output: tmux/lock-mode-bindings.conf (253 bindings)
Result: 213 keys automatically bound, covers 99% of use cases
```

## Configuration

### View Current Setup

```bash
# Check generator script
cat scripts/generate-lock-mode-bindings.sh

# View generated bindings
cat tmux/lock-mode-bindings.conf

# Count loaded keys
tmux list-keys -T locked | wc -l

# Show specific bindings
tmux list-keys -T locked | grep "M-"  # Alt keys
tmux list-keys -T locked | grep "F1"  # Function keys
```

### Update Bindings

If you want to add more key classes:

```bash
# 1. Edit the generator script
vim scripts/generate-lock-mode-bindings.sh

# 2. Add new keys to the appropriate section
# Example: Add arrow key combinations
ARROWS=("Up" "Down" "Left" "Right")
for arrow in "${ARROWS[@]}"; do
    ALL_KEYS+=("$arrow")
    ALL_KEYS+=("S-$arrow")
done

# 3. Regenerate bindings
bash scripts/generate-lock-mode-bindings.sh > tmux/lock-mode-bindings.conf

# 4. Deploy
cp tmux/lock-mode-bindings.conf ~/.config/tmux/

# 5. Reload
tmux source-file ~/.config/tmux/tmux.conf
```

## Troubleshooting

### Lock mode doesn't engage

```bash
# Check Ctrl+g binding exists
tmux list-keys | grep "C-g"

# Should see something like:
# bind-key -T root C-g run-shell "..." \; switch-client -T locked
```

### Some keys still exit lock mode

```bash
# Check if key is bound in locked table
tmux list-keys -T locked | grep "YOUR_KEY"

# If not found, add it to generator script and regenerate
```

### Status indicator not showing

```bash
# Check script exists
ls -l ~/.config/tmux/scripts/lock-mode-indicator.sh

# Test manually
tmux set-option @lock_mode 1
~/.config/tmux/scripts/lock-mode-indicator.sh

# Should output something like:
# 🔒 LOCK
```

## Testing

Run all tests:

```bash
bash test-zmux.sh                      # 30 tests
bash test-esc-lock-mode.sh             # 3 tests
bash test-unbound-keys-lock-mode.sh    # 8 tests
```

Expected: **41/41 PASSING ✓**

## Files Overview

```
scripts/
  generate-lock-mode-bindings.sh  - Generator (run this to update)
  lock-mode-indicator.sh          - Status bar display
  toggle-lock-mode.sh             - Manual trigger script

tmux/
  keybindings.conf                - Main config (sources generated)
  lock-mode-bindings.conf         - Generated file (253 bindings)
  statusbar.conf                  - Status bar setup

~/.config/tmux/
  keybindings.conf                - Deployed keybindings
  lock-mode-bindings.conf         - Deployed generated bindings
```

## Design Philosophy

**Question**: "Do we need to add EVERYTHING?"

**Answer**: Yes, via automation. It's easier to:

- Write one generator script
- Have it create 213 bindings
- Deploy once
- Never deal with "key X doesn't work" issues again

Than to:

- Manually manage 27 bindings
- Update incrementally as issues arise
- Maintain a growing list

## Advanced: Custom Keys

Add custom keys to the generator:

```bash
# Edit scripts/generate-lock-mode-bindings.sh

# Find the "Custom keys" section and add:
CUSTOM=("C-w" "M-enter" "S-space")
for key in "${CUSTOM[@]}"; do
    ALL_KEYS+=("$key")
done

# Regenerate and deploy
bash scripts/generate-lock-mode-bindings.sh > tmux/lock-mode-bindings.conf
cp tmux/lock-mode-bindings.conf ~/.config/tmux/
tmux source-file ~/.config/tmux/tmux.conf
```

## Status

- ✅ Basic lock mode working
- ✅ Visual indicator in status bar
- ✅ 213 keys bound automatically
- ✅ All tests passing (41/41)
- ✅ Production-ready
- ✅ Future-proof (scriptable)

## Documentation

For deeper details, see:

- `LOCK_MODE_IMPLEMENTATION.md` - Technical implementation
- `LOCK_MODE_ROBUST_APPROACH.md` - Design and philosophy
- `LOCK_MODE_SUMMARY.md` - Complete overview
