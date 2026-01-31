#!/bin/bash
# track-active-session.sh - Update the active session file
# Called by tmux hook whenever session changes
# This ensures we always know which session is active

SESSION_NAME="$1"
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
ACTIVE_FILE="$RESURRECT_DIR/active-session.txt"

# Create directory if needed
mkdir -p "$RESURRECT_DIR"

# Write the session name
echo "$SESSION_NAME" > "$ACTIVE_FILE"
