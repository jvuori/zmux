#!/bin/bash
# ============================================================================
# zmux Update Script
# ============================================================================
# This script updates an existing zmux installation with the latest
# configuration files and plugins

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"

echo "🔄 Updating zmux configuration..."
echo ""

# Check if zmux is installed
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    echo "❌ zmux is not installed. Please run install.sh first."
    exit 1
fi

# ============================================================================
# Step 1: Backup current configuration
# ============================================================================

echo "📦 Creating backup..."
BACKUP_DIR="$TMUX_CONFIG_DIR.backup.$(date +%Y%m%d_%H%M%S)"
cp -r "$TMUX_CONFIG_DIR" "$BACKUP_DIR" 2>/dev/null || {
    echo "⚠️  Could not create backup, continuing anyway..."
}
echo "✅ Backup created: $BACKUP_DIR"

# ============================================================================
# Step 2: Update configuration files
# ============================================================================

echo ""
echo "📋 Updating configuration files..."

# Ensure directories exist
mkdir -p "$TMUX_CONFIG_DIR"
mkdir -p "$TMUX_CONFIG_DIR/modes"
mkdir -p "$TMUX_CONFIG_DIR/scripts"

# Copy main config files
cp "$SCRIPT_DIR/tmux/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
cp "$SCRIPT_DIR/tmux/keybindings.conf" "$TMUX_CONFIG_DIR/keybindings.conf"
cp "$SCRIPT_DIR/tmux/statusbar.conf" "$TMUX_CONFIG_DIR/statusbar.conf"
cp "$SCRIPT_DIR/tmux/sessions.conf" "$TMUX_CONFIG_DIR/sessions.conf"
cp "$SCRIPT_DIR/plugins/plugins.conf" "$TMUX_CONFIG_DIR/plugins.conf"

# Copy mode configs
cp "$SCRIPT_DIR/tmux/modes/pane.conf" "$TMUX_CONFIG_DIR/modes/pane.conf"
cp "$SCRIPT_DIR/tmux/modes/tab.conf" "$TMUX_CONFIG_DIR/modes/tab.conf"
cp "$SCRIPT_DIR/tmux/modes/resize.conf" "$TMUX_CONFIG_DIR/modes/resize.conf"
cp "$SCRIPT_DIR/tmux/modes/move.conf" "$TMUX_CONFIG_DIR/modes/move.conf"

# Copy scripts
cp "$SCRIPT_DIR/scripts/session-switcher.sh" "$TMUX_CONFIG_DIR/scripts/session-switcher.sh"
cp "$SCRIPT_DIR/scripts/doctor.sh" "$TMUX_CONFIG_DIR/scripts/doctor.sh"
cp "$SCRIPT_DIR/scripts/tmux-start.sh" "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
cp "$SCRIPT_DIR/scripts/show-help.sh" "$TMUX_CONFIG_DIR/scripts/show-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-switcher.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/doctor.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/show-help.sh"

echo "✅ Configuration files updated"

# ============================================================================
# Step 3: Reload tmux configuration
# ============================================================================

echo ""
echo "🔄 Reloading tmux configuration..."

if tmux has-session 2>/dev/null; then
    # Reload in all active sessions
    tmux list-sessions -F "#{session_name}" 2>/dev/null | while read -r session; do
        tmux source-file -t "$session" ~/.tmux.conf 2>/dev/null || true
    done
    echo "✅ Configuration reloaded in active sessions"
else
    echo "ℹ️  No active tmux sessions. Config will load automatically on next start."
fi

# ============================================================================
# Step 4: Update plugins
# ============================================================================

echo ""
echo "📦 Updating plugins..."

# Start tmux server if not running (needed for plugin installation)
if ! tmux has-session 2>/dev/null; then
    echo "   Starting tmux server for plugin update..."
    tmux start-server 2>/dev/null || true
    sleep 1
fi

# Install/update plugins using TPM
if [ -f ~/.tmux/plugins/tpm/bin/install_plugins ]; then
    echo "   Installing new plugins..."
    tmux source-file ~/.tmux.conf 2>/dev/null || true
    tmux run '~/.tmux/plugins/tpm/bin/install_plugins' 2>/dev/null || {
        echo "⚠️  Could not install plugins automatically. Please install manually:"
        echo "   In tmux, press Ctrl+a, then I"
    }
    
    echo "   Updating existing plugins..."
    # Use bash -c to properly execute the command with arguments
    tmux run 'bash -c "~/.tmux/plugins/tpm/bin/update_plugins all"' 2>/dev/null || {
        echo "⚠️  Could not update plugins automatically. Please update manually:"
        echo "   In tmux, press Ctrl+a, then U"
    }
    echo "✅ Plugins updated"
else
    echo "⚠️  TPM not found. Please install plugins manually:"
    echo "   In tmux, press Ctrl+g, then I"
fi

# ============================================================================
# Update complete
# ============================================================================

echo ""
echo "🎉 Update complete!"
echo ""
echo "Next steps:"
echo "  1. If you have active tmux sessions, the config is already reloaded"
echo "  2. Install/update plugins: Press Ctrl+a, then I (or U for updates)"
echo "  3. Verify: ~/.config/tmux/scripts/doctor.sh"
echo ""
echo "If you encounter issues, your backup is at:"
echo "  $BACKUP_DIR"

