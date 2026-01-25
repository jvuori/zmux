#!/bin/bash
# Main test runner for zmux
# Runs in Docker container to test installation and functionality

# Don't exit on error - we want to run all tests
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  ZMUX Installation & Functionality Tests${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local test_script="$2"
    
    echo -e "${YELLOW}Running: ${test_name}${NC}"
    
    if bash "$test_script"; then
        echo -e "${GREEN}✓ PASSED: ${test_name}${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}✗ FAILED: ${test_name}${NC}"
        ((TESTS_FAILED++))
    fi
    echo ""
}

# Run test suites
run_test "Installation Test" "tests/test-installation.sh"
run_test "Mode & Keybinding Test" "tests/test-modes.sh"
run_test "Git Operations Test" "tests/test-git-operations.sh"
run_test "Script Availability Test" "tests/test-scripts.sh"

# Summary
echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Test Summary${NC}"
echo -e "${YELLOW}========================================${NC}"
echo -e "${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "${RED}Failed: ${TESTS_FAILED}${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
