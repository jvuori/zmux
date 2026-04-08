#!/bin/sh
# Move focus right, or switch to next tab if at the right edge
# When tab is switched due to crossing the boundary, always select top-left pane

if [ "$(tmux display-message -p '#{pane_at_right}')" = "1" ]; then
    CURRENT=$(tmux display-message -p '#{window_index}')
    LAST=$(tmux list-windows -F '#{window_index}' | sort -n | tail -1)
    if [ "$CURRENT" = "$LAST" ]; then
        tmux select-window -t '{start}'
    else
        tmux next-window
    fi
    tmux select-pane -t '{top-left}'
else
    tmux select-pane -R 2>/dev/null || true
fi
exit 0
