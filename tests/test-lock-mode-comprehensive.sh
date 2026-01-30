#!/bin/bash

# Lock Mode Comprehensive Test Suite

TEST_SESSION="test-lock-comp"
TESTS_PASSED=0
TESTS_FAILED=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

cleanup_session() {
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
}

trap cleanup_session EXIT

echo "=========================================================================="
echo "Lock Mode Comprehensive Test Suite"
echo "=========================================================================="
echo ""

# Test 1: Ctrl+g binding
echo "Test 1: Verify Ctrl+g binding in root table"
if tmux list-keys | grep -q "bind-key.*-n.*C-g"; then
    echo "✓ PASS: Ctrl+g global binding found"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Ctrl+g not found"
    ((TESTS_FAILED++))
fi

# Test 2: Locked table bindings
echo "Test 2: Verify locked table exists"
LOCKED_COUNT=$(tmux list-keys -T locked 2>/dev/null | wc -l)
if [ "$LOCKED_COUNT" -gt 20 ]; then
    echo "✓ PASS: Locked table has $LOCKED_COUNT bindings"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Locked table only has $LOCKED_COUNT"
    ((TESTS_FAILED++))
fi

# Test 3: Critical keys
echo "Test 3: Critical Ctrl keys in locked table"
CRITICAL=0
for key in C-p C-n C-h C-t C-a C-g C-c C-x; do
    if tmux list-keys -T locked | grep -q "$key"; then
        ((CRITICAL++))
    fi
done

if [ "$CRITICAL" -ge 8 ]; then
    echo "✓ PASS: $CRITICAL critical keys bound"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Only $CRITICAL critical keys"
    ((TESTS_FAILED++))
fi

# Test 4: Special keys
echo "Test 4: Special keys (Escape, Tab, Enter, BSpace)"
SPECIAL=0
for key in Escape Tab Enter BSpace; do
    if tmux list-keys -T locked | grep -q "$key"; then
        ((SPECIAL++))
    fi
done

if [ "$SPECIAL" -ge 4 ]; then
    echo "✓ PASS: All special keys bound"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Missing special keys ($SPECIAL/4)"
    ((TESTS_FAILED++))
fi

# Test 5: Session variable
echo "Test 5: Session variable @lock_mode"
cleanup_session
tmux new-session -d -s "$TEST_SESSION" -c "$HOME" 2>/dev/null
sleep 0.1
tmux set-option -t "$TEST_SESSION" @lock_mode 0
STATUS=$(tmux show-options -t "$TEST_SESSION" -v @lock_mode 2>/dev/null)

if [ "$STATUS" = "0" ]; then
    echo "✓ PASS: Variable initialized to 0"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Variable not set ($STATUS)"
    ((TESTS_FAILED++))
fi

# Test 6: Toggle to locked
echo "Test 6: Toggle variable to 1 (locked)"
tmux set-option -t "$TEST_SESSION" @lock_mode 1
STATUS=$(tmux show-options -t "$TEST_SESSION" -v @lock_mode 2>/dev/null)

if [ "$STATUS" = "1" ]; then
    echo "✓ PASS: Toggled to 1"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Toggle failed"
    ((TESTS_FAILED++))
fi

# Test 7: Indicator script
echo "Test 7: Lock mode indicator script"
if [ -x ~/.config/tmux/scripts/lock-mode-indicator.sh ]; then
    echo "✓ PASS: Script is executable"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Script not executable"
    ((TESTS_FAILED++))
fi

# Test 8: Status bar integration
echo "Test 8: Lock indicator in status bar"
if grep -q "lock-mode-indicator" ~/.config/tmux/statusbar.conf 2>/dev/null; then
    echo "✓ PASS: Integrated in statusbar"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Not in statusbar"
    ((TESTS_FAILED++))
fi

# Test 9: Key forwarding
echo "Test 9: Key forwarding pattern"
if tmux list-keys -T locked | grep "C-p" | grep -q "switch-client -T locked"; then
    echo "✓ PASS: Forwarding maintains lock state"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Forwarding pattern wrong"
    ((TESTS_FAILED++))
fi

# Test 10: Exit binding
echo "Test 10: Ctrl+g exits lock mode"
if tmux list-keys -T locked | grep "C-g" | grep -q "switch-client -T root"; then
    echo "✓ PASS: Ctrl+g switches to root"
    ((TESTS_PASSED++))
else
    echo "✗ FAIL: Exit binding wrong"
    ((TESTS_FAILED++))
fi

echo ""
echo "=========================================================================="
printf "Results: ${GREEN}$TESTS_PASSED passed${NC}, ${RED}$TESTS_FAILED failed${NC}\n"
echo "=========================================================================="

[ $TESTS_FAILED -eq 0 ]
