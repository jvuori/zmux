#!/bin/bash
# Test that all required scripts are available and executable
# Verifies script dependencies and permissions

set -e

echo "Testing script availability..."

SCRIPTS_DIR="$HOME/.config/tmux/scripts"

# List of all scripts that should be installed
REQUIRED_SCRIPTS=(
    "session-switcher.sh"
    "doctor.sh"
    "tmux-start.sh"
    "show-help.sh"
    "get-mode-help.sh"
    "capture-cursor-agent-session.sh"
    "toggle-lock-mode.sh"
    "lock-mode-indicator.sh"
    "swap-pane-left.sh"
    "swap-pane-right.sh"
    "session-killer.sh"
    "fzf-git-branch.sh"
    "git-branch-popup.sh"
    "fzf-git-commits.sh"
    "git-commits-popup.sh"
)

# Check each script
MISSING=0
NOT_EXECUTABLE=0

for script in "${REQUIRED_SCRIPTS[@]}"; do
    full_path="$SCRIPTS_DIR/$script"
    
    if [ ! -f "$full_path" ]; then
        echo "ERROR: Script missing: $script"
        ((MISSING++))
        continue
    fi
    
    if [ ! -x "$full_path" ]; then
        echo "ERROR: Script not executable: $script"
        ((NOT_EXECUTABLE++))
        continue
    fi
done

if [ $MISSING -gt 0 ]; then
    echo "ERROR: $MISSING scripts are missing"
    exit 1
fi

if [ $NOT_EXECUTABLE -gt 0 ]; then
    echo "ERROR: $NOT_EXECUTABLE scripts are not executable"
    exit 1
fi

echo "✓ All ${#REQUIRED_SCRIPTS[@]} required scripts present and executable"

# Test that key scripts can be sourced/executed without errors
# (basic syntax check)

# Test session-switcher can run with --help or similar
if ! bash "$SCRIPTS_DIR/session-switcher.sh" --help >/dev/null 2>&1; then
    # It's okay if it doesn't have --help, just check it doesn't have syntax errors
    if ! bash -n "$SCRIPTS_DIR/session-switcher.sh"; then
        echo "ERROR: session-switcher.sh has syntax errors"
        exit 1
    fi
fi

echo "✓ session-switcher.sh has valid syntax"

# Test doctor script
if ! bash -n "$SCRIPTS_DIR/doctor.sh"; then
    echo "ERROR: doctor.sh has syntax errors"
    exit 1
fi

echo "✓ doctor.sh has valid syntax"

# Test git scripts
if ! bash -n "$SCRIPTS_DIR/fzf-git-branch.sh"; then
    echo "ERROR: fzf-git-branch.sh has syntax errors"
    exit 1
fi

if ! bash -n "$SCRIPTS_DIR/git-branch-popup.sh"; then
    echo "ERROR: git-branch-popup.sh has syntax errors"
    exit 1
fi

if ! bash -n "$SCRIPTS_DIR/fzf-git-commits.sh"; then
    echo "ERROR: fzf-git-commits.sh has syntax errors"
    exit 1
fi

if ! bash -n "$SCRIPTS_DIR/git-commits-popup.sh"; then
    echo "ERROR: git-commits-popup.sh has syntax errors"
    exit 1
fi

echo "✓ Git operation scripts have valid syntax"

# Check that tmux-start.sh has proper shebang
if ! head -1 "$SCRIPTS_DIR/tmux-start.sh" | grep -q "^#!"; then
    echo "ERROR: tmux-start.sh missing shebang"
    exit 1
fi

echo "✓ Scripts have proper shebangs"

echo ""
echo "All script availability tests passed!"
exit 0
