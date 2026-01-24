#!/bin/bash
# ============================================================================
# Lock Mode Status Indicator for Status Bar
# ============================================================================
# Show lock indicator if we're in the locked key table, otherwise show prefix indicator

# Use -p flag to get the value without errors
CURRENT_TABLE=$(tmux display-message -p '#{client_key_table}' 2>/dev/null)

# Default to root if we can't get the table
CURRENT_TABLE="${CURRENT_TABLE:-root}"

if [ "$CURRENT_TABLE" = "locked" ]; then
    # In locked mode, show lock icon only
    echo "#[fg=colour208,bold]🔒#[default]"
else
    # In normal mode, show the prefix-highlight (usually Ctrl+A indicator)
    # This uses the prefix_highlight plugin variable if available
    echo "#{prefix_highlight}"
fi

