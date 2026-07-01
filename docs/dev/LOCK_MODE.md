# 🔒 Lock Mode - Quick Reference

## What is Lock Mode?

Lock mode allows applications running in tmux to receive all keyboard input, solving the problem where tmux keybindings conflict with your application's keybindings.

## Quick Start

```
Press Ctrl+g to toggle lock mode
↓
See 🔒 LOCK in status bar
↓
Now your app's keybindings work (Ctrl+p, Ctrl+n, etc.)
↓
Press Ctrl+g again to toggle lock mode off
```

## Real-World Examples

**Using fzf's Ctrl+p:**
```
Ctrl+g          → Lock mode ON
Ctrl+p          → fzf opens (instead of tmux pane mode)
<select a file>
Ctrl+g          → Lock mode OFF, back to tmux
```

**Using vim's Ctrl+p completion:**
```
Ctrl+g          → Lock mode ON  
Ctrl+p          → Vim shows word completion
<select word>
Ctrl+g          → Lock mode OFF
```

## Key Facts

| Feature | Details |
|---------|---------|
| **Toggle Key** | `Ctrl+g` |
| **Visual Indicator** | 🔒 LOCK in status bar |
| **When Locked** | All keyboard goes to application |
| **Only Key That Works** | `Ctrl+g` (to unlock) |
| **Perfect For** | fzf, vim, neovim, lazygit, etc. |

## Why This Matters

Without lock mode:
- `Ctrl+p` → tmux pane mode (fzf doesn't see it)
- `Ctrl+s` → tmux scroll mode (vim search doesn't work)
- `Ctrl+n` → tmux resize mode (application can't use it)

With lock mode:
- `Ctrl+p` → goes to your application
- `Ctrl+s` → goes to your application  
- `Ctrl+n` → goes to your application

## See Also

- Full documentation: [docs/lock-mode.md](docs/lock-mode.md)
- Complete keymap: [docs/keymap.md](docs/keymap.md)
- Implementation: [scripts/toggle-lock-mode.sh](scripts/toggle-lock-mode.sh)
