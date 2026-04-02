#!/bin/sh
# Move focus left, or switch to previous tab if at the left edge
if [ "$(tmux display-message -p '#{pane_at_left}')" = "1" ]; then
    tmux previous-window 2>/dev/null || true
else
    tmux select-pane -L 2>/dev/null || true
fi
