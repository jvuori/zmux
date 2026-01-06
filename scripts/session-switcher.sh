#!/bin/bash
# ============================================================================
# Session Switcher Script
# ============================================================================
# Interactive session switcher similar to Zellij's session management

# Get list of sessions
sessions=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

if [ -z "$sessions" ]; then
    tmux display-message "No sessions available"
    exit 0
fi

# Use fzf if available, otherwise use basic selection
if command -v fzf >/dev/null 2>&1; then
    selected=$(echo "$sessions" | fzf --height 40% --reverse --border)
else
    # Fallback to tmux choose-session
    tmux choose-session
    exit 0
fi

# Switch to selected session
if [ -n "$selected" ]; then
    tmux switch-client -t "$selected"
fi

