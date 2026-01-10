#!/bin/sh
# Swap current pane with the pane to the left
CURRENT=$(tmux display-message -p "#{pane_id}")
tmux select-pane -L 2>/dev/null && TARGET=$(tmux display-message -p "#{pane_id}") && tmux swap-pane -s "$CURRENT" -t "$TARGET" -d && tmux select-pane -t "$CURRENT"
