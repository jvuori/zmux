#!/bin/bash
# systemd-tmux-start.sh - Start tmux for systemd service
# This script ensures tmux starts properly for background daemon use
# and triggers tmux-continuum to restore previous sessions.
#
# Coordination with tmux-start.sh:
# - Writes status to ~/.tmux/daemon-status to signal restoration progress
# - tmux-start.sh waits for "ready" status before attaching
# - This ensures only ONE restoration happens (by systemd, not WezTerm)

STATUS_FILE="$HOME/.tmux/daemon-status"

# Function to write status
write_status() {
    echo "$1" > "$STATUS_FILE"
}

# Ensure required directories exist
mkdir -p ~/.tmux/resurrect
mkdir -p ~/.config/tmux/scripts

# Ensure shutdown save service is enabled (in case systemd disabled it after reboot)
if systemctl --user is-enabled tmux-shutdown-save.service >/dev/null 2>&1; then
    : # Already enabled
else
    # Service exists but is disabled - enable it
    if [ -f "$HOME/.config/systemd/user/tmux-shutdown-save.service" ]; then
        systemctl --user daemon-reload 2>/dev/null
        systemctl --user enable tmux-shutdown-save.service 2>/dev/null || true
    fi
fi

# Check if tmux server is already running with sessions
# This handles the case where systemd restarts but tmux is still alive
if tmux list-sessions >/dev/null 2>&1; then
    # Server already running - just mark as ready and exit
    write_status "ready"
    exit 0
fi

# Mark restoration as in-progress
write_status "restoring"

# Kill any zombie tmux server (no sessions but server process exists)
tmux kill-server 2>/dev/null || true
sleep 0.3

# Start tmux server with a "default" session
# This session will trigger tmux-continuum auto-restore of saved sessions
# Using "default" as the session name since this is the fallback session
/usr/bin/tmux new-session -d -s default -c "$HOME" -x 200 -y 60

# Wait for continuum to restore sessions
# The continuum plugin will detect saved sessions and restore them
# We check periodically for session count to stabilize
PREV_COUNT=0
STABLE_CHECKS=0
MAX_WAIT=30  # Maximum 30 seconds

for i in $(seq 1 $MAX_WAIT); do
    sleep 1
    CURRENT_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    
    if [ "$CURRENT_COUNT" -eq "$PREV_COUNT" ] && [ "$CURRENT_COUNT" -gt 0 ]; then
        STABLE_CHECKS=$((STABLE_CHECKS + 1))
        # If session count is stable for 3 seconds, we're done
        if [ "$STABLE_CHECKS" -ge 3 ]; then
            break
        fi
    else
        STABLE_CHECKS=0
        PREV_COUNT=$CURRENT_COUNT
    fi
done

# After restoration, clean up the "default" session if other sessions exist
# This prevents "default" from being selected when we have saved sessions
SESSION_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
if [ "$SESSION_COUNT" -gt 1 ]; then
    # We have more than just "default" session, remove it
    # The default session was just a trigger for continuum restoration
    tmux kill-session -t default 2>/dev/null || true
fi

# Mark as ready - restoration complete
write_status "ready"

# Exit successfully - the tmux server continues running in the background
exit 0
