# Systemd Tmux Service Setup

## Overview

This guide sets up tmux to start automatically as a systemd user service at login time. This means the tmux daemon and all your sessions will be restored **before** you even open your terminal emulator, resulting in dramatically faster startup times.

**Note:** If you installed zmux using `install.sh`, the systemd service is already configured. This guide is for manual setup or troubleshooting.

## Benefits

- ⚡ **Fast startup** - tmux server and sessions are ready when WezTerm opens
- 🔄 **Automatic restoration** - sessions persist across desktop restarts
- 📌 **Always available** - tmux daemon runs in the background automatically
- 🔌 **Detach-safe** - the default session keeps the server alive

## Prerequisites

- `systemd` user session support (standard on most Linux distributions)
- tmux installed (`sudo apt install tmux` or equivalent)
- A running desktop session

## Installation

### Step 1: Create the systemd user directory

```bash
mkdir -p ~/.config/systemd/user
```

### Step 2: Ensure the startup script is in place

The startup script should already exist at `~/.config/tmux/scripts/systemd-tmux-start.sh` if you ran `install.sh` or `update.sh`. If not:

```bash
# Copy from zmux repository
cp /path/to/zmux/scripts/systemd-tmux-start.sh ~/.config/tmux/scripts/
chmod +x ~/.config/tmux/scripts/systemd-tmux-start.sh
```

### Step 3: Create the tmux service file

```bash
cat > ~/.config/systemd/user/tmux.service << 'EOF'
[Unit]
Description=Tmux Session Manager
Documentation=man:tmux(1)
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=%h/.config/tmux/scripts/systemd-tmux-start.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=graphical-session.target
EOF
```

### Step 4: Enable and start the service

```bash
# Reload systemd to recognize the new service
systemctl --user daemon-reload

# Enable the service to start at login
systemctl --user enable tmux.service

# Start the service now
systemctl --user start tmux.service
```

### Step 5: Verify it's working

```bash
# Quick verification script (from zmux directory)
./verify-systemd.sh

# Or manually check service status
systemctl --user status tmux.service

# List tmux sessions (should show "default" and any restored sessions)
tmux list-sessions
```

## How It Works

1. **At login**: systemd automatically starts the tmux service
2. **Service initialization**:
   - Writes "restoring" to `~/.tmux/daemon-status` status file
   - Creates `~/.tmux/resurrect` directory
   - Creates a "default" session (required for tmux-continuum to work)
   - The default session loads your tmux config and all plugins
   - Tmux-continuum detects saved sessions and automatically restores them
3. **Session restoration**: Waits for session count to stabilize (up to 30 seconds)
4. **Completion**: Writes "ready" to status file when restoration is complete
5. **Session activation**: When you open WezTerm:
   - `tmux-start.sh` checks if tmux server is running
   - If "restoring" status, it waits for "ready" before attaching
   - Once ready, attaches to your most recently active session
   - All sessions are already restored - no redundant restoration!

### Status File Coordination

The status file `~/.tmux/daemon-status` ensures proper coordination:

| Status      | Meaning                                 |
| ----------- | --------------------------------------- |
| `restoring` | Systemd is currently restoring sessions |
| `ready`     | Restoration complete, safe to attach    |

This prevents race conditions where WezTerm might start its own restoration process.

## Monitoring and Maintenance

### Check service status

```bash
systemctl --user status tmux.service
```

### View service logs

```bash
journalctl --user -u tmux.service -f
```

### Manually restart the service

```bash
systemctl --user restart tmux.service
```

### Stop the service (if needed)

```bash
systemctl --user stop tmux.service
```

### Disable the service (if needed)

```bash
systemctl --user disable tmux.service
```

## Integration with WezTerm

When WezTerm starts with the `default_prog` set to `~/.config/tmux/scripts/tmux-start.sh`:

1. The script detects that tmux server is already running
2. It automatically attaches to your most recently active session
3. All your sessions and window layouts are already restored and ready

This creates a seamless experience where:

- Opening WezTerm is instant (no restoration delay)
- Your sessions are automatically restored with their previous state
- Your most recently active session becomes active again
- Desktop reboots preserve your exact session configuration
- No duplicate or temporary sessions are created

## Troubleshooting

### Service is disabled or won't enable

**Check if the service is enabled:**

```bash
systemctl --user is-enabled tmux.service
```

**If disabled, enable it manually:**

```bash
systemctl --user daemon-reload
systemctl --user enable tmux.service
systemctl --user start tmux.service
```

**Why this might happen during installation:**

The `systemctl --user` commands require an active systemd user session. This is normally started automatically when you log in, but in rare cases it might not be available:

- Running `install.sh` over SSH without a full login session
- Very minimal Linux installations
- Custom environments without standard systemd setup

The fix: Just wait for your next graphical login or reboot, then run the enable commands above. After that, it will work automatically.

### Service fails to start or is inactive

Check the logs:

```bash
journalctl --user -u tmux.service -n 50
```

Common issues:

- **Missing startup script**: Ensure `~/.config/tmux/scripts/systemd-tmux-start.sh` exists and is executable
- **Syntax error in service file**: Check for typos in `[Unit]`, `[Service]`, `[Install]` sections
- **tmux binary not found**: Verify with `which tmux`

### Sessions not being restored

Verify tmux-continuum is configured:

```bash
tmux show-option -g @continuum-restore
tmux show-option -g @continuum-save-interval
```

Should output:

```
@continuum-restore on
@continuum-save-interval 15
```

### Service says "active (exited)"

This is normal! The service:

- Starts the tmux server with a "default" session
- Exits after startup (RemainAfterExit=yes keeps it marked as active)
- The actual tmux server continues running in the background

The tmux server process is separate from the service status indicator.

## Sharing with Colleagues

To share this setup with a colleague:

1. **They should install zmux using install.sh** (recommended):

   ```bash
   git clone https://github.com/your-username/zmux.git
   cd zmux
   ./install.sh
   ```

   The install script will automatically set up the systemd service.

2. **Or manually copy the service file**:

   ```bash
   mkdir -p ~/.config/systemd/user
   cp /path/to/tmux.service ~/.config/systemd/user/
   systemctl --user daemon-reload
   systemctl --user enable tmux.service
   systemctl --user start tmux.service
   systemctl --user status tmux.service
   ```

3. **Verify it works**:
   ```bash
   tmux list-sessions
   ```

## See Also

- [Tmux Plugin Manager (TPM) Installation](./PLUGIN_INSTALLATION.md)
- [Continuum Auto-Save/Restore Documentation](https://github.com/tmux-plugins/tmux-continuum)
- [Systemd User Services](https://wiki.archlinux.org/title/Systemd/User)
