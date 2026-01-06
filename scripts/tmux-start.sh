#!/bin/bash
# tmux-start.sh - Smart tmux session starter
# If sessions exist, attach to the last active one
# If no sessions exist, create a new one named "default"

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    # Already in tmux, just run tmux normally
    exec tmux "$@"
    exit $?
fi

# Check if there are any existing sessions
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

