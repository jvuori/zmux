#!/bin/bash
# ============================================================================
# Toggle Lock Mode for tmux
# ============================================================================
# This script toggles lock mode on/off, similar to Zellij's lock mode.
# When locked, keyboard shortcuts are passed through to the application.

# Get the currently active pane's session
# Note: This script MUST be called from within tmux context
CURRENT_SESSION=$(tmux display-message -p '#{session_name}' 2>/dev/null)

if [ -z "$CURRENT_SESSION" ]; then
    exit 1
fi

# Get current lock status
LOCK_STATUS=$(tmux show-options -t "$CURRENT_SESSION" -v "@lock_mode" 2>/dev/null || echo "0")

if [ "$LOCK_STATUS" = "1" ]; then
    # Currently locked, unlock it
    tmux set-option -t "$CURRENT_SESSION" "@lock_mode" "0"
    tmux switch-client -T root
    tmux display-message "Unlocked"
else
    # Currently unlocked, lock it
    tmux set-option -t "$CURRENT_SESSION" "@lock_mode" "1"
    tmux switch-client -T locked
    tmux display-message "Locked"
fi
