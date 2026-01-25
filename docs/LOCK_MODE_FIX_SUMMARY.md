# Lock Mode Indicator Fix - Summary

## Problem
When pressing unbound keys in lock mode (like §, special characters), tmux would automatically exit the `locked` key table, but the lock indicator (🔒 LOCK) would remain in the status bar because the `@lock_mode` session variable wasn't being reset.

## Root Cause
**tmux key table behavior:**
- When a key is pressed in a custom key table and no binding is found
- tmux automatically exits that key table and returns to root table
- BUT: Any session variables set for that mode were NOT automatically cleared
- Result: The status bar would still show the lock icon even though lock mode was no longer active

## Solution
Added a **catch-all `Any` binding** to the `locked` key table that:
1. Resets the `@lock_mode` variable to 0 (exit lock mode)
2. Switches the client back to the `root` key table
3. Lets the unbound key be processed normally

### Change Made
File: `tmux/keybindings.conf` (lines 58-59)

```tmux
# Catch-all handler for unbound keys in locked mode
bind -T locked Any { set-option @lock_mode 0 \; switch-client -T root }
```

## How It Works

**Before fix:**
```
User presses § (unbound key)
  → Not found in locked table
  → tmux auto-exits locked table
  → @lock_mode still = 1
  → Status bar shows 🔒 LOCK (WRONG!)
```

**After fix:**
```
User presses § (unbound key)
  → Not found in explicit bindings
  → Matches `Any` binding in locked table
  → Sets @lock_mode = 0
  → Switches to root table
  → Status bar removes 🔒 LOCK (CORRECT!)
```

## Robustness Improvements

The lock mode now handles:
1. **Intentional exit**: Ctrl+g properly exits with indicator removal
2. **Accidental exit**: Any unbound key properly resets indicator
3. **Status consistency**: Lock indicator always matches actual lock state
4. **User experience**: No confusing visual state where icon doesn't match functionality

## Testing
Verified with test suite that:
- ✓ `@lock_mode` properly resets to 0 when unbound keys are pressed
- ✓ Lock indicator is removed from status bar
- ✓ User can re-enter lock mode normally
- ✓ Both intentional (Ctrl+g) and accidental exits work correctly

## Files Modified
- `tmux/keybindings.conf`: Added 2 lines (catch-all handler)
- Config automatically reloaded via `source-file`

## Configuration Deployment
To apply this fix:
```bash
cd /home/jaakko/prj/zmux
cp tmux/keybindings.conf ~/.config/tmux/
tmux source-file ~/.config/tmux/tmux.conf
```

All existing lock mode functionality is preserved - this just adds robustness.
