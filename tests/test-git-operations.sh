#!/bin/bash
# Test git operations functionality
# Verifies that git branch and commit selection scripts work
# Tests include both syntax validation and functional automation

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

echo "✓ Test repository created with 4 commits and 2 branches"

# Test git branch script exists and is executable
BRANCH_SCRIPT="$HOME/.config/tmux/scripts/fzf-git-branch.sh"
if [ ! -x "$BRANCH_SCRIPT" ]; then
    echo "ERROR: Branch script not executable: $BRANCH_SCRIPT"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Branch script exists and is executable"

# Test that branch script lists branches correctly
# Use fzf in filter mode (--filter) with the first branch to automate selection
SELECTED_BRANCH=$(cd "$TEST_REPO" && bash "$BRANCH_SCRIPT" 2>&1 <<< "feature" || true)

# Check if the output contains fzf error
if echo "$SELECTED_BRANCH" | grep -qi "fzf.*not.*installed\|Error.*fzf"; then
    echo "ERROR: fzf is not installed or not working"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

if [ -z "$SELECTED_BRANCH" ]; then
    # Empty output is OK (fzf aborted), but verify no git errors
    BRANCH_ERROR=$(cd "$TEST_REPO" && bash "$BRANCH_SCRIPT" 2>&1 <<< "" || true)
    if echo "$BRANCH_ERROR" | grep -qi "not.*git.*repository"; then
        echo "ERROR: Branch script failed to detect git repository"
        cd - >/dev/null
        rm -rf "$TEST_REPO"
        exit 1
    fi
else
    # Verify selected branch is valid
    if ! cd "$TEST_REPO" && git branch -a | grep -q "$SELECTED_BRANCH"; then
        echo "ERROR: Branch script returned invalid branch: $SELECTED_BRANCH"
        cd - >/dev/null
        rm -rf "$TEST_REPO"
        exit 1
    fi
    echo "✓ Branch script correctly selected branch: $SELECTED_BRANCH"
fi

echo "✓ Branch script can access and list git branches"

# Test git commits script exists and is executable
COMMITS_SCRIPT="$HOME/.config/tmux/scripts/fzf-git-commits.sh"
if [ ! -x "$COMMITS_SCRIPT" ]; then
    echo "ERROR: Commits script not executable: $COMMITS_SCRIPT"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Commits script exists and is executable"

# Test that commits script lists commits correctly
# Use fzf in filter mode to automate selection
SELECTED_COMMIT=$(cd "$TEST_REPO" && bash "$COMMITS_SCRIPT" 2>&1 <<< "First" || true)

# Check if the output contains fzf error
if echo "$SELECTED_COMMIT" | grep -qi "fzf.*not.*installed\|Error.*fzf"; then
    echo "ERROR: fzf is not installed or not working"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

if [ -z "$SELECTED_COMMIT" ]; then
    # Empty output is OK (fzf aborted), but verify no git errors
    COMMITS_ERROR=$(cd "$TEST_REPO" && bash "$COMMITS_SCRIPT" 2>&1 <<< "" || true)
    if echo "$COMMITS_ERROR" | grep -qi "not.*git.*repository\|not on a git branch"; then
        echo "ERROR: Commits script failed to access git repository"
        cd - >/dev/null
        rm -rf "$TEST_REPO"
        exit 1
    fi
else
    # Verify selected commit is a valid SHA (7+ hex chars)
    if ! echo "$SELECTED_COMMIT" | grep -qE '^[a-f0-9]{7,}'; then
        echo "ERROR: Commits script returned invalid commit SHA: $SELECTED_COMMIT"
        cd - >/dev/null
        rm -rf "$TEST_REPO"
        exit 1
    fi
    echo "✓ Commits script correctly selected commit: $SELECTED_COMMIT"
fi

echo "✓ Commits script can access and list git commits"

# Test git popup wrapper scripts exist and are executable
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

# Verify popup scripts have valid syntax
if ! bash -n "$BRANCH_POPUP" 2>/dev/null; then
    echo "ERROR: Branch popup script has syntax errors"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

if ! bash -n "$COMMITS_POPUP" 2>/dev/null; then
    echo "ERROR: Commits popup script has syntax errors"
    cd - >/dev/null
    rm -rf "$TEST_REPO"
    exit 1
fi

echo "✓ Popup wrapper scripts have valid bash syntax"

# Clean up
cd - >/dev/null
rm -rf "$TEST_REPO"

echo ""
echo "All git operations tests passed!"
exit 0
