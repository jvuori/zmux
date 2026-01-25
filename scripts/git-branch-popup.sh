#!/bin/bash
# Wrapper script for git branch selection in tmux popup
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

# Run the fzf git branch selector
result=$(~/.config/tmux/scripts/fzf-git-branch.sh 2>&1)
exit_code=$?

# Debug: write to temp file to see what we got
echo "Debug: TARGET_PANE=$TARGET_PANE" > /tmp/git-popup-debug.log
echo "Debug: result='$result'" >> /tmp/git-popup-debug.log
echo "Debug: exit_code=$exit_code" >> /tmp/git-popup-debug.log

# If we got a result, send it to the target pane
if [ $exit_code -eq 0 ] && [ -n "$result" ]; then
    echo "Debug: Sending keys to $TARGET_PANE" >> /tmp/git-popup-debug.log
    tmux send-keys -t "$TARGET_PANE" -l "$result"
    echo "Debug: send-keys returned $?" >> /tmp/git-popup-debug.log
fi
