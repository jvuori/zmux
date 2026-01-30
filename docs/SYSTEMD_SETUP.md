# Systemd Tmux Service - Setup Guide

## Quick Answer

**The systemd service starts tmux automatically at login with all sessions restored. When you open WezTerm, you instantly get your previous session back - no waiting.**

## What Changed

You now have a **coordination mechanism** that prevents WezTerm from doing redundant work:

1. **Systemd starts tmux at login** - runs `systemd-tmux-start.sh`
   - Starts tmux server with sessions from previous boot
   - Writes status file while restoring: `"restoring"`
   - Writes status file when done: `"ready"`

2. **WezTerm checks the status file** - runs `tmux-start.sh`
   - If `"restoring"` → waits for `"ready"` (up to 60 seconds)
   - If `"ready"` → attaches immediately
   - Fallback: if systemd isn't available, starts tmux locally

## Installation

You already have everything set up. Just verify it:

```bash
cd ~/prj/zmux
./verify-systemd.sh
```

All checks should pass with green ✅ marks.

## What Happens At Each Stage

### At Reboot/Login

```
systemd automatically starts tmux service
    ↓
tmux server starts in background
    ↓
Continuum plugin restores your saved sessions (5-10 seconds)
    ↓
When restoration is done: status file shows "ready"
```

### When You Open WezTerm

```
WezTerm runs tmux-start.sh
    ↓
Script sees: tmux already running, status file says "ready"
    ↓
Script attaches to your most recent session
    ↓
Your session appears instantly (restoration already happened)
```

## Verifying It Works

### After rebooting your laptop:

1. Don't open any terminal yet
2. Wait a few seconds (systemd runs tmux in background)
3. Open WezTerm
4. Your session should appear immediately

**The key insight:** The restoration happens **before** you open WezTerm, so there's no delay.

### Check the status:

```bash
# See when restoration happened
cat ~/.tmux/daemon-status

# List your sessions
tmux list-sessions

# Check service is running
systemctl --user status tmux.service
```

## If It's Not Working

### Service is disabled

```bash
systemctl --user daemon-reload
systemctl --user enable tmux.service
systemctl --user start tmux.service
```

### Verify everything:

```bash
./verify-systemd.sh
```

This checks all the pieces and tells you exactly what's wrong (if anything).

### Check logs if problems persist:

```bash
journalctl --user -u tmux.service -f
```

## Files Involved

- **`~/.config/systemd/user/tmux.service`** - Service definition
- **`~/.config/tmux/scripts/systemd-tmux-start.sh`** - Runs at login
- **`~/.config/tmux/scripts/tmux-start.sh`** - Runs when opening WezTerm
- **`~/.tmux/daemon-status`** - Coordination status file

## The Fallback Mechanism

If systemd doesn't work for some reason:

- `tmux-start.sh` detects it and starts tmux locally
- Sessions still get restored (just takes a few seconds)
- You still get all your sessions back
- No data loss, just slightly slower

## For Next Time You Install

When running `install.sh`:

- It creates the systemd service file
- It attempts to enable the service
- If it can't (rare), you'll see instructions
- Just follow those instructions after your next login

## Questions?

See [SYSTEMD_HOW_IT_WORKS.md](SYSTEMD_HOW_IT_WORKS.md) for detailed explanation.
