#!/bin/bash
# ============================================================================
# Test: Lock Mode Esc Key Behavior
# ============================================================================
# Tests that Esc key does NOT exit lock mode
# Also tests other special keys that might exit lock mode

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

test_key_in_locked() {
    local key=$1
    local key_name=$2
    
    # Create test session
    tmux new-session -d -s key_test_$$
    
    # Enter lock mode by switching table and setting variable
    tmux switch-client -T locked -t key_test_$$ 2>/dev/null || true
    tmux set-option -t key_test_$$ @lock_mode 1
    
    # Verify we're in lock mode
    BEFORE=$(tmux display-message -t key_test_$$ -p '#{client_key_table}')
    if [ "$BEFORE" != "locked" ]; then
        echo -e "${RED}✗ FAIL${NC}: Could not enter locked mode for $key_name test"
        tmux kill-session -t key_test_$$ 2>/dev/null || true
        FAIL=$((FAIL + 1))
        return 1
    fi
    
    # Send the key
    tmux send-keys -t key_test_$$ "$key"
    
    # Wait a bit for any async processing
    sleep 0.2
    
    # Check if still in lock mode
    AFTER=$(tmux display-message -t key_test_$$ -p '#{client_key_table}')
    
    # Clean up
    tmux kill-session -t key_test_$$ 2>/dev/null || true
    
    # Verify result
    if [ "$AFTER" = "locked" ]; then
        echo -e "${GREEN}✓ PASS${NC}: $key_name did not exit lock mode"
        PASS=$((PASS + 1))
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}: $key_name exited lock mode (BUG!)"
        echo "  Expected: locked, Got: $AFTER"
        FAIL=$((FAIL + 1))
        return 1
    fi
}

echo "============================================================================"
echo "Test: Lock Mode Should NOT Exit on Special Keys"
echo "============================================================================"
echo ""

# Test various keys that might incorrectly exit lock mode
test_key_in_locked "Escape" "Escape"
test_key_in_locked "C-c" "Ctrl+C"
test_key_in_locked "Tab" "Tab"

echo ""
echo "============================================================================"
echo "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}"
echo "============================================================================"

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi

exit 0

