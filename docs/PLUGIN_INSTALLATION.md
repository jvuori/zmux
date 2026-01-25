# zmux Plugin Installation & Session Restoration

## Overview

zmux now provides seamless plugin installation and session restoration across all three scenarios: installation, updates, and startup.

## Installation Scenario

When you run `./install.sh`:

1. **TPM is installed** (Tmux Plugin Manager)
2. **Temporary session created** (if none exist) so TPM can work properly
3. **All essential plugins installed**, including:
   - `tmux-resurrect` - Save/restore session state
   - `tmux-continuum` - Auto-save sessions periodically
   - `tmux-fzf` - FZF-based session/window switcher
   - Other utility plugins (yank, open, prefix-highlight, sensible)
4. **Plugins verified** - if any fail to install, they're installed manually via git
5. **Temporary session cleaned up**

**Result:** All plugins ready to use without manual intervention.

## Update Scenario

When you run `./update.sh`:

1. **Config files updated** from latest source
2. **Temporary session created** (if none exist) for plugin operations
3. **Plugins installed** (any new ones listed in plugins.conf)
4. **Plugins updated** (all existing plugins updated to latest version)
5. **Session restoration verified** (resurrect/continuum confirmed present)
6. **Temporary session cleaned up**

**Result:** Everything up-to-date without losing your active sessions.

## Startup Scenario

When you launch a terminal (via WezTerm or Alacritty wrapper):

1. **tmux-start.sh is executed**
2. **tmux server starts**
3. **~/.tmux.conf is sourced** explicitly (ensures continuum is loaded)
4. **Continuum restore begins** (async process to restore saved sessions)
5. **Script waits up to 10 seconds** for sessions to appear
6. **Once sessions appear, waits 0.2s more** for restore to fully complete
7. **Attaches to most recently active session**

**Result:** Your sessions (zmux, spot, etc.) are automatically restored with all windows and panes.

## Key Improvements

### Before

- TPM couldn't install plugins during setup script (needed manual `Ctrl+a` then `i`)
- resurrect/continuum often weren't installed
- Startup didn't wait long enough for continuum to restore sessions
- Sessions were lost on terminal restart

### After

- All plugins install automatically with full retry logic
- Session persistence happens automatically (both saving and restoring)
- Startup properly waits for and detects restored sessions
- Sessions survive terminal restarts seamlessly

## Troubleshooting

### If plugins still fail to install:

```bash
# Manual installation in tmux:
# Press: Ctrl+a, then I

# Or run directly:
~/.tmux/plugins/tpm/bin/install_plugins
```

### If sessions don't restore on startup:

```bash
# Check if resurrect data exists:
ls -la ~/.local/share/tmux/resurrect/

# Manually restore:
~/.tmux/plugins/tmux-resurrect/scripts/restore.sh

# Verify continuum is loaded:
tmux show-environment | grep continuum
```

### If you want to manually save sessions right now:

```bash
# In tmux: Ctrl+a, then Ctrl+s
# Or manually:
~/.tmux/plugins/tmux-resurrect/scripts/save.sh
```

## Configuration Files

- **Installation**: `install.sh` - Handles fresh setup with plugin installation
- **Updates**: `update.sh` - Updates config and plugins with session safety
- **Startup**: `scripts/tmux-start.sh` - Smart session detection and attachment
- **Plugin list**: `plugins/plugins.conf` - TPM plugin specifications

## Plugin List

Your zmux uses these plugins (from `plugins/plugins.conf`):

| Plugin                | Purpose                         |
| --------------------- | ------------------------------- |
| tpm                   | Plugin manager itself           |
| tmux-sensible         | Sensible tmux defaults          |
| tmux-resurrect        | Save/restore session state      |
| tmux-continuum        | Auto-save sessions every 15 min |
| tmux-prefix-highlight | Show when prefix is active      |
| tmux-fzf              | FZF-based navigation            |
| tmux-yank             | Better copy/paste               |
| tmux-open             | Open files/URLs from tmux       |

## Manual Session Management

If you want to control session persistence manually:

```bash
# Force save (Ctrl+a, Ctrl+s):
~/.tmux/plugins/tmux-resurrect/scripts/save.sh

# Force restore (Ctrl+a, Ctrl+r):
~/.tmux/plugins/tmux-resurrect/scripts/restore.sh

# Check what's saved:
cat ~/.local/share/tmux/resurrect/last
```

## Continuum Settings (if you want to customize)

In `~/.tmux.conf` you can add:

```tmux
# Restore on tmux start (default: yes)
set -g @continuum-restore 'on'

# Auto-save interval in minutes (default: 15)
set -g @continuum-save-interval '10'

# Auto-restore on tmux start
if-shell "test -f ~/.local/share/tmux/resurrect/last" 'run "~/.tmux/plugins/tmux-resurrect/scripts/restore.sh"'
```

The defaults are already good - auto-save every 15 minutes and auto-restore on start.
