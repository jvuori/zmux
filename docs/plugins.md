# Plugins

zmux uses [TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm) to manage plugins. All plugins are declared in `~/.config/tmux/plugins.conf`.

## Installed plugins

### Session management

| Plugin | Purpose |
|--------|---------|
| **tmux-resurrect** | Save and restore sessions manually (`Ctrl+a Ctrl+s` / `Ctrl+a Ctrl+r`) |
| **tmux-continuum** | Auto-save sessions every 5 minutes; auto-restore on tmux start |

### Navigation & UX

| Plugin | Purpose |
|--------|---------|
| **tmux-sensible** | Sensible defaults (escape time, terminal settings, etc.) |
| **tmux-fzf** | Interactive fzf-based session/window/pane switcher (`Ctrl+o w`) |
| **tmux-pain-control** | Improved pane navigation and splitting |

### Clipboard & file handling

| Plugin | Purpose |
|--------|---------|
| **tmux-yank** | Copy to system clipboard from copy mode |
| **tmux-open** | Open files and URLs from copy mode |

### Status bar

| Plugin | Purpose |
|--------|---------|
| **tmux-prefix-highlight** | Shows an indicator in the status bar when the prefix key is active |
| **tmux-battery** | Battery percentage and graph in the status bar |

## Installing plugins

After a fresh install or after running `update.sh`, install plugins from inside tmux:

```
Ctrl+a  i    — install all listed plugins
Ctrl+a  u    — update existing plugins (also runs zmux update)
```

Or from the command line:

```bash
tmux run '~/.tmux/plugins/tpm/bin/install_plugins'
tmux run '~/.tmux/plugins/tpm/bin/update_plugins' all
```

## Adding or removing plugins

Edit `~/.config/tmux/plugins.conf`, then press `Ctrl+a i` to install new plugins or `Ctrl+a Alt+u` to remove unlisted ones.
