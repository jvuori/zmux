#!/bin/bash
# ============================================================================
# Comprehensive zmux Test Suite
# ============================================================================
# Tests all major functionality: session, tabs, panes, lock mode, help

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
SKIP=0

# Test helpers
pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    PASS=$((PASS + 1))
}

fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    echo -e "  ${YELLOW}Reason: $2${NC}"
    FAIL=$((FAIL + 1))
}

skip() {
    echo -e "${YELLOW}○ SKIP${NC}: $1"
    SKIP=$((SKIP + 1))
}

section() {
    echo ""
    echo "============================================================================"
    echo "$1"
    echo "============================================================================"
}

# Ensure clean state
cleanup() {
    tmux kill-session -t test_session 2>/dev/null || true
}
trap cleanup EXIT

# ============================================================================
section "1. Configuration Tests"
# ============================================================================

# Test 1.1: Check if keybindings.conf is loaded
if tmux list-keys -T root | grep -q "C-p"; then
    pass "Keybindings loaded - C-p (pane mode) registered"
else
    fail "Keybindings not loaded" "C-p not found in root key table"
fi

# Test 1.2: Check if lock mode bindings exist
if tmux list-keys -T root | grep -q "C-g"; then
    pass "Lock mode keybinding exists (C-g in root)"
else
    fail "Lock mode keybinding missing" "C-g not found in root table"
fi

# Test 1.3: Check locked table has bindings
LOCKED_BINDINGS=$(tmux list-keys -T locked 2>/dev/null | wc -l)
if [ "$LOCKED_BINDINGS" -gt 5 ]; then
    pass "Locked table has $LOCKED_BINDINGS bindings"
else
    fail "Locked table incomplete" "Only $LOCKED_BINDINGS bindings found, expected >5"
fi

# Test 1.4: Check prefix is set to Ctrl+a
PREFIX=$(tmux show-options -g prefix | awk '{print $2}')
if [ "$PREFIX" = "C-a" ]; then
    pass "Prefix is set to Ctrl+a"
else
    fail "Prefix is wrong" "Expected C-a, got $PREFIX"
fi

# Test 1.5: Check help binding exists
if tmux list-keys | grep -q "bind-key.*\?.*show-help"; then
    pass "Help binding exists (Ctrl+a ?)"
else
    fail "Help binding missing" "No ? binding found for show-help"
fi

# ============================================================================
section "2. Pane Mode Tests"
# ============================================================================

# Create test session
tmux new-session -d -s test_session -x 120 -y 30

# Test 2.1: Check pane table has bindings
PANE_BINDINGS=$(tmux list-keys -T pane 2>/dev/null | wc -l)
if [ "$PANE_BINDINGS" -gt 5 ]; then
    pass "Pane table has $PANE_BINDINGS bindings"
else
    fail "Pane table incomplete" "Only $PANE_BINDINGS bindings found"
fi

# Test 2.2: Pane split horizontal exists
if tmux list-keys -T pane | grep -qE 'd|r.*split.*-h'; then
    pass "Pane horizontal split binding exists"
else
    fail "Pane horizontal split missing" "No 'r' or 'd' binding for horizontal split"
fi

# Test 2.3: Pane split vertical exists
if tmux list-keys -T pane | grep -qE 'n|e.*split.*-v'; then
    pass "Pane vertical split binding exists"
else
    fail "Pane vertical split missing" "No 'n' or 'e' binding for vertical split"
fi

# Test 2.4: Pane navigation exists
if tmux list-keys -T pane | grep -q "select-pane"; then
    pass "Pane navigation bindings exist"
else
    fail "Pane navigation missing" "No select-pane bindings found"
fi

# ============================================================================
section "3. Tab Mode Tests"
# ============================================================================

# Test 3.1: Check tab table has bindings
TAB_BINDINGS=$(tmux list-keys -T tab 2>/dev/null | wc -l)
if [ "$TAB_BINDINGS" -gt 3 ]; then
    pass "Tab table has $TAB_BINDINGS bindings"
else
    fail "Tab table incomplete" "Only $TAB_BINDINGS bindings found"
fi

# Test 3.2: New tab binding exists
if tmux list-keys -T tab | grep -q "new-window"; then
    pass "New tab binding exists"
else
    fail "New tab binding missing" "No new-window binding in tab table"
fi

# Test 3.3: Tab navigation exists
if tmux list-keys -T tab | grep -qE "select-window|next-window|previous-window"; then
    pass "Tab navigation bindings exist"
else
    fail "Tab navigation missing" "No tab navigation bindings found"
fi

# ============================================================================
section "4. Session Mode Tests"
# ============================================================================

# Test 4.1: Check session table has bindings
SESSION_BINDINGS=$(tmux list-keys -T session 2>/dev/null | wc -l)
if [ "$SESSION_BINDINGS" -gt 0 ]; then
    pass "Session table has $SESSION_BINDINGS bindings"
else
    fail "Session table missing" "No session table bindings found"
fi

# Test 4.2: Session switcher script exists
if [ -f ~/.config/tmux/scripts/session-switcher.sh ]; then
    pass "Session switcher script exists"
else
    fail "Session switcher script missing" "~/.config/tmux/scripts/session-switcher.sh not found"
fi

# ============================================================================
section "5. Resize Mode Tests"
# ============================================================================

# Test 5.1: Check resize table has bindings
RESIZE_BINDINGS=$(tmux list-keys -T resize 2>/dev/null | wc -l)
if [ "$RESIZE_BINDINGS" -gt 3 ]; then
    pass "Resize table has $RESIZE_BINDINGS bindings"
else
    fail "Resize table incomplete" "Only $RESIZE_BINDINGS bindings found"
fi

# Test 5.2: Resize pane bindings exist
if tmux list-keys -T resize | grep -q "resize-pane"; then
    pass "Resize pane bindings exist"
else
    fail "Resize pane bindings missing" "No resize-pane bindings found"
fi

# ============================================================================
section "6. Lock Mode Tests"
# ============================================================================

# Test 6.1: Lock mode indicator script exists
if [ -f ~/.config/tmux/scripts/lock-mode-indicator.sh ]; then
    pass "Lock mode indicator script exists"
else
    fail "Lock mode indicator script missing" "~/.config/tmux/scripts/lock-mode-indicator.sh not found"
fi

# Test 6.2: Lock mode indicator is executable
if [ -x ~/.config/tmux/scripts/lock-mode-indicator.sh ]; then
    pass "Lock mode indicator script is executable"
else
    fail "Lock mode indicator not executable" "Missing execute permission"
fi

# Test 6.3: C-g binding has switch-client -T locked
CG_BINDING=$(tmux list-keys -T root | grep "C-g")
if echo "$CG_BINDING" | grep -q "switch-client -T locked"; then
    pass "C-g binding switches to locked table"
else
    fail "C-g binding incomplete" "No 'switch-client -T locked' in C-g binding"
fi

# Test 6.4: Locked table C-p binding keeps locked state
CP_LOCKED=$(tmux list-keys -T locked | grep "C-p")
if echo "$CP_LOCKED" | grep -q "switch-client -T locked"; then
    pass "Locked C-p maintains locked state"
else
    fail "Locked C-p doesn't maintain state" "Missing 'switch-client -T locked'"
fi

# Test 6.5: Lock icon in status bar configuration
STATUS_LEFT=$(tmux show-options -g status-left 2>/dev/null)
if echo "$STATUS_LEFT" | grep -q "lock-mode-indicator"; then
    pass "Lock indicator in status-left config"
else
    fail "Lock indicator not in status bar" "lock-mode-indicator.sh not in status-left"
fi

# Test 6.6: Test entering locked mode manually
tmux switch-client -T locked 2>/dev/null || true
CURRENT_TABLE=$(tmux display-message -p '#{client_key_table}')
if [ "$CURRENT_TABLE" = "locked" ]; then
    pass "Can switch to locked key table"
else
    fail "Cannot switch to locked table" "Expected 'locked', got '$CURRENT_TABLE'"
fi

# Test 6.7: Verify locked table persists after C-p (simulated)
# Note: send-keys goes to the pane, not the key handler
# This test verifies the binding structure is correct
if tmux list-keys -T locked | grep "C-p" | grep -q "switch-client -T locked"; then
    pass "Locked C-p binding structure is correct"
    tmux switch-client -T root  # Reset
else
    fail "Locked C-p binding structure wrong" "Should have switch-client -T locked"
    tmux switch-client -T root  # Reset
fi

# ============================================================================
section "7. Help System Tests"
# ============================================================================

# Test 7.1: Help script exists
if [ -f ~/.config/tmux/scripts/show-help.sh ]; then
    pass "Help script exists"
else
    fail "Help script missing" "~/.config/tmux/scripts/show-help.sh not found"
fi

# Test 7.2: Help script is executable
if [ -x ~/.config/tmux/scripts/show-help.sh ]; then
    pass "Help script is executable"
else
    fail "Help script not executable" "Missing execute permission"
fi

# Test 7.3: Help binding in prefix table
if tmux list-keys -T prefix | grep -q "?.*show-help\|?.*run-shell"; then
    pass "Help binding registered in prefix table"
else
    fail "Help binding not in prefix table" "? key not bound to show-help"
fi

# ============================================================================
section "8. Scripts Existence Tests"
# ============================================================================

SCRIPTS=(
    "toggle-lock-mode.sh"
    "lock-mode-indicator.sh"
    "show-help.sh"
    "session-switcher.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f ~/.config/tmux/scripts/"$script" ]; then
        pass "Script exists: $script"
    else
        fail "Script missing" "$script not found in ~/.config/tmux/scripts/"
    fi
done

# ============================================================================
section "Test Summary"
# ============================================================================

echo ""
echo "============================================================================"
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$SKIP skipped${NC}"
echo "============================================================================"

# Clean up test session
tmux kill-session -t test_session 2>/dev/null || true

# Exit with failure if any tests failed
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0
