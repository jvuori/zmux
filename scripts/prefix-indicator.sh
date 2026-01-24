#!/bin/bash
# Show lock icon in locked mode, otherwise show prefix indicator
# This script runs in tmux status bar context

CURRENT_TABLE=$(tmux display-message -p '#{client_key_table}' 2>/dev/null)
CURRENT_TABLE="${CURRENT_TABLE:-root}"

if [ "$CURRENT_TABLE" = "locked" ]; then
    # Show lock icon in locked mode (orange)
    printf "#[fg=colour208,bold]🔒#[default]"
else
    # Show prefix indicator - we'll use a simple indicator
    # tmux prefix_highlight plugin shows this, we just output blank if not in prefix mode
    # The plugin handles it, we just need to not output anything when locked
    :
fi
