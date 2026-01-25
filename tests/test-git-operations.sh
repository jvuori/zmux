#!/bin/bash
# Test git operations functionality
# Verifies that git branch and commit selection scripts work

set -e

echo "Testing git operations..."

# Create a temporary git repository for testing
TEST_REPO=$(mktemp -d)
cd "$TEST_REPO"

git init -q
git config user.email "test@example.com"
git config user.name "Test User"

# Create some commits
echo "test1" > file1.txt
git add file1.txt
git commit -q -m "First commit"

echo "test2" > file2.txt
git add file2.txt
git commit -q -m "Second commit"

echo "test3" > file3.txt
git add file3.txt
git commit -q -m "Third commit"

# Create a branch
git checkout -q -b feature-branch
echo "feature" > feature.txt
git add feature.txt
git commit -q -m "Feature commit"
git checkout -q master

echo "✓ Test repository created"

# Test git branch script exists and is executable
BRANCH_SCRIPT="$HOME/.config/tmux/scripts/fzf-git-branch.sh"
if [ ! -x "$BRANCH_SCRIPT" ]; then
    echo "ERROR: Branch script not executable: $BRANCH_SCRIPT"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Branch script exists and is executable"

# Test that branch script can list branches
# We'll run it with empty input to avoid fzf interaction
BRANCH_LIST=$(cd "$TEST_REPO" && bash "$BRANCH_SCRIPT" 2>&1 <<< "" || true)

# The script should at least try to show branches (might exit on fzf abort, that's ok)
# Just verify it doesn't crash with errors about git
if echo "$BRANCH_LIST" | grep -qi "not.*git.*repository"; then
    echo "ERROR: Branch script failed to detect git repository"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Branch script can access git repository"

# Test git commits script exists and is executable
COMMITS_SCRIPT="$HOME/.config/tmux/scripts/fzf-git-commits.sh"
if [ ! -x "$COMMITS_SCRIPT" ]; then
    echo "ERROR: Commits script not executable: $COMMITS_SCRIPT"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Commits script exists and is executable"

# Test that commits script can list commits
COMMITS_LIST=$(cd "$TEST_REPO" && bash "$COMMITS_SCRIPT" 2>&1 <<< "" || true)

# The script should at least try to show commits
if echo "$COMMITS_LIST" | grep -qi "not.*git.*repository\|not on a git branch"; then
    echo "ERROR: Commits script failed to access git repository"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Commits script can access git repository"

# Test git popup wrapper scripts exist
BRANCH_POPUP="$HOME/.config/tmux/scripts/git-branch-popup.sh"
COMMITS_POPUP="$HOME/.config/tmux/scripts/git-commits-popup.sh"

if [ ! -x "$BRANCH_POPUP" ]; then
    echo "ERROR: Branch popup script not executable: $BRANCH_POPUP"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

if [ ! -x "$COMMITS_POPUP" ]; then
    echo "ERROR: Commits popup script not executable: $COMMITS_POPUP"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Popup wrapper scripts exist and are executable"

# Clean up
cd - >/dev/null
rm -rf "$TEST_REPO"

echo ""
echo "All git operations tests passed!"
exit 0
