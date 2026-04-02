#!/bin/sh
# Move focus right, or switch to next tab if at the right edge
if [ "$(tmux display-message -p '#{pane_at_right}')" = "1" ]; then
    tmux next-window
else
    tmux select-pane -R
fi
