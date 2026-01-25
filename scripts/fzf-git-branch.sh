#!/bin/bash
# ============================================================================
# FZF Git Branch Selector
# ============================================================================
# Interactive git branch selector using fzf
# Lists all remote branches (without origin/) for easy fuzzy search
#
# Usage:
#   fzf-git-branch.sh                    # List branches and output selection
#
# This script outputs the selected branch name to stdout,
# suitable for insertion into a command line.

# Source bashrc to get proper PATH in WSL/tmux popups
if [ -f "$HOME/.bashrc" ]; then
    source "$HOME/.bashrc" 2>/dev/null || true
fi

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}" >&2
    exit 1
fi

# Check if fzf is installed (with fallback paths for WSL)
if ! command -v fzf >/dev/null 2>&1; then
    if [ -f "$HOME/.fzf/bin/fzf" ]; then
        export PATH="$HOME/.fzf/bin:$PATH"
    else
        echo -e "${RED}Error: fzf is not installed${NC}" >&2
        echo "Please install fzf: https://github.com/junegunn/fzf#installation" >&2
        exit 1
    fi
fi

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

# Debug: save branch list to a temp file for inspection
list_branches() {
    # List remote branches, remove "origin/" prefix, and mark current branch
    git branch -r 2>/dev/null | \
        grep -v 'HEAD ->' | \
        sed 's|^[[:space:]]*origin/||' | \
        sort | \
        uniq | \
        awk -v current="$CURRENT_BRANCH" '{
            if ($0 == current)
                printf "* %s\n", $0  # Mark current branch with *
            else
                printf "  %s\n", $0
        }'
}

# Check if stdin is a pipe (for automated testing)
if [ ! -t 0 ]; then
    # Running in automated/piped mode - use fzf filter mode
    SELECTED=$(list_branches 2>/dev/null | \
        fzf \
            --filter="$(cat)" \
            --no-multi \
            --exit-0 \
            2>/dev/null | head -1)
else
    # Use fzf to select branch with inline preview
    # Explicitly redirect to ensure proper I/O in tmux popup context
    SELECTED=$(list_branches 2>/dev/null | \
        fzf \
            --header="Select git branch (Ctrl+c to cancel)" \
            --reverse \
            --height=100% \
            --ansi \
            --preview='git log $(echo {} | sed "s/^[* ][[:space:]]*//") --oneline -5 2>/dev/null | awk "{ printf \"  %s\n\", \$0 }"' \
            --preview-window=bottom:5 \
            --bind 'ctrl-c:abort' \
            2>/dev/tty)
fi

EXIT_CODE=$?

# Check if user cancelled (fzf returns 130 on Ctrl+C)
if [ $EXIT_CODE -ne 0 ] || [ -z "$SELECTED" ]; then
    exit 0
fi

# Extract branch name (remove leading * or spaces) and output it
BRANCH=$(echo "$SELECTED" | sed 's/^[* ][[:space:]]*//')

if [ -z "$BRANCH" ]; then
    exit 0
fi

# Output the branch name (will be inserted into command line)
echo -n "$BRANCH"
