#!/bin/sh
# Move focus left, or switch to previous tab if at the left edge
if [ "$(tmux display-message -p '#{pane_at_left}')" = "1" ]; then
    tmux previous-window
else
    tmux select-pane -L
fi
