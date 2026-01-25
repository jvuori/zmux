#!/bin/bash
# Wrapper script for git commit selection in tmux popup
# This script runs fzf and sends the result back to the calling pane

# Get the target pane ID from argument
TARGET_PANE="$1"

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo "Not in a git repository"
    echo "Current directory: $(pwd)"
    read -p "Press Enter to close..."
    exit 1
fi

# Run the fzf git commit selector
result=$(~/.config/tmux/scripts/fzf-git-commits.sh 2>&1)
exit_code=$?

# If we got a result, send it to the target pane
if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
    tmux send-keys -t "$TARGET_PANE" -l "$result"
fi
