#!/bin/bash
# save-pane-programs.sh
# Saves the foreground program running in each pane alongside tmux-resurrect.
# Stored as session:window.pane|program so restore-pane-apps.sh can read it
# back reliably instead of grepping scrollback content.

PROGRAMS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane-programs.txt"
tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_current_command}" \
    > "$PROGRAMS_FILE" 2>/dev/null
