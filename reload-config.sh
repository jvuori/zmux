#!/bin/bash
# ============================================================================
# Reload zmux Configuration
# ============================================================================
# This script reloads the zmux configuration in all active tmux sessions

if ! command -v tmux >/dev/null 2>&1; then
    echo "❌ tmux is not installed"
    exit 1
fi

if ! tmux has-session 2>/dev/null; then
    echo "ℹ️  No active tmux sessions. Start tmux and the config will load automatically."
    exit 0
fi

echo "🔄 Reloading zmux configuration in all tmux sessions..."
echo ""

# Reload config in all sessions
tmux list-sessions -F "#{session_name}" | while read -r session; do
    echo "   Reloading session: $session"
    tmux source-file -t "$session" ~/.tmux.conf 2>/dev/null || {
        echo "   ⚠️  Could not reload session: $session"
    }
done

echo ""
echo "✅ Configuration reloaded!"
echo ""
echo "Verify it worked:"
echo "  tmux show-options -g prefix"
echo "  (Should show: prefix C-g)"
echo ""
echo "Test keybindings:"
echo "  - Press Ctrl+p (should enter pane mode)"
echo "  - Press Ctrl+n (should enter resize mode)"

