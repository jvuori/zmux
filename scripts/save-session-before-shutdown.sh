#!/bin/bash
# save-session-before-shutdown.sh - Save tmux session before system shutdown/reboot
# This script is called by systemd when the system is shutting down
# It saves both the session state and which session was active

# Check if tmux server is running
if ! tmux list-sessions >/dev/null 2>&1; then
    echo "No tmux server running, nothing to save"
    exit 0
fi

echo "Saving tmux session before shutdown..."

# Create the resurrect directory if it doesn't exist
mkdir -p "${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"

# Save which session is currently active (for restoration)
# This is stored separately so we can restore to the exact session that was active
ACTIVE_SESSION_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/active-session.txt"

# Get the active client's session (or first client if multiple)
ACTIVE_SESSION=$(tmux list-clients -F "#{client_session}" 2>/dev/null | head -1)

# If we can't determine from client, try to get the most recently attached session
if [ -z "$ACTIVE_SESSION" ]; then
    ACTIVE_SESSION=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | sort -rn | head -1 | cut -d: -f2)
fi

# Save the active session name
if [ -n "$ACTIVE_SESSION" ]; then
    echo "$ACTIVE_SESSION" > "$ACTIVE_SESSION_FILE"
    echo "Saved active session: $ACTIVE_SESSION"
fi

# Use tmux-resurrect save script if available
RESURRECT_SAVE="$HOME/.tmux/plugins/tmux-resurrect/scripts/save.sh"

if [ -f "$RESURRECT_SAVE" ]; then
    # Run the save script
    "$RESURRECT_SAVE"
    echo "Session saved successfully"
else
    echo "Warning: tmux-resurrect save script not found at $RESURRECT_SAVE"
    exit 1
fi

# Give it a moment to complete the save
sleep 0.5
