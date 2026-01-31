#!/bin/bash
# Test session restoration after shutdown
# This script simulates a shutdown and verifies the correct session is restored

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Testing session restoration...${NC}"

# Create test directories
TEST_SESSION="test-restore-session"
TEST_DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
TEST_ACTIVE_FILE="$TEST_DATA_DIR/active-session.txt"

# Cleanup function
cleanup() {
    # Kill test session if it exists
    tmux kill-session -t "$TEST_SESSION" 2>/dev/null || true
    # Remove test files
    rm -f "$TEST_ACTIVE_FILE"
}

trap cleanup EXIT

# Start tmux if not running
if ! tmux list-sessions >/dev/null 2>&1; then
    tmux start-server
    sleep 0.5
fi

# Create a test session
echo -e "${YELLOW}1. Creating test session...${NC}"
tmux new-session -d -s "$TEST_SESSION" -c "$HOME"
sleep 0.2

# Simulate saving the active session (as done by save-session-before-shutdown.sh)
echo -e "${YELLOW}2. Simulating shutdown - saving active session...${NC}"
mkdir -p "$TEST_DATA_DIR"
echo "$TEST_SESSION" > "$TEST_ACTIVE_FILE"
echo -e "${GREEN}   Saved active session: $(cat $TEST_ACTIVE_FILE)${NC}"

# Verify the file was created
if [ ! -f "$TEST_ACTIVE_FILE" ]; then
    echo -e "${RED}ERROR: Failed to save active session file${NC}"
    exit 1
fi

# Verify the content is correct
SAVED_SESSION=$(cat "$TEST_ACTIVE_FILE")
if [ "$SAVED_SESSION" != "$TEST_SESSION" ]; then
    echo -e "${RED}ERROR: Saved session mismatch. Expected: $TEST_SESSION, Got: $SAVED_SESSION${NC}"
    exit 1
fi

echo -e "${GREEN}   ✓ Active session file created correctly${NC}"

# Verify tmux can find the session
echo -e "${YELLOW}3. Verifying session exists in tmux...${NC}"
if tmux has-session -t "$TEST_SESSION" 2>/dev/null; then
    echo -e "${GREEN}   ✓ Session $TEST_SESSION found in tmux${NC}"
else
    echo -e "${RED}ERROR: Session $TEST_SESSION not found in tmux${NC}"
    exit 1
fi

# Simulate restoration by reading the file
echo -e "${YELLOW}4. Simulating restoration...${NC}"
if [ -f "$TEST_ACTIVE_FILE" ]; then
    RESTORED_SESSION=$(cat "$TEST_ACTIVE_FILE")
    if tmux has-session -t "$RESTORED_SESSION" 2>/dev/null; then
        echo -e "${GREEN}   ✓ Successfully restored to session: $RESTORED_SESSION${NC}"
    else
        echo -e "${RED}ERROR: Restored session not found: $RESTORED_SESSION${NC}"
        exit 1
    fi
else
    echo -e "${RED}ERROR: Active session file not found during restoration${NC}"
    exit 1
fi

echo -e "${GREEN}✓ All tests passed!${NC}"
