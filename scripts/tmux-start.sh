#!/bin/bash
# tmux-start.sh - Smart tmux session starter
# If sessions exist, attach to the last active one
# If no sessions exist, create a new one named "default"
# Note: tmux-continuum will auto-restore sessions on tmux server start

# Ensure required directories exist (for plugins like tmux-resurrect)
mkdir -p ~/.tmux/resurrect
mkdir -p ~/.config/tmux/scripts

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    # Already in tmux, just run tmux normally
    exec tmux "$@"
    exit $?
fi

# Start tmux server (this loads tmux.conf which loads plugins)
tmux start-server 2>/dev/null || true
sleep 0.5

# Source the config explicitly to ensure tmux-continuum is loaded
# This is important for auto-restore to trigger
if [ -f ~/.tmux.conf ]; then
    tmux source-file ~/.tmux.conf 2>/dev/null || true
fi

# Wait for continuum restore to complete
# Check every 0.1s for up to 10 seconds, until sessions appear or timeout
for i in {1..100}; do
    EXISTING_SESSIONS=$(tmux list-sessions 2>/dev/null)
    if [ -n "$EXISTING_SESSIONS" ]; then
        # Give continuum a tiny bit more time to finish restore
        sleep 0.2
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
    # Get the session with the highest activity timestamp (most recently used)
    # Format: session_activity:session_name, then sort by activity descending
    LAST_SESSION=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2)
    
    if [ -n "$LAST_SESSION" ]; then
        # Attach to the most recently active session
        exec tmux attach-session -t "$LAST_SESSION" "$@"
    else
        # Fallback: just attach to any session (tmux will pick one)
        exec tmux attach-session "$@"
    fi
fi

