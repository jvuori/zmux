#!/bin/bash
# Test that Ctrl+A ? help binding works

set -e

echo "Testing Ctrl+A ? help binding..."

# Check if ? is bound in the prefix table
if tmux list-keys -T prefix | grep -q "?"; then
    echo "✓ ? binding exists in prefix table"
else
    echo "✗ ? binding missing from prefix table"
    exit 1
fi

# Check if it's bound to show-help
if tmux list-keys -T prefix | grep "?" | grep -q "show-help"; then
    echo "✓ ? is bound to show-help script"
else
    echo "✗ ? is not bound to show-help"
    exit 1
fi

# Test with a temporary session
TEST_SESSION="help_test_$$"
tmux new-session -d -s "$TEST_SESSION" -c /tmp

# Try the key binding
tmux send-keys -t "$TEST_SESSION" "C-a" "?"
sleep 0.2

tmux kill-session -t "$TEST_SESSION"

echo "✓ All tests passed"
