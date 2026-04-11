#!/usr/bin/env bash
# ============================================================================
# run-update.sh - Interactive zmux self-update, run inside a tmux popup
# ============================================================================
# Updates zmux itself if a newer release is available (zmux update also handles
# TPM plugin updates internally). Clears the status-bar update notification when done.

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
