#!/bin/bash
# save-session-before-shutdown.sh - Save tmux session before system shutdown/reboot
# This script is called by systemd when the system is shutting down

# Check if tmux server is running
if ! tmux list-sessions >/dev/null 2>&1; then
    echo "No tmux server running, nothing to save"
    exit 0
fi

echo "Saving tmux session before shutdown..."

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
