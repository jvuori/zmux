#!/bin/bash
# Notify that a process is waiting for user input.
# Intended to be called from a tool's "stop/wait" hook (e.g. Claude Code Stop hook).
# Requires TMUX_PANE to be set, which tmux sets automatically for processes running in a pane.

[ -z "$TMUX" ] && exit 0
[ -z "$TMUX_PANE" ] && exit 0

PANE="$TMUX_PANE"
WINDOW=$(tmux display-message -t "$PANE" -p '#{window_id}' 2>/dev/null) || exit 0

# Flash the pane background (both active and inactive panes).
tmux set-option -pt "$PANE" window-style 'bg=colour240' 2>/dev/null || exit 0
tmux set-option -pt "$PANE" window-active-style 'fg=default,bg=colour240' 2>/dev/null || true

# Only set tab indicators if the user is not already in this window —
# if they're already here they've implicitly seen the notification.
SESSION=$(tmux display-message -t "$PANE" -p '#{session_id}' 2>/dev/null)
ACTIVE_WINDOW=$(tmux display-message -t "$SESSION" -p '#{window_id}' 2>/dev/null)
if [ -n "$WINDOW" ] && [ "$ACTIVE_WINDOW" != "$WINDOW" ]; then
    tmux set-option -w -t "$WINDOW" @zmux_notify_flash 1 2>/dev/null || true
fi

# Restore pane background after 50ms.
( sleep 0.05
  tmux set-option -upt "$PANE" window-style 2>/dev/null
  tmux set-option -upt "$PANE" window-active-style 2>/dev/null
) &
disown
# Flash tab 3 times (200ms on / 100ms off), then show the persistent "i" badge.
( for _ in 1 2 3; do
    sleep 0.2
    [ -n "$WINDOW" ] && tmux set-option -wu -t "$WINDOW" @zmux_notify_flash 2>/dev/null
    sleep 0.1
    [ -n "$WINDOW" ] && tmux set-option -w -t "$WINDOW" @zmux_notify_flash 1 2>/dev/null
  done
  [ -n "$WINDOW" ] && tmux set-option -wu -t "$WINDOW" @zmux_notify_flash 2>/dev/null
  # Only leave the "i" badge if the user was not already in this window when the notification fired.
  [ -n "$WINDOW" ] && [ "$ACTIVE_WINDOW" != "$WINDOW" ] && tmux set-option -w -t "$WINDOW" @zmux_notify_waiting 1 2>/dev/null
) &
disown
