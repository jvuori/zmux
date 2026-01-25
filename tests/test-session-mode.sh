#!/bin/bash
# Quick test script to verify session mode bindings

echo "Testing session mode bindings..."
echo ""

echo "1. Checking if Ctrl+o enters session mode:"
tmux list-keys -n | grep "C-o" || echo "   ❌ Ctrl+o binding not found"

echo ""
echo "2. Checking session mode bindings:"
tmux list-keys -T session | head -10

echo ""
echo "3. Testing the binding directly:"
echo "   Run this in tmux:"
echo "   - Press Ctrl+o (should enter session mode)"
echo "   - Press w (should run session switcher)"
echo ""
echo "4. If it doesn't work, try:"
echo "   - Press Ctrl+o"
echo "   - Wait a moment"
echo "   - Press w"
echo ""
echo "5. To verify you're in session mode, check the status bar or try:"
echo "   - Press Ctrl+o"
echo "   - Press Ctrl+o again (should exit session mode)"

