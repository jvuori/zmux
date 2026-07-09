# Reliable Autostart Solution

## The Problem

Previous attempts used systemd user services and shell profile scripts for autostart, but these proved unreliable:

- **Systemd service**: Kept getting disabled after reboot despite enable-linger
- **Shell profiles**: Only run on login shells (most terminals open non-login shells)
- Both mechanisms failed to run **before opening terminals**, defeating the purpose

## The Solution: XDG Autostart

zmux now uses **XDG autostart** exclusively - the standard way desktop environments launch applications at login.

### Why XDG Autostart?

✅ **Runs at graphical login** - Before you open ANY terminal  
✅ **Desktop-agnostic** - Works on GNOME, KDE, XFCE, i3, Sway, etc.  
✅ **Reliable** - Desktop environment guarantees execution  
✅ **Standard** - Part of FreeDesktop.org specifications  
✅ **Simple** - Single desktop entry file, no complex service management

## Implementation

### File Created

**`~/.config/autostart/zmux-daemon.desktop`**

```ini
[Desktop Entry]
Type=Application
Name=zmux Daemon
Comment=Start tmux daemon with session restoration before any terminal opens
Exec=/bin/bash -c '$HOME/.config/tmux/scripts/systemd-tmux-start.sh'
Terminal=false
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=true
```

### How It Works

1. **You log into your graphical desktop**
2. Desktop environment reads `~/.config/autostart/*.desktop` files
3. Executes `systemd-tmux-start.sh` which:
   - Starts tmux server
   - Runs tmux-resurrect/continuum to restore sessions
   - Sets status file to "ready"
4. **All this happens BEFORE you open any terminal**
5. When you open WezTerm → `tmux-start.sh` finds server already running → attaches instantly ⚡

## Files Changed

1. ✅ [install.sh](../install.sh) - Sets up XDG autostart only
2. ✅ [update.sh](../update.sh) - Updates XDG autostart configuration
3. ✅ [verify-autostart.sh](../verify-autostart.sh) - Verifies XDG autostart setup
4. ✅ [cleanup-old-autostart.sh](../cleanup-old-autostart.sh) - Removes old systemd/shell profile mechanisms
5. ✅ [README.md](../README.md) - Updated documentation

## Migration from Old Methods

If you previously used zmux with systemd or shell profile autostart:

```bash
./cleanup-old-autostart.sh  # Remove old mechanisms
./update.sh                  # Install XDG autostart
./verify-autostart.sh        # Verify configuration
```

The cleanup script removes:

- Systemd service files and configuration
- Shell profile autostart entries (with backup)
- Obsolete helper scripts

## Verification

After installation or reboot:

```bash
./verify-autostart.sh
```

Should show:

- ✅ XDG autostart configured
- ✅ Startup scripts executable
- ✅ tmux server running with sessions

## Troubleshooting

### Debug Mode

If autostart isn't working, enable debug logging to see what's happening:

```bash
# Create debug flag file
touch ~/.tmux/zmux-debug

# Re-run autostart (or log out and log back in)
~/.config/tmux/scripts/systemd-tmux-start.sh

# Check the logs
cat ~/.tmux/zmux-start.log
```

The log file will show:
- When the daemon started
- When systemd user session became ready
- When tmux restoration completed
- Any errors encountered

**Tip**: Remove the debug flag when done to disable logging:
```bash
rm ~/.tmux/zmux-debug
```

### Common Issues and Solutions

#### Issue: Autostart doesn't start tmux

**Potential causes**:
1. **Systemd user session timing** - The user session might not be ready when autostart runs
   - *Fix*: Script now waits up to 15 seconds for systemd user session readiness
   - Check logs with: `touch ~/.tmux/zmux-debug && ~/.config/tmux/scripts/systemd-tmux-start.sh`

2. **Environment variables** - `$HOME` or `$PATH` might be unset
   - *Fix*: Script now uses `/bin/bash` with proper variable handling
   - Verify: `echo $HOME` in the terminal

3. **Script permissions** - Script might not be executable
   - Check: `ls -l ~/.config/tmux/scripts/systemd-tmux-start.sh`
   - Fix: `chmod +x ~/.config/tmux/scripts/systemd-tmux-start.sh`

4. **tmux binary location** - tmux might not be at `/usr/bin/tmux`
   - Check: `which tmux`
   - Debug: `tmux list-sessions` in terminal (to verify tmux works)

#### Issue: Sessions aren't being restored

This is separate from autostart. Check:

```bash
# Verify continuum plugin is working
tmux list-plugins

# Check if resurrection data exists
ls -la ~/.tmux/resurrect/

# Manually check desktop file
cat ~/.config/autostart/zmux-daemon.desktop
```

#### Issue: Multiple tmux servers running

This might indicate:
- Autostart started one server
- Manual start or terminal launch started another

Check and fix:
```bash
tmux list-sessions -a  # Show all sessions from all servers
ps aux | grep tmux     # Show all tmux processes

# Kill all tmux servers (this will terminate all sessions!)
tmux kill-server
```

### Diagnostic Commands

Run these to verify your setup:

1. **Verify autostart configuration**
   ```bash
   ./verify-autostart.sh
   ```

2. **Run startup script manually**
   ```bash
   ~/.config/tmux/scripts/systemd-tmux-start.sh
   ```

3. **Check systemd user session status**
   ```bash
   systemctl --user status
   ```

4. **Simulate minimal autostart environment**
   ```bash
   env -i HOME=$HOME PATH=/usr/bin:/bin /bin/bash -c '~/.config/tmux/scripts/systemd-tmux-start.sh'
   ```

5. **Validate desktop file syntax**
   ```bash
   desktop-file-validate ~/.config/autostart/zmux-daemon.desktop
   ```

6. **Check journal logs for autostart events**
   ```bash
   journalctl --user -b -n 50  # Last 50 lines from this session
   journalctl --user -b | grep -i zmux  # Filter for zmux entries
   ```

### XDG Autostart not working?

1. Check if your desktop environment supports XDG autostart:

   ```bash
   ls ~/.config/autostart/
   ```

2. Verify the desktop file exists and is valid:

   ```bash
   cat ~/.config/autostart/zmux-daemon.desktop
   desktop-file-validate ~/.config/autostart/zmux-daemon.desktop
   ```

3. Check desktop environment autostart settings (some DEs have a GUI for managing autostart apps)

### Running terminal-only system?

For servers or terminal-only systems without a graphical desktop, manually start the daemon:

```bash
~/.config/tmux/scripts/systemd-tmux-start.sh &
```

Or add to your shell's rc file (`.bashrc`, `.zshrc`):

```bash
# Start tmux daemon if not already running
if ! tmux list-sessions >/dev/null 2>&1; then
    ~/.config/tmux/scripts/systemd-tmux-start.sh >/dev/null 2>&1 &
fi
```

## Benefits

✅ **Simple** - One file, one mechanism, easy to understand  
✅ **Reliable** - No more disabled services after reboot  
✅ **Fast** - Daemon starts at login, terminals open instantly  
✅ **Portable** - Works across all major Linux desktop environments  
✅ **Maintainable** - Standard approach, well-documented
