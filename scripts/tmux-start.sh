#!/bin/bash
# tmux-start.sh - Smart tmux session starter for WezTerm/terminal emulators
# If sessions exist, attach to the last active one
# If no sessions exist, create a new one named "default"
#
# When used with the systemd tmux service:
# - Sessions are already restored in the background at login
# - This script just attaches to the most recently active session
# - No delay for session restoration!

# Ensure required directories exist (for plugins like tmux-resurrect)
mkdir -p ~/.tmux/resurrect
mkdir -p ~/.config/tmux/scripts

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    # Already in tmux, just run tmux normally
    exec tmux "$@"
    exit $?
fi

# Check if tmux server is already running (e.g., started by systemd)
if tmux list-sessions >/dev/null 2>&1; then
    # Server is running with sessions - attach to most recent
    LAST_SESSION=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2)
    
    if [ -n "$LAST_SESSION" ]; then
        exec tmux attach-session -t "$LAST_SESSION" "$@"
    else
        exec tmux attach-session "$@"
    fi
fi

# No tmux server running - start fresh
# This happens if systemd service isn't enabled or failed
tmux start-server 2>/dev/null || true
sleep 0.5

# Source the config explicitly to ensure tmux-continuum is loaded
# This is important for auto-restore to trigger
if [ -f ~/.tmux.conf ]; then
    tmux source-file ~/.tmux.conf 2>/dev/null || true
fi

# Wait for continuum restore to complete (fallback when systemd isn't used)
# Check every 0.1s for up to 5 seconds, until sessions appear or timeout
for i in {1..50}; do
    EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null)
    if [ -n "$EXISTING_SESSIONS" ]; then
        # Give continuum a tiny bit more time to finish restore
        sleep 0.3
        break
    fi
    sleep 0.1
done

# Final check for sessions after potential restore
EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null)

if [ -z "$EXISTING_SESSIONS" ]; then
    # No sessions exist, create a new one named "default"
    exec tmux new-session -s default "$@"
else
    # Sessions exist, attach to the last active session
    LAST_SESSION=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2)
    
    if [ -n "$LAST_SESSION" ]; then
        exec tmux attach-session -t "$LAST_SESSION" "$@"
    else
        exec tmux attach-session "$@"
    fi
fi
