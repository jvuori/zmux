#!/bin/sh
# Swap current pane with the pane to the right
CURRENT=$(tmux display-message -p "#{pane_id}")
tmux select-pane -R 2>/dev/null && TARGET=$(tmux display-message -p "#{pane_id}") && tmux swap-pane -s "$CURRENT" -t "$TARGET" -d && tmux select-pane -t "$CURRENT"
