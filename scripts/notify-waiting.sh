#!/bin/bash
# Notify that a process is waiting for user input.
# Intended to be called from a tool's "stop/wait" hook (e.g. Claude Code Stop hook).
# Requires TMUX_PANE to be set, which tmux sets automatically for processes running in a pane.

[ -z "$TMUX" ] && exit 0
[ -z "$TMUX_PANE" ] && exit 0

PANE="$TMUX_PANE"
WINDOW=$(tmux display-message -t "$PANE" -p '#{window_id}' 2>/dev/null) || exit 0

# Flash the pane background (inactive style only; active style stays normal).
tmux set-option -pt "$PANE" window-style 'bg=colour52' 2>/dev/null || exit 0
tmux set-option -pt "$PANE" window-active-style 'fg=default,bg=colour0' 2>/dev/null || true

# Only set tab indicators if the user is not already in this window —
# if they're already here they've implicitly seen the notification.
SESSION=$(tmux display-message -t "$PANE" -p '#{session_id}' 2>/dev/null)
ACTIVE_WINDOW=$(tmux display-message -t "$SESSION" -p '#{window_id}' 2>/dev/null)
if [ -n "$WINDOW" ] && [ "$ACTIVE_WINDOW" != "$WINDOW" ]; then
    tmux set-option -w -t "$WINDOW" @zmux_notify_flash 1 2>/dev/null || true
    tmux set-option -w -t "$WINDOW" @zmux_notify_waiting 1 2>/dev/null || true
fi

# Restore pane color and tab flash after 300ms; ⚡ stays until tab is activated.
( sleep 0.3
  tmux set-option -upt "$PANE" window-style 2>/dev/null
  tmux set-option -upt "$PANE" window-active-style 2>/dev/null
  [ -n "$WINDOW" ] && tmux set-option -wu -t "$WINDOW" @zmux_notify_flash 2>/dev/null
) &
disown
