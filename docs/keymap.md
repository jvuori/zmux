# zmux Keymap Reference

This keymap matches Zellij's default keybindings as closely as possible.

## Lock Mode (`Ctrl+g`)

Lock mode is zmux's implementation of Zellij's lock mode. When enabled, all keyboard input goes directly to the application without being intercepted by tmux.

### Activation

| Key      | Action                                                               |
| -------- | -------------------------------------------------------------------- |
| `Ctrl+g` | Toggle lock mode ON (visual indicator 🔒 LOCK appears in status bar) |

### Behavior When Locked

- ✅ All keyboard input goes directly to the application
- ✅ No tmux keybindings are active (Ctrl+p, Ctrl+n, etc. go to the app)
- ✅ Only `Ctrl+g` works to toggle lock mode OFF
- ✅ Perfect for applications that need Ctrl+\* keybindings:
  - `Ctrl+p` for fzf (find files/history)
  - `Ctrl+s` for vim/neovim search
  - `Ctrl+l` for lazygit
  - `Ctrl+p` for neovim Telescope plugin
  - And many others

### Use Case Example

You want to use fzf with `Ctrl+p`:

1. Press `Ctrl+g` to enable lock mode (status bar shows 🔒 LOCK)
2. Now `Ctrl+p` goes to fzf instead of triggering pane mode
3. Use fzf to find and open files
4. Press `Ctrl+g` again to disable lock mode and restore tmux keybindings

## Lock Key (Legacy - now Ctrl+g)

## Mode Activation

Zellij uses direct key combinations (no prefix needed):

| Mode        | Activation | Description                                  |
| ----------- | ---------- | -------------------------------------------- |
| **Pane**    | `Ctrl+p`   | Manage panes (split, close, navigate)        |
| **Resize**  | `Ctrl+n`   | Resize panes with arrow keys                 |
| **Move**    | `Ctrl+h`   | Move/reorder panes                           |
| **Tab**     | `Ctrl+t`   | Manage tabs/windows (create, switch, rename) |
| **Scroll**  | `Ctrl+s`   | Scroll and copy mode                         |
| **Session** | `Ctrl+o`   | Session management                           |

## Pane Mode (`Ctrl+p`)

| Key      | Action                                                        |
| -------- | ------------------------------------------------------------- |
| `h` `←`  | Move focus left                                               |
| `l` `→`  | Move focus right                                              |
| `j` `↓`  | Move focus down                                               |
| `k` `↑`  | Move focus up                                                 |
| `p`      | Switch focus (toggle between panes)                           |
| `n`      | Create new pane (smart: horizontal if wide, vertical if tall) |
| `d`      | Create new pane down                                          |
| `r`      | Create new pane right                                         |
| `s`      | Create new pane stacked                                       |
| `x`      | Close focused pane                                            |
| `f`      | Toggle fullscreen                                             |
| `z`      | Toggle pane frames                                            |
| `w`      | Toggle floating panes (not available in tmux)                 |
| `e`      | Toggle embed/floating (not available in tmux)                 |
| `c`      | Rename pane                                                   |
| `i`      | Toggle pane pinned (not available in tmux)                    |
| `Ctrl+p` | Exit pane mode                                                |

## Resize Mode (`Ctrl+n`)

| Key      | Action                  |
| -------- | ----------------------- |
| `←` `h`  | Resize left (increase)  |
| `→` `l`  | Resize right (increase) |
| `↑` `k`  | Resize up (increase)    |
| `↓` `j`  | Resize down (increase)  |
| `H`      | Resize left (decrease)  |
| `J`      | Resize down (decrease)  |
| `K`      | Resize up (decrease)    |
| `L`      | Resize right (decrease) |
| `=` `+`  | Increase all dimensions |
| `-`      | Decrease all dimensions |
| `Ctrl+n` | Exit resize mode        |

## Move Mode (`Ctrl+h`)

| Key       | Action                     |
| --------- | -------------------------- |
| `←` `h`   | Move pane left             |
| `→` `l`   | Move pane right            |
| `↑` `k`   | Move pane up               |
| `↓` `j`   | Move pane down             |
| `n` `Tab` | Move pane to next position |
| `p`       | Move pane backwards        |
| `Ctrl+h`  | Exit move mode             |

## Tab Mode (`Ctrl+t`)

| Key             | Action                    |
| --------------- | ------------------------- |
| `←` `h` `↑` `k` | Previous tab              |
| `→` `l` `↓` `j` | Next tab                  |
| `n`             | Create new tab            |
| `x`             | Close current tab         |
| `r`             | Rename current tab        |
| `s`             | Toggle active sync tab    |
| `b`             | Break pane into new tab   |
| `]`             | Break pane right          |
| `[`             | Break pane left           |
| `1-9`           | Switch to tab number      |
| `Tab`           | Toggle to last active tab |
| `Ctrl+t`        | Exit tab mode             |

## Scroll Mode (`Ctrl+s`)

| Key                         | Action                    |
| --------------------------- | ------------------------- |
| `s`                         | Enter search mode         |
| `↑` `k`                     | Scroll up                 |
| `↓` `j`                     | Scroll down               |
| `Ctrl+f` `PageDown` `→` `l` | Page down                 |
| `Ctrl+b` `PageUp` `←` `h`   | Page up                   |
| `d`                         | Half page down            |
| `u`                         | Half page up              |
| `Ctrl+c`                    | Scroll to bottom and exit |
| `Ctrl+s`                    | Exit scroll mode          |

## Session Mode (`Ctrl+o`)

| Key      | Action                                  |
| -------- | --------------------------------------- |
| `n`      | Create new session (prompts for name)   |
| `r`      | Rename current session                  |
| `w`      | Session manager (tmux-fzf session list) |
| `d`      | Detach from session                     |
| `c`      | Show configuration info                 |
| `p`      | Show plugin info                        |
| `a`      | Show about info                         |
| `s`      | Share (not available in tmux)           |
| `q`      | Sequence (not available in tmux)        |
| `Ctrl+s` | Enter scroll mode                       |
| `Ctrl+o` | Exit session mode                       |

## Shared Keybindings

These work in all modes (except locked):

| Key             | Action                   |
| --------------- | ------------------------ |
| `Ctrl+a`        | Lock session             |
| `Ctrl+q`        | Quit (kill all sessions) |
| `Alt+f`         | Toggle pane frames       |
| `Alt+n`         | Create new pane          |
| `Alt+i`         | Move tab left            |
| `Alt+o`         | Move tab right           |
| `Alt+h` `Alt+←` | Move focus/tab left      |
| `Alt+l` `Alt+→` | Move focus/tab right     |
| `Alt+j` `Alt+↓` | Move focus down          |
| `Alt+k` `Alt+↑` | Move focus up            |
| `Alt+=` `Alt++` | Resize increase          |
| `Alt+-`         | Resize decrease          |
| `Alt+[`         | Previous swap layout     |
| `Alt+]`         | Next swap layout         |
| `Alt+p`         | Toggle pane in group     |
| `Alt+Shift+p`   | Toggle group marking     |

## Copy Mode

When in copy mode (entered via scroll mode):

| Key | Action                     |
| --- | -------------------------- |
| `v` | Begin selection            |
| `y` | Copy selection and exit    |
| `r` | Toggle rectangle selection |

## Custom Keybindings (Not in Zellij)

These are zmux-specific utilities:

| Key        | Action                         |
| ---------- | ------------------------------ |
| `Ctrl+a r` | Reload configuration           |
| `Ctrl+a s` | Session switcher (interactive) |

## Plugin Keybindings

### tmux-resurrect

- `Ctrl+a Ctrl+s` - Save session state
- `Ctrl+a Ctrl+r` - Restore session state

### tmux-fzf (if installed)

- `Ctrl+a s` - Interactive session switcher
- `Ctrl+a w` - Interactive window switcher
- `Ctrl+a p` - Interactive pane switcher
- `Ctrl+a i` - Install plugins (TPM)
- `Ctrl+a u` - Update plugins (TPM)

Note: These may conflict with Zellij keybindings. The session switcher (`Ctrl+a s`) uses a custom script that tries tmux-fzf first, then falls back to a simple switcher.

## Tips

1. **Direct key combinations**: Unlike traditional tmux, zmux uses direct `Ctrl+key` combinations (like Zellij), not a prefix system
2. **Mode-based workflow**: Enter a mode with `Ctrl+key`, perform actions, then exit with the same `Ctrl+key` or `Escape`
3. **Arrow keys work**: Arrow keys work in most modes for navigation/resizing
4. **Consistent navigation**: hjkl and arrow keys work consistently across modes
5. **Session switching**: Use `Ctrl+a s` for interactive session selection (requires fzf for best experience)

## Differences from Standard tmux

- **No prefix required**: Modes are activated directly with `Ctrl+key`
- **Mode exit**: Press the same `Ctrl+key` again or `Escape` to exit modes
- **Zellij-like behavior**: Keybindings match Zellij's defaults as closely as possible
