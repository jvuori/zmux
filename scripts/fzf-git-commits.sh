#!/bin/bash
# Git commit selector using fzf
# Lists commits with SHA, date, and message
# Outputs selected commit SHA

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [ -z "$CURRENT_BRANCH" ]; then
    echo "Not on a git branch"
    exit 1
fi

# Function to list commits in a formatted way
list_commits() {
    # Format: SHORT_SHA | DATE | MESSAGE
    git log --color=always --format="%C(yellow)%h%C(reset) | %C(green)%ar%C(reset) | %s" \
        --all \
        -100
}

# Use fzf to select commit
# Preview shows full commit details
SELECTED=$(list_commits 2>/dev/null | \
    fzf \
        --header="Select git commit (Ctrl+c to cancel)" \
        --reverse \
        --height=100% \
        --ansi \
        --preview='git show --color=always {1} | head -50' \
        --preview-window=right:60% \
        --bind 'ctrl-c:abort' \
        2>/dev/tty)

EXIT_CODE=$?

# Check if user cancelled
if [ $EXIT_CODE -ne 0 ] || [ -z "$SELECTED" ]; then
    exit 0
fi

# Extract just the SHA (first column before |)
COMMIT_SHA=$(echo "$SELECTED" | awk '{print $1}')

if [ -z "$COMMIT_SHA" ]; then
    exit 0
fi

# Output the commit SHA
echo -n "$COMMIT_SHA"
