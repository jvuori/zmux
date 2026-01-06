#!/bin/bash
# ============================================================================
# Session Switcher Script
# ============================================================================
# Interactive session switcher similar to Zellij's session management

# Check if tmux-fzf is available (preferred method)
if [ -f ~/.tmux/plugins/tmux-fzf/scripts/session.sh ]; then
    # Use tmux-fzf if available (works better in tmux context)
    ~/.tmux/plugins/tmux-fzf/scripts/session.sh
    exit 0
fi

# Fallback: Use tmux's built-in choose-session
# This works reliably in tmux context
tmux choose-session

