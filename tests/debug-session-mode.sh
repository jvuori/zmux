#!/bin/bash
# Debug script for session mode issues

echo "🔍 Debugging session mode (Ctrl+o -> w)"
echo ""

echo "1. Checking Ctrl+o binding:"
if tmux list-keys | grep -q "root.*C-o.*session"; then
    echo "   ✅ Ctrl+o is bound to enter session mode"
    tmux list-keys | grep "root.*C-o"
else
    echo "   ❌ Ctrl+o is NOT bound correctly"
fi

echo ""
echo "2. Checking session mode 'w' binding:"
if tmux list-keys -T session | grep -q " w "; then
    echo "   ✅ 'w' is bound in session mode"
    tmux list-keys -T session | grep " w "
else
    echo "   ❌ 'w' is NOT bound in session mode"
fi

echo ""
echo "3. Testing script:"
if [ -x ~/.config/tmux/scripts/session-switcher.sh ]; then
    echo "   ✅ Script is executable"
else
    echo "   ❌ Script is NOT executable"
fi

echo ""
echo "4. Manual test instructions:"
echo "   a) In tmux, press Ctrl+o"
echo "   b) You should now be in session mode (no visual indicator, but you are)"
echo "   c) Press 'w' (lowercase)"
echo "   d) The session switcher should run"
echo ""
echo "5. If it still doesn't work:"
echo "   - Make sure you're not in a program that captures Ctrl+o (like vim insert mode)"
echo "   - Try: Ctrl+o, wait 1 second, then press 'w'"
echo "   - Check if your shell is intercepting Ctrl+o"
echo ""
echo "6. Test the binding directly:"
echo "   Run: tmux send-keys C-o w"
echo "   (This simulates pressing Ctrl+o then w)"

