#!/bin/bash
# ============================================================================
# Lock Mode Status Indicator for Status Bar
# ============================================================================
# Show lock indicator if we're in the locked key table
# Uses the key table as the source of truth (atomic operation)

# Use -p flag to get the value without errors
CURRENT_TABLE=$(tmux display-message -p '#{client_key_table}' 2>/dev/null)

# Default to root if we can't get the table
CURRENT_TABLE="${CURRENT_TABLE:-root}"

if [ "$CURRENT_TABLE" = "locked" ]; then
    echo "#[fg=colour208,bold]🔒 LOCK#[default]"
fi

