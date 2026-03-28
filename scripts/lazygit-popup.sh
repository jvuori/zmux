#!/bin/bash
# lazygit-popup.sh - Open LazyGit in a tmux popup
#
# Usage: lazygit-popup.sh <pane_id> [directory]
#
# Opens lazygit in a popup window at the specified directory (or current pane's directory)
# Returns to normal mode after exiting lazygit

PANE_ID="${1}"
WORK_DIR="${2:-.}"

# Ensure lazygit is installed
if ! command -v lazygit >/dev/null 2>&1; then
    echo "❌ lazygit is not installed. Please install it first."
    exit 1
fi

# Check if directory exists and is a git repository
if [ ! -d "$WORK_DIR" ]; then
    WORK_DIR="."
fi

if [ ! -d "$WORK_DIR/.git" ]; then
    # Try to find git root
    cd "$WORK_DIR" 2>/dev/null || WORK_DIR="."
    WORK_DIR=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
fi

# Open lazygit in a popup (90% width, 80% height)
# -x option prevents commands from being buffered, allowing interactive use
# -E exits the popup immediately when lazygit exits
tmux display-popup -E -w 90% -h 80% -d "$WORK_DIR" "lazygit"
