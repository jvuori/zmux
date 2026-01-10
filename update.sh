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
cp "$SCRIPT_DIR/scripts/capture-cursor-agent-session.sh" "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-switcher.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/doctor.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/show-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"

echo "✅ Configuration files updated"

# ============================================================================
# Ensure WSL-aware xdg-open shim is installed for tmux-open compatibility
# ============================================================================
echo ""
echo "🔧 Ensuring xdg-open shim is installed for WSL compatibility..."
if [ ! -f "$HOME/.local/bin/xdg-open" ]; then
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/xdg-open" <<'SH'
#!/bin/sh
# WSL-aware xdg-open shim. If powershell.exe is available, use it to open
# files/URLs in Windows default apps; otherwise fall back to system xdg-open.
if command -v powershell.exe >/dev/null 2>&1; then
    # Join all arguments into one quoted string
    args=""
    for a in "$@"; do
        args="$args '$a'"
    done
    powershell.exe -NoProfile -Command "Start-Process $args" >/dev/null 2>&1 || exit 1
    exit 0
fi
# Fallback to system xdg-open if present
if command -v /usr/bin/xdg-open >/dev/null 2>&1; then
    /usr/bin/xdg-open "$@" >/dev/null 2>&1 || exit 1
    exit 0
fi
echo "xdg-open shim: no opener available" >&2
exit 1
SH
        chmod +x "$HOME/.local/bin/xdg-open"
        echo "✅ Installed WSL-aware xdg-open shim to ~/.local/bin/xdg-open"
else
        echo "ℹ️  xdg-open shim already present: ~/.local/bin/xdg-open"
fi

# ============================================================================
# Step 3: Reload tmux configuration
# ============================================================================

echo ""
echo "🔄 Reloading tmux configuration..."

if tmux has-session 2>/dev/null; then
    # Reload server configuration from the updated config file
    tmux source-file "$TMUX_CONFIG_DIR/tmux.conf" 2>/dev/null || true
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
    # Ensure tmux loads the updated configuration (with guarded plugin runs)
    tmux source-file "$TMUX_CONFIG_DIR/tmux.conf" 2>/dev/null || true
    tmux run '~/.tmux/plugins/tpm/bin/install_plugins' 2>/dev/null || {
        echo "⚠️  Could not install plugins automatically. Please install manually:"
        echo "   In tmux, press Ctrl+a, then i"
    }
    
    echo "   Updating existing plugins..."
    # Use bash -c to properly execute the command with arguments
    tmux run 'bash -c "~/.tmux/plugins/tpm/bin/update_plugins all"' 2>/dev/null || {
        echo "⚠️  Could not update plugins automatically. Please update manually:"
        echo "   In tmux, press Ctrl+a, then u"
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
echo "  2. Install/update plugins: Press Ctrl+a, then i (or u for updates)"
echo "  3. Verify: ~/.config/tmux/scripts/doctor.sh"
echo ""
echo "If you encounter issues, your backup is at:"
echo "  $BACKUP_DIR"

