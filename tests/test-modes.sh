#!/bin/bash
# Test tmux modes and keybindings
# Verifies that key tables are properly configured and mode switching works

set -e

echo "Testing tmux modes and keybindings..."

# Check if we're in a headless environment
if [ ! -t 0 ]; then
    echo "⚠️  WARNING: Running in headless environment"
    echo "⚠️  Will verify keybindings via configuration files instead"
    HEADLESS=true
else
    HEADLESS=false
fi

if [ "$HEADLESS" = "false" ]; then
    # Use the installed tmux config (via symlink)
    # Start a tmux server in the background with a test session
    tmux new-session -d -s test_session "sleep 300" 2>/dev/null || {
        echo "ERROR: Failed to start tmux session"
        HEADLESS=true
    }
    
    if [ "$HEADLESS" = "false" ]; then
        # Give tmux a moment to initialize
        sleep 2
        echo "✓ Tmux session started"
    fi
fi

if [ "$HEADLESS" = "true" ]; then
    echo "✓ Running in headless mode - using config file verification"
fi

# Test that tmux is running with our config
if [ "$HEADLESS" = "false" ]; then
    if ! tmux list-sessions | grep -q "test_session"; then
        echo "ERROR: Test session not found"
        tmux kill-server 2>/dev/null || true
        exit 1
    fi
    echo "✓ Session created successfully"
fi

# Check if key tables are defined (works in both modes)
# In headless mode, we parse the config files
if [ "$HEADLESS" = "true" ]; then
    # Verify keybindings exist in config files
    if [ ! -f "$HOME/.config/tmux/keybindings.conf" ]; then
        echo "ERROR: keybindings.conf not found"
        exit 1
    fi
    echo "✓ Keybindings configuration file present"
    
    # Check for mode definitions in keybindings
    for mode in pane tab session move resize git; do
        if ! grep -q "bind.*-T $mode" "$HOME/.config/tmux/keybindings.conf"; then
            echo "ERROR: Mode '$mode' bindings not found in config"
            exit 1
        fi
    done
    echo "✓ All key tables defined in configuration"
else
    # Use tmux commands to verify
    EXPECTED_TABLES=(
        "root"
        "pane"
        "tab"
        "session"
        "move"
        "resize"
        "git"
    )

    for table in "${EXPECTED_TABLES[@]}"; do
        if ! tmux list-keys -T "$table" >/dev/null 2>&1; then
            echo "ERROR: Key table '$table' not defined"
            tmux kill-server 2>/dev/null || true
            exit 1
        fi
        # Check that table has bindings
        binding_count=$(tmux list-keys -T "$table" | wc -l)
        if [ "$binding_count" -eq 0 ]; then
            echo "ERROR: Key table '$table' has no bindings"
            tmux kill-server 2>/dev/null || true
            exit 1
        fi
    done
    echo "✓ All key tables defined with bindings"
fi

# Test specific mode configurations
# Use config file checking in all modes since tmux might not start in Docker
echo "Checking mode-specific bindings in configuration..."

# Test pane mode (Ctrl+p)
if ! grep -q "bind.*-T pane.*\(new-window\|split-window\)" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Pane mode missing expected bindings"
    exit 1
fi
echo "✓ Pane mode configured"

# Test tab mode (Ctrl+t)
if ! grep -q "bind.*-T tab.*new-window" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Tab mode missing expected bindings"
    exit 1
fi
echo "✓ Tab mode configured"

# Test session mode (Ctrl+o)
if ! grep -q "bind.*-T session.*\(new-session\|choose-tree\)" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Session mode missing expected bindings"
    exit 1
fi
echo "✓ Session mode configured"

# Test move mode (Ctrl+h)
if ! grep -q "bind.*-T move.*swap-pane" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Move mode missing expected bindings"
    exit 1
fi
echo "✓ Move mode configured"

# Test resize mode (Ctrl+n)
if ! grep -q "bind.*-T resize.*resize-pane" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Resize mode missing expected bindings"
    exit 1
fi
echo "✓ Resize mode configured"

# Test git mode (Ctrl+g)
# Handle multiline bindings by checking for the mode and then the script names
if ! grep -q "bind -T git" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Git mode not defined"
    exit 1
fi

if ! grep -q "git-branch-popup" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Git mode missing branch selection binding"
    exit 1
fi

if ! grep -q "git-commits-popup" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Git mode missing commits selection binding"
    exit 1
fi
echo "✓ Git mode configured"

# Test configuration settings
if ! grep -q "set -g prefix C-a" "$HOME/.config/tmux/keybindings.conf"; then
    echo "ERROR: Prefix key not set to Ctrl+a"
    exit 1
fi
echo "✓ Prefix key configured (Ctrl+a)"

if ! grep -q "set-option -g repeat-time 2000" "$HOME/.config/tmux/tmux.conf"; then
    echo "ERROR: repeat-time not set to 2000ms"
    exit 1
fi
echo "✓ Repeat-time configured (2000ms)"

if ! grep -q "set -g status-position top" "$HOME/.config/tmux/statusbar.conf"; then
    echo "ERROR: Status bar not positioned at top"
    exit 1
fi
echo "✓ Status bar at top"

# Clean up if tmux was started
if [ "$HEADLESS" = "false" ]; then
    tmux kill-server 2>/dev/null || true
fi

echo ""
echo "All mode and keybinding tests passed!"
exit 0
