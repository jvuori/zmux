#!/bin/bash

# Test that plain character keys are bound in lock mode

echo "Verification: Plain Character Keys in Lock Mode"
echo "=============================================="
echo ""

# Count total bindings
TOTAL=$(tmux list-keys -T locked 2>/dev/null | wc -l)
echo "Total keys bound: $TOTAL"
echo ""

# Verify plain letters are bound
PLAIN_LOWER=$(tmux list-keys -T locked 2>/dev/null | grep -E "^bind-key -T locked [a-z] " | wc -l)
PLAIN_UPPER=$(tmux list-keys -T locked 2>/dev/null | grep -E "^bind-key -T locked [A-Z] " | wc -l)
PLAIN_TOTAL=$((PLAIN_LOWER + PLAIN_UPPER))

echo "Plain letters bound:"
echo "  Lowercase (a-z): $PLAIN_LOWER"
echo "  Uppercase (A-Z): $PLAIN_UPPER"
echo "  Total: $PLAIN_TOTAL"
echo ""

if [ "$PLAIN_TOTAL" = "52" ]; then
    echo "✓ SUCCESS: All 52 plain letters are bound!"
else
    echo "✗ FAILURE: Only $PLAIN_TOTAL/52 plain letters bound"
    exit 1
fi

echo ""
echo "Sample of bound plain character keys:"
tmux list-keys -T locked 2>/dev/null | grep -E "^bind-key -T locked [a-z] " | head -5
echo ""

echo "Ctrl+g binding (enter lock mode):"
tmux list-keys 2>/dev/null | grep "root.*C-g"
echo ""

echo "Ready to test:"
echo "  1. Open a tmux session"
echo "  2. Press Ctrl+g to enter lock mode"
echo "  3. Type any letters/numbers - they should go to the app"
echo "  4. Press Ctrl+g again to exit"
