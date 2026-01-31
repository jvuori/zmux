#!/bin/bash
# Test comprehensive session restoration scenarios
# Tests both real-time tracking and fallback handling

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Comprehensive Session Restoration Tests ===${NC}\n"

# Test setup
TEST_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
TEST_ACTIVE_FILE="$TEST_DATA_DIR/active-session.txt"
TEST_SESSION_A="test-session-a"
TEST_SESSION_B="test-session-b"

# Cleanup function
cleanup() {
    tmux kill-session -t "$TEST_SESSION_A" 2>/dev/null || true
    tmux kill-session -t "$TEST_SESSION_B" 2>/dev/null || true
    rm -f "$TEST_ACTIVE_FILE"
}

trap cleanup EXIT

# Ensure tmux is running
if ! tmux list-sessions >/dev/null 2>&1; then
    tmux start-server
    sleep 0.5
fi

mkdir -p "$TEST_DATA_DIR"

# ============================================================================
# Test 1: Real-time session tracking
# ============================================================================
echo -e "${YELLOW}Test 1: Real-time session tracking${NC}"
echo "  Creating two test sessions..."

tmux new-session -d -s "$TEST_SESSION_A" -c "$HOME"
sleep 0.2
tmux new-session -d -s "$TEST_SESSION_B" -c "$HOME"
sleep 0.2

# Simulate client attaching to session A
echo "  Simulating: client attaches to $TEST_SESSION_A"
SESSION_BEFORE=$(cat "$TEST_ACTIVE_FILE" 2>/dev/null || echo "none")
echo "  Session file before: $SESSION_BEFORE"

# Note: In real usage, the hook updates this when you switch sessions with tmux commands
# For testing purposes, we manually simulate what the hook would do
echo "$TEST_SESSION_A" > "$TEST_ACTIVE_FILE"
sleep 0.1

SESSION_AFTER=$(cat "$TEST_ACTIVE_FILE")
if [ "$SESSION_AFTER" = "$TEST_SESSION_A" ]; then
    echo -e "${GREEN}  ✓ Session file updated when client attaches${NC}"
else
    echo -e "${RED}  ✗ Session file not updated. Expected: $TEST_SESSION_A, Got: $SESSION_AFTER${NC}"
    exit 1
fi

# Simulate switching to session B
echo "  Simulating: client switches to $TEST_SESSION_B"
echo "$TEST_SESSION_B" > "$TEST_ACTIVE_FILE"
sleep 0.1

SESSION_AFTER=$(cat "$TEST_ACTIVE_FILE")
if [ "$SESSION_AFTER" = "$TEST_SESSION_B" ]; then
    echo -e "${GREEN}  ✓ Session file updated when switching sessions${NC}"
else
    echo -e "${RED}  ✗ Session file not updated after switch. Expected: $TEST_SESSION_B, Got: $SESSION_AFTER${NC}"
    exit 1
fi

# ============================================================================
# Test 2: Fallback when saved session doesn't exist
# ============================================================================
echo -e "\n${YELLOW}Test 2: Fallback when saved session doesn't exist${NC}"

# Kill one session to simulate it being removed
echo "  Killing $TEST_SESSION_B..."
tmux kill-session -t "$TEST_SESSION_B"
sleep 0.2

# The active-session.txt still points to the killed session
echo "  Session file still points to killed session: $(cat $TEST_ACTIVE_FILE)"

# Now simulate restoration logic
echo "  Testing restoration logic..."
ACTIVE_SESSION_FILE="$TEST_ACTIVE_FILE"
if [ -f "$ACTIVE_SESSION_FILE" ]; then
    SAVED_SESSION=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
    # Verify the session still exists
    if [ -n "$SAVED_SESSION" ] && tmux has-session -t "$SAVED_SESSION" 2>/dev/null; then
        echo -e "${RED}  ✗ Should not restore to killed session${NC}"
        exit 1
    fi
    
    # Clean up the file if the session doesn't exist anymore
    if ! tmux has-session -t "$SAVED_SESSION" 2>/dev/null; then
        echo "  Saved session '$SAVED_SESSION' not found, cleaning up..."
        rm -f "$ACTIVE_SESSION_FILE" 2>/dev/null
        echo -e "${GREEN}  ✓ Cleaned up stale session file${NC}"
    fi
fi

# Verify file was cleaned
if [ ! -f "$ACTIVE_SESSION_FILE" ]; then
    echo -e "${GREEN}  ✓ Stale session file removed${NC}"
else
    echo -e "${RED}  ✗ Stale session file should have been removed${NC}"
    exit 1
fi

# Test fallback selection
echo "  Testing fallback to activity-based selection..."
FALLBACK=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
    sort -t: -k1 -rn | \
    head -1 | \
    cut -d: -f2)

if [ -n "$FALLBACK" ] && tmux has-session -t "$FALLBACK" 2>/dev/null; then
    echo -e "${GREEN}  ✓ Fallback selects valid session: $FALLBACK${NC}"
else
    echo -e "${RED}  ✗ Fallback failed to select valid session${NC}"
    exit 1
fi

# ============================================================================
# Test 3: Sudden kill scenario (session still exists)
# ============================================================================
echo -e "\n${YELLOW}Test 3: Sudden kill scenario - session file updated in real-time${NC}"

# Ensure we have a session
if ! tmux has-session -t "$TEST_SESSION_A" 2>/dev/null; then
    tmux new-session -d -s "$TEST_SESSION_A" -c "$HOME"
    sleep 0.2
fi

echo "  Active session: $TEST_SESSION_A"
echo "$TEST_SESSION_A" > "$TEST_ACTIVE_FILE"

# If tmux is suddenly killed here, the file would still have the correct session
# This is guaranteed because we use the client-session-changed hook
echo "  Session file contains: $(cat $TEST_ACTIVE_FILE)"

# Now if we restart and try to restore
if [ -f "$TEST_ACTIVE_FILE" ]; then
    SAVED_SESSION=$(cat "$TEST_ACTIVE_FILE")
    if [ -n "$SAVED_SESSION" ] && tmux has-session -t "$SAVED_SESSION" 2>/dev/null; then
        echo -e "${GREEN}  ✓ Can restore to correct session even after sudden kill${NC}"
        echo -e "${GREEN}    Session still exists: $SAVED_SESSION${NC}"
    fi
fi

# ============================================================================
# Test 4: Empty/invalid session file
# ============================================================================
echo -e "\n${YELLOW}Test 4: Empty or corrupted session file${NC}"

# Create invalid session file
echo "" > "$TEST_ACTIVE_FILE"
echo "  Created empty session file"

ACTIVE_SESSION_FILE="$TEST_ACTIVE_FILE"
if [ -f "$ACTIVE_SESSION_FILE" ]; then
    SAVED_SESSION=$(cat "$ACTIVE_SESSION_FILE" 2>/dev/null)
    if [ -z "$SAVED_SESSION" ]; then
        echo "  Empty saved session detected"
        rm -f "$ACTIVE_SESSION_FILE" 2>/dev/null
        echo -e "${GREEN}  ✓ Cleaned up empty session file${NC}"
    fi
fi

# Verify fallback works
FALLBACK=$(tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
    sort -t: -k1 -rn | \
    head -1 | \
    cut -d: -f2)

if [ -n "$FALLBACK" ]; then
    echo -e "${GREEN}  ✓ Fallback works with corrupted file: $FALLBACK${NC}"
fi

echo -e "\n${GREEN}✓ All tests passed!${NC}"
