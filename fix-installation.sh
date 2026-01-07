#!/bin/bash
# ============================================================================
# Fix Existing zmux Installation
# ============================================================================
# This script fixes an installation where files were copied but ~/.tmux.conf
# wasn't updated, or helps migrate from an old installation

set -e

TMUX_CONFIG_DIR="$HOME/.config/tmux"

echo "🔧 Fixing zmux installation..."
echo ""

# Check if zmux config exists
if [ ! -f "$TMUX_CONFIG_DIR/tmux.conf" ]; then
    echo "❌ zmux configuration not found at $TMUX_CONFIG_DIR/tmux.conf"
    echo "   Please run install.sh first"
    exit 1
fi

# Handle existing ~/.tmux.conf
if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    echo "📋 Found existing ~/.tmux.conf"
    
    if [ -L "$HOME/.tmux.conf" ]; then
        CURRENT_LINK=$(readlink -f "$HOME/.tmux.conf")
        echo "   Current symlink points to: $CURRENT_LINK"
        
        if [ "$CURRENT_LINK" = "$TMUX_CONFIG_DIR/tmux.conf" ]; then
            echo "✅ Already pointing to zmux config!"
            echo ""
            echo "If zmux isn't working, reload your tmux config:"
            echo "  In tmux: prefix + :source-file ~/.tmux.conf"
            echo "  Or restart tmux: exit and run 'tmux' again"
            exit 0
        fi
    else
        echo "   Existing file (not a symlink)"
    fi
    
    # Backup and replace
    BACKUP_FILE="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
    echo ""
    echo "📦 Backing up to: $BACKUP_FILE"
    cp -L "$HOME/.tmux.conf" "$BACKUP_FILE" 2>/dev/null || cp "$HOME/.tmux.conf" "$BACKUP_FILE"
    
    echo "🔗 Creating symlink to zmux config..."
    rm -f "$HOME/.tmux.conf"
    ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Done!"
    
else
    echo "🔗 Creating symlink to zmux config..."
    ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Done!"
fi

echo ""
echo "⚠️  IMPORTANT: Reload your tmux configuration!"
echo ""
echo "Option 1: Use the reload script (easiest):"
echo "   ./reload-config.sh"
echo ""
echo "Option 2: Manual reload in tmux:"
echo "   Press your current prefix (usually Ctrl+b)"
echo "   Type: :source-file ~/.tmux.conf"
echo "   Press Enter"
echo ""
echo "Option 3: Restart tmux:"
echo "   exit  # exit current session"
echo "   tmux  # start new session"
echo ""
echo "2. Configure your shell (REQUIRED for keybindings to work):"
echo "   ./setup-shell.sh"
echo "   source ~/.bashrc  # or source ~/.zshrc"
echo ""
echo "   Without this, Ctrl+p will show previous command instead of"
echo "   entering pane mode. See docs/shell-config.md for details."
echo ""
echo "After both steps, test with:"
echo "  - Press Ctrl+p (should enter pane mode, not show previous command)"
echo "  - Press Ctrl+n (should enter resize mode)"
echo "  - Press Ctrl+a twice (should lock/unlock)"

