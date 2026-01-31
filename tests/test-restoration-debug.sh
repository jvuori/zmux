#!/bin/bash
# Test the session restoration logic

echo "=== Testing Session Restoration Logic ==="
echo

# Check the active session file
ACTIVE_SESSION_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/active-session.txt"
echo "1. Checking active session file..."
if [ -f "$ACTIVE_SESSION_FILE" ]; then
    SAVED_SESSION=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
    echo "   File exists: YES"
    echo "   Contents: '$SAVED_SESSION'"
    
    # Check if the session exists
    if tmux has-session -t "$SAVED_SESSION" 2>/dev/null; then
        echo "   Session '$SAVED_SESSION' exists: YES"
        echo "   ✓ Should restore to: $SAVED_SESSION"
    else
        echo "   Session '$SAVED_SESSION' exists: NO"
        echo "   ✗ Would use fallback"
    fi
else
    echo "   File exists: NO"
    echo "   Would use fallback (activity-based)"
fi

echo
echo "2. Current sessions:"
tmux list-sessions -F "   #{session_name} - activity:#{session_activity} - attached:#{session_attached}"

echo
echo "3. Fallback would select:"
FALLBACK=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
    sort -t: -k1 -rn | \
    head -1 | \
    cut -d: -f2)
echo "   $FALLBACK (most recent activity)"

echo
echo "4. Currently attached:"
tmux list-sessions | grep attached | awk '{print "   " $1}' | sed 's/://'
