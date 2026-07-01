# Systemd Integration - How It Works

## The Goal

When you boot your laptop or log in, tmux starts automatically in the background with all your previous sessions restored. When you open WezTerm, it instantly connects to your existing sessions - no waiting for restoration.

## How It's Implemented

### Two Scripts Working Together

1. **`systemd-tmux-start.sh`** (runs once at login via systemd)
   - Starts the tmux server
   - Loads your tmux config
   - Triggers continuum to restore all saved sessions
   - Writes status file: `"restoring"` → `"ready"` when done

2. **`tmux-start.sh`** (runs when you open WezTerm)
   - Checks if tmux server is already running
   - If restoration is in progress, waits for it
   - Attaches to your most recently active session
   - No redundant restoration!

### Status File Coordination

The file `~/.tmux/daemon-status` ensures proper coordination:

```
"restoring" = systemd is currently restoring sessions
"ready"     = restoration complete, safe to attach
```

This prevents WezTerm from starting its own restoration process when systemd is already doing it.

## Flow Diagram

### At Boot/Login

```
Login happens
    ↓
systemd starts tmux.service
    ↓
systemd-tmux-start.sh runs
    ├─ Writes "restoring" to status file
    ├─ Starts tmux server
    ├─ Loads config (tmux-continuum plugin activates)
    ├─ Continuum restores saved sessions
    └─ Writes "ready" to status file

Meanwhile, tmux server runs in background with all sessions ready
```

### When WezTerm Opens

```
User opens WezTerm
    ↓
WezTerm runs tmux-start.sh
    ↓
Script checks: Is tmux server running?
    ├─ YES → Check status file
    │  ├─ Status is "restoring" → Wait for "ready"
    │  └─ Status is "ready" → Attach immediately
    └─ NO → Fall back to local restoration (backup)

Session appears instantly (or after brief wait)
```

## Why This Works Better Than Alternatives

### ❌ Without systemd (original approach)

1. User opens WezTerm
2. WezTerm starts tmux-start.sh
3. tmux starts and begins restoring sessions
4. User waits 5-10 seconds for restoration
5. Session finally appears

### ✅ With systemd (new approach)

1. User logs in (systemd starts tmux in background)
2. Tmux spends 5-10 seconds restoring sessions
3. User opens WezTerm (restoration already done!)
4. Session appears instantly
5. User is productive immediately

The restoration time is the same, but it happens **while the user is doing other things** (checking email, reading news, making coffee), not while they're staring at a blank terminal.

## When It Works Automatically

On standard Linux distros (Ubuntu 20.04+, Fedora, Arch, etc.):

- Service file is created: ✅
- Service is enabled: ✅
- Service starts at login: ✅
- Sessions are restored: ✅

## When Manual Setup Might Be Needed

**Very rare, but if:**

- You install on a **minimal system without graphical login** (server-only)
- You install via **SSH without a user systemd session** active
- Your system uses something other than systemd (OpenRC, etc.)

**The fix:** Just run these commands after your next login:

```bash
systemctl --user daemon-reload
systemctl --user enable tmux.service
systemctl --user start tmux.service
```

That's it! Then it will work automatically from then on.

## Verification

To check if everything is set up correctly:

```bash
# From zmux directory
./verify-systemd.sh
```

This script checks:

- ✅ User systemd session is active
- ✅ Service file exists
- ✅ Startup scripts exist and are executable
- ✅ Service is enabled
- ✅ tmux is installed
- ✅ Status file is valid
- ✅ Sessions are being tracked

## What Happens If Systemd Isn't Available

If the systemd service isn't working for some reason, `tmux-start.sh` has a fallback:

- It will start tmux locally
- It will trigger restoration locally
- You'll see a slight delay while restoration happens
- But it still works!

## Monitoring

Check what's happening:

```bash
# Service status
systemctl --user status tmux.service

# Recent logs
journalctl --user -u tmux.service -f

# Running sessions
tmux list-sessions

# Restoration status
cat ~/.tmux/daemon-status
```

## Key Takeaway

**You don't need to do anything.** It just works automatically. The systemd integration is transparent - you only notice that WezTerm starts faster.

If something's not working, run `./verify-systemd.sh` to see what's wrong.
