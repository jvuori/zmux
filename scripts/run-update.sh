#!/usr/bin/env bash
# ============================================================================
# run-update.sh - Interactive zmux self-update, run inside a tmux popup
# ============================================================================
# Always updates TPM plugins. Also updates zmux itself if a newer release is
# available. Clears the status-bar update notification when done.

# Make sure the zmux CLI is reachable regardless of popup shell PATH.
PATH="$HOME/.local/bin:$PATH"
export PATH

zmux update

echo
echo "🔌 Updating tmux plugins..."
if [ -f "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
else
    echo "   TPM not found, skipping plugin update."
fi

echo
printf '── Press any key to close ──'
# Works with bash or any POSIX sh launched by bash -c
read -rn1 2>/dev/null || read -r _

# Dismiss the status-bar notification whether the update succeeded or not.
tmux set-option -gq @update_available "" 2>/dev/null || true
