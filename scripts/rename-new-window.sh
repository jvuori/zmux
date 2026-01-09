#!/bin/sh
# rename-new-window.sh
# Usage: rename-new-window.sh <window-id>
# Renames the given tmux window to "Tab #<index>" using tmux display-message

set -eu

WIN_ID="$1"

# Get the window index for the provided window id
idx=$(tmux display-message -p -t "$WIN_ID" "#{window_index}" 2>/dev/null || true)

if [ -z "$idx" ]; then
  # fallback: try to parse from WIN_ID (format %{session}:{index}.window?)
  idx=""
fi

if [ -n "$idx" ]; then
  tmux rename-window -t "$WIN_ID" "Tab #$idx" 2>/dev/null || true
fi
