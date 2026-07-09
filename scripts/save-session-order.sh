#!/bin/bash
# save-session-order.sh
# Saves per-session last-used timestamps alongside the resurrect file so the
# session switcher can restore ordering across reboots.
# Called from the client-detached hook and from Ctrl+a Ctrl+s.

RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
ORDER_FILE="$RESURRECT_DIR/session-order.txt"

mkdir -p "$RESURRECT_DIR"

# Prefer session_last_attached; fall back to session_activity.
tmux list-sessions \
    -F "#{session_last_attached}|#{session_activity}|#{session_name}" 2>/dev/null \
    | awk -F'|' 'NF==3 && $3!="" {
        ts = ($1 != "") ? $1 : ($2 != "" ? $2 : "0")
        print ts "|" $3
      }' \
    | sort -rn > "$ORDER_FILE"
