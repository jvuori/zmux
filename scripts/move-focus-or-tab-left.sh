#!/bin/sh
# Move focus left, or switch to previous tab if at the left edge
# When tab is switched due to crossing the boundary, always select bottom-right pane

if [ "$(tmux display-message -p '#{pane_at_left}')" = "1" ]; then
    CURRENT=$(tmux display-message -p '#{window_index}')
    FIRST=$(tmux list-windows -F '#{window_index}' | sort -n | head -1)
    if [ "$CURRENT" = "$FIRST" ]; then
        tmux select-window -t '{end}'
    else
        tmux previous-window
    fi
    tmux select-pane -t '{bottom-right}'
else
    tmux select-pane -L 2>/dev/null || true
fi
exit 0
