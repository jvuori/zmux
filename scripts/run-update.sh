#!/usr/bin/env bash
# ============================================================================
# run-update.sh - Interactive zmux self-update, run inside a tmux popup
# ============================================================================
# Updates zmux if a newer release is available, then updates TPM plugins.
# Clears the status-bar update notification when done.

# Make sure the zmux CLI is reachable regardless of popup shell PATH.
PATH="$HOME/.local/bin:$PATH"
export PATH

zmux update

echo
echo "🔌 Updating tmux plugins..."
if [ -f "$HOME/.tmux/plugins/tpm/bin/update_plugins" ]; then
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all >/dev/null 2>&1
    echo "✅ Plugins updated."
else
    echo "   TPM not found, skipping."
fi

echo
printf '── Press any key to close ──'
# Works with bash or any POSIX sh launched by bash -c
read -rn1 2>/dev/null || read -r _

# Dismiss the status-bar notification whether the update succeeded or not.
tmux set-option -gq @update_available "" 2>/dev/null || true
