#!/usr/bin/env bash
# ============================================================================
# run-update.sh - Interactive zmux self-update, run inside a tmux popup
# ============================================================================
# Ensures zmux is reachable (adds ~/.local/bin to PATH), runs "zmux update",
# waits for the user to read the output, then clears the update notification.

# Make sure the zmux CLI is reachable regardless of popup shell PATH.
PATH="$HOME/.local/bin:$PATH"
export PATH

zmux update
echo
printf '── Press any key to close ──'
# Works with bash or any POSIX sh launched by bash -c
read -rn1 2>/dev/null || read -r _

# Dismiss the status-bar notification whether the update succeeded or not.
tmux set-option -gq @update_available "" 2>/dev/null || true
