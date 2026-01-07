#!/bin/bash
# ============================================================================
# zmux Uninstallation Script
# ============================================================================
# This script removes zmux configuration and optionally tmux

set -e

TMUX_CONFIG_DIR="$HOME/.config/tmux"
TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"

echo "🗑️  Uninstalling zmux..."
echo ""

# ============================================================================
# Confirmation
# ============================================================================

read -p "Are you sure you want to uninstall zmux? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

# ============================================================================
# Step 1: Remove configuration files
# ============================================================================

echo ""
echo "📁 Removing configuration files..."

if [ -d "$TMUX_CONFIG_DIR" ]; then
    rm -rf "$TMUX_CONFIG_DIR"
    echo "✅ Removed: $TMUX_CONFIG_DIR"
else
    echo "ℹ️  Configuration directory not found: $TMUX_CONFIG_DIR"
fi

# ============================================================================
# Step 2: Remove symlink
# ============================================================================

echo ""
if [ -L "$HOME/.tmux.conf" ]; then
    # Check if it points to our config
    LINK_TARGET=$(readlink "$HOME/.tmux.conf")
    if [[ "$LINK_TARGET" == *"zmux"* ]] || [[ "$LINK_TARGET" == *".config/tmux"* ]]; then
        rm "$HOME/.tmux.conf"
        echo "✅ Removed symlink: ~/.tmux.conf"
    else
        echo "ℹ️  ~/.tmux.conf exists but doesn't point to zmux config. Keeping it."
    fi
else
    echo "ℹ️  ~/.tmux.conf is not a symlink or doesn't exist"
fi

# ============================================================================
# Step 3: Remove plugins (optional)
# ============================================================================

echo ""
read -p "Remove tmux plugins? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [ -d "$TMUX_PLUGINS_DIR" ]; then
        rm -rf "$TMUX_PLUGINS_DIR"
        echo "✅ Removed: $TMUX_PLUGINS_DIR"
    else
        echo "ℹ️  Plugins directory not found: $TMUX_PLUGINS_DIR"
    fi
else
    echo "ℹ️  Keeping plugins directory"
fi

# ============================================================================
# Step 4: Remove tmux (optional)
# ============================================================================

echo ""
read -p "Uninstall tmux as well? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if command -v tmux >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            sudo apt-get remove -y tmux
        elif command -v yum >/dev/null 2>&1; then
            sudo yum remove -y tmux
        elif command -v dnf >/dev/null 2>&1; then
            sudo dnf remove -y tmux
        elif command -v pacman >/dev/null 2>&1; then
            sudo pacman -R --noconfirm tmux
        elif command -v brew >/dev/null 2>&1; then
            brew uninstall tmux
        else
            echo "⚠️  Could not detect package manager. Please uninstall tmux manually."
        fi
        echo "✅ tmux uninstalled"
    else
        echo "ℹ️  tmux is not installed"
    fi
else
    echo "ℹ️  Keeping tmux installed"
fi

# ============================================================================
# Uninstallation complete
# ============================================================================

echo ""
echo "✅ Uninstallation complete!"
echo ""
echo "Note: If you have active tmux sessions, you may want to:"
echo "  - Detach from sessions: prefix+d (or Ctrl+a, then d)"
echo "  - Kill all sessions: tmux kill-server"

