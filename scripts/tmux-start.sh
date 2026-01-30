#!/bin/bash
# tmux-start.sh - Smart tmux session starter for WezTerm/terminal emulators
#
# This script coordinates with the systemd tmux daemon:
# - If systemd is restoring sessions, wait for completion
# - If tmux is already running with sessions, attach immediately
# - If systemd isn't available, fall back to local restoration
#
# Status file: ~/.tmux/daemon-status
# - "restoring" = systemd is currently restoring sessions
# - "ready" = restoration complete, safe to attach

STATUS_FILE="$HOME/.tmux/daemon-status"
MAX_WAIT=60  # Maximum seconds to wait for systemd restoration

# Ensure required directories exist (for plugins like tmux-resurrect)
mkdir -p ~/.tmux/resurrect
mkdir -p ~/.config/tmux/scripts

# Check if we're already in a tmux session
if [ -n "$TMUX" ]; then
    # Already in tmux, just run tmux normally
    exec tmux "$@"
    exit $?
fi

# Function to get the most recently active session
get_last_session() {
    tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2
}

# Function to attach to the most recent session
attach_to_session() {
    local session
    session=$(get_last_session)
    
    if [ -n "$session" ]; then
        exec tmux attach-session -t "$session" "$@"
    else
        exec tmux attach-session "$@"
    fi
}

# Check if tmux server is already running with sessions
if tmux list-sessions >/dev/null 2>&1; then
    # Server is running - check if restoration is complete
    if [ -f "$STATUS_FILE" ]; then
        STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
        
        if [ "$STATUS" = "restoring" ]; then
            # Systemd is still restoring - wait for it
            echo "Waiting for session restoration to complete..."
            for i in $(seq 1 $MAX_WAIT); do
                sleep 1
                STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
                if [ "$STATUS" = "ready" ]; then
                    break
                fi
                # Show progress every 5 seconds
                if [ $((i % 5)) -eq 0 ]; then
                    echo "  Still waiting... (${i}s)"
                fi
            done
        fi
    fi
    
    # Attach to the most recently active session
    attach_to_session "$@"
fi

# No tmux server running - check if systemd service is starting
# Give systemd a moment to start the service (race condition at login)
for i in {1..10}; do
    if tmux list-sessions >/dev/null 2>&1; then
        # Server started by systemd - wait for restoration if needed
        if [ -f "$STATUS_FILE" ]; then
            STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
            if [ "$STATUS" = "restoring" ]; then
                echo "Waiting for session restoration to complete..."
                for j in $(seq 1 $MAX_WAIT); do
                    sleep 1
                    STATUS=$(cat "$STATUS_FILE" 2>/dev/null)
                    if [ "$STATUS" = "ready" ]; then
                        break
                    fi
                    if [ $((j % 5)) -eq 0 ]; then
                        echo "  Still waiting... (${j}s)"
                    fi
                done
            fi
        fi
        attach_to_session "$@"
    fi
    sleep 0.5
done

# Systemd service not available or failed - fall back to local startup
# This is the fallback path when systemd isn't being used
echo "Starting tmux with local session restoration..."

# Mark as restoring (in case we need to coordinate with other terminals)
echo "restoring" > "$STATUS_FILE"

tmux start-server 2>/dev/null || true
sleep 0.5

# Source the config explicitly to ensure tmux-continuum is loaded
if [ -f ~/.tmux.conf ]; then
    tmux source-file ~/.tmux.conf 2>/dev/null || true
fi

# Wait for continuum restore to complete
PREV_COUNT=0
STABLE_CHECKS=0
for i in {1..30}; do
    sleep 1
    CURRENT_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    
    if [ "$CURRENT_COUNT" -eq "$PREV_COUNT" ] && [ "$CURRENT_COUNT" -gt 0 ]; then
        STABLE_CHECKS=$((STABLE_CHECKS + 1))
        if [ "$STABLE_CHECKS" -ge 3 ]; then
            break
        fi
    else
        STABLE_CHECKS=0
        PREV_COUNT=$CURRENT_COUNT
    fi
done

# Mark as ready
echo "ready" > "$STATUS_FILE"

# Check for sessions after potential restore
if tmux list-sessions >/dev/null 2>&1; then
    attach_to_session "$@"
else
    # No sessions exist, create a new one named "default"
    exec tmux new-session -s default "$@"
fi
