#!/bin/bash
# Clear the "waiting for input" notification set by notify-waiting.sh.
# Intended to be called from a tool's "pre-action" hook (e.g. Claude Code PreToolUse hook).

[ -z "$TMUX" ] && exit 0
[ -z "$TMUX_PANE" ] && exit 0

PANE="$TMUX_PANE"

# Restore both pane-level style overrides set by notify-waiting.sh
tmux set-option -upt "$PANE" window-style 2>/dev/null || true
tmux set-option -upt "$PANE" window-active-style 2>/dev/null || true

# Clear window indicator
WINDOW=$(tmux display-message -t "$PANE" -p '#{window_id}' 2>/dev/null)
[ -n "$WINDOW" ] && tmux set-option -wu -t "$WINDOW" @zmux_notify_waiting 2>/dev/null || true
