#!/bin/sh
# Wrapper for LazyGit that dims background panes and restores focus
# Called from tmux keybinding with current pane path as $1

PANE_PATH="${1:-.}"
SESSION=$(tmux display-message -p '#{session_name}')

# Save the current window and pane id
CURRENT_WINDOW=$(tmux display-message -p '#{window_index}')
CURRENT_PANE=$(tmux display-message -p '#{pane_id}')

# Dim all panes to inactive style (red borders, muted background)
tmux set -g pane-border-style "fg=colour1,bg=colour235"
tmux set -g pane-active-border-style "fg=colour1,bg=colour235"

# Make the active pane look highlighted (green borders, brightened background)
tmux select-pane -t "$CURRENT_PANE" -P -S -200 -E -1

# Launch lazygit in a popup - this is blocking until the user exits lazygit
tmux display-popup -E -w 90% -h 80% -d "$PANE_PATH" "lazygit"

# Restore normal styling
tmux set -g pane-border-style "fg=colour46"
tmux set -g pane-active-border-style "fg=colour46"

# Re-focus the original pane
tmux select-pane -t "$CURRENT_PANE"
