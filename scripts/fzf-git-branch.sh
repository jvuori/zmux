#!/bin/bash
# ============================================================================
# FZF Git Branch Selector
# ============================================================================
# Interactive git branch selector using fzf
# Lists all remote branches (without origin/) for easy fuzzy search
#
# Usage:
#   fzf-git-branch.sh                    # List all branches
#   fzf-git-branch.sh checkout           # Checkout a branch
#   fzf-git-branch.sh delete             # Delete a branch
#
# Shell Integration (zsh):
#   bindkey '^[b' '# MAGIC: git branch fzf\nfzf-git-branch.sh checkout\n'
#
# Or in shell function:
#   git-branch() { fzf-git-branch.sh checkout; }

set -e

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

# Check if fzf is installed
if ! command -v fzf >/dev/null 2>&1; then
    echo -e "${RED}Error: fzf is not installed${NC}" >&2
    echo "Please install fzf: https://github.com/junegunn/fzf#installation" >&2
    exit 1
fi

ACTION="${1:-checkout}"

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

# Function to list branches with better formatting
list_branches() {
    # List remote branches, remove "origin/" prefix, and mark current branch
    git branch -r | \
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

# Function to format preview
show_preview() {
    local branch="$1"
    # Remove any leading markers
    branch=$(echo "$branch" | sed 's/^[* ][[:space:]]*//')
    
    # Show recent commits on this branch
    git log "$branch" --oneline -5 2>/dev/null | \
        awk '{ printf "  %s\n", $0 }' || \
        echo "  (new branch)"
}

# Get preview script path
PREVIEW_CMD="bash -c 'source $0; show_preview \"{}\"'"

# Use fzf to select branch
SELECTED=$(list_branches | \
    fzf \
        --header="Select git branch (Ctrl+g to cancel)" \
        --reverse \
        --height=40% \
        --ansi \
        --preview="bash -c 'source \"$0\"; show_preview \"{}\"'" \
        --preview-window=bottom:5 \
        --bind 'ctrl-c:abort' \
        2>/dev/null)

# Check if user cancelled
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Extract branch name (remove leading * or spaces)
BRANCH=$(echo "$SELECTED" | sed 's/^[* ][[:space:]]*//')

case "$ACTION" in
    checkout)
        echo -e "${BLUE}Checking out branch: ${GREEN}$BRANCH${NC}"
        git checkout "$BRANCH" 2>&1 || {
            echo -e "${RED}Failed to checkout branch: $BRANCH${NC}" >&2
            exit 1
        }
        ;;
    delete)
        if [ "$BRANCH" = "$CURRENT_BRANCH" ]; then
            echo -e "${RED}Cannot delete current branch: $BRANCH${NC}" >&2
            exit 1
        fi
        echo -e "${YELLOW}Delete branch: ${RED}$BRANCH${NC}?"
        read -p "Are you sure? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git branch -d "$BRANCH" 2>&1 || {
                echo -e "${YELLOW}Trying force delete...${NC}"
                git branch -D "$BRANCH" 2>&1 || {
                    echo -e "${RED}Failed to delete branch: $BRANCH${NC}" >&2
                    exit 1
                }
            }
            echo -e "${GREEN}Deleted branch: $BRANCH${NC}"
        fi
        ;;
    *)
        echo "Usage: $0 {checkout|delete}" >&2
        exit 1
        ;;
esac
