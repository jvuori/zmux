#!/usr/bin/env bash
# ============================================================================
# Lock Mode Testing Script
# ============================================================================
# This script demonstrates the lock mode functionality

echo "🔒 Testing Lock Mode Functionality"
echo "=================================="
echo ""
echo "Lock mode is a Zellij-like feature that allows all keyboard input"
echo "to pass through to the application without being intercepted by tmux."
echo ""

# Test 1: Check if C-g binding exists
echo "Test 1: Checking C-g binding..."
if tmux list-keys -T root | grep -q "C-g.*toggle-lock-mode"; then
    echo "✅ C-g is properly bound to toggle lock mode"
else
    echo "❌ C-g binding not found"
fi

# Test 2: Check if toggle script exists
echo ""
echo "Test 2: Checking toggle script..."
if [ -x ~/.config/tmux/scripts/toggle-lock-mode.sh ]; then
    echo "✅ Toggle script exists and is executable"
else
    echo "❌ Toggle script not found or not executable"
fi

# Test 3: Check if locked key table exists
echo ""
echo "Test 3: Checking locked key table..."
if tmux list-keys -T locked | grep -q "C-g.*toggle-lock-mode"; then
    echo "✅ Locked key table has C-g binding"
else
    echo "❌ Locked key table not properly configured"
fi

# Test 4: Check status bar configuration for lock indicator
echo ""
echo "Test 4: Checking status bar configuration..."
if grep -q "@lock_mode" ~/.config/tmux/statusbar.conf; then
    echo "✅ Status bar configured to show lock indicator"
else
    echo "❌ Status bar lock indicator not configured"
fi

echo ""
echo "🎯 Manual Testing Steps:"
echo "1. Open a tmux session: tmux"
echo "2. Press Ctrl+g to toggle lock mode ON"
echo "3. Look for 🔒 LOCK indicator in the status bar (top left)"
echo "4. Try pressing Ctrl+p - it should NOT enter pane mode (it will be sent to app)"
echo "5. Try pressing Ctrl+g again - lock mode should toggle OFF"
echo "6. Now Ctrl+p should work again to enter pane mode"
echo ""
echo "✨ Features:"
echo "   - Press Ctrl+g to toggle lock mode"
echo "   - When locked: All input goes to application"
echo "   - When unlocked: Normal tmux keybindings work"
echo "   - Status bar shows 🔒 LOCK when active"
echo "   - Only Ctrl+g works when locked (to toggle back)"
