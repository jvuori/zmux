#!/bin/bash
# restore-session.sh - Wrapper around tmux-resurrect restore
# Restores session state, then restores pane applications
# Single deterministic entry point for all session restoration

set -e

# Run the standard tmux-resurrect restore
~/.tmux/plugins/tmux-resurrect/scripts/restore.sh

# After resurrection completes, restore pane apps
# Use a small delay to ensure panes are fully initialized
sleep 0.5
~/.config/tmux/scripts/restore-pane-apps.sh
