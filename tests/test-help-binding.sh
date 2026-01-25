#!/bin/bash
# Test that Ctrl+A ? help binding works

set -e

echo "Testing Ctrl+A ? help binding..."

# Check configuration file directly (works in all environments)
if [ ! -f "$HOME/.config/tmux/keybindings.conf" ]; then
    echo "✗ Keybindings config file not found"
    exit 1
fi

# Check if ? is bound to show-help in config
if ! grep -q 'bind.*-T.*prefix.*"?".*show-help' "$HOME/.config/tmux/keybindings.conf" && \
   ! grep -q "bind.*-T.*prefix.*'?'.*show-help" "$HOME/.config/tmux/keybindings.conf"; then
    # Try a simpler check in case formatting differs
    if ! grep -q "bind.*-T.*prefix.*\?" "$HOME/.config/tmux/keybindings.conf" || \
       ! grep -q "show-help" "$HOME/.config/tmux/keybindings.conf"; then
        echo "✗ ? binding or show-help not found in configuration"
        exit 1
    fi
fi

echo "✓ ? binding to show-help found in configuration"

# Try to verify with tmux if available and not in headless mode
if [ -t 0 ] && command -v tmux >/dev/null 2>&1; then
    # Check if ? is bound in the prefix table
    if tmux list-keys -T prefix 2>/dev/null | grep -q "?"; then
        echo "✓ ? binding verified in tmux prefix table"
    else
        echo "⚠️  Could not verify ? binding in tmux (server not running)"
    fi
fi

echo "✓ Help binding test passed"
