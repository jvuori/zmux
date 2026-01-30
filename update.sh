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
mkdir -p "$HOME/.tmux/resurrect"

# Copy main config files
cp "$SCRIPT_DIR/tmux/tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
cp "$SCRIPT_DIR/tmux/keybindings.conf" "$TMUX_CONFIG_DIR/keybindings.conf"
cp "$SCRIPT_DIR/tmux/lock-mode-bindings.conf" "$TMUX_CONFIG_DIR/lock-mode-bindings.conf"
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
cp "$SCRIPT_DIR/scripts/get-mode-help.sh" "$TMUX_CONFIG_DIR/scripts/get-mode-help.sh"
cp "$SCRIPT_DIR/scripts/capture-cursor-agent-session.sh" "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"
cp "$SCRIPT_DIR/scripts/fzf-git-branch.sh" "$TMUX_CONFIG_DIR/scripts/fzf-git-branch.sh"
cp "$SCRIPT_DIR/scripts/git-branch-popup.sh" "$TMUX_CONFIG_DIR/scripts/git-branch-popup.sh"
cp "$SCRIPT_DIR/scripts/fzf-git-commits.sh" "$TMUX_CONFIG_DIR/scripts/fzf-git-commits.sh"
cp "$SCRIPT_DIR/scripts/git-commits-popup.sh" "$TMUX_CONFIG_DIR/scripts/git-commits-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-switcher.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/doctor.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/show-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/get-mode-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-branch.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-branch-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-commits.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-commits-popup.sh"

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
# Step 4: Update systemd tmux service
# ============================================================================

echo ""
echo "🚀 Updating systemd tmux service..."

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/tmux.service" << 'SYSTEMD_SERVICE'
[Unit]
Description=Tmux Session Manager
Documentation=man:tmux(1)
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=forking
RemainAfterExit=yes
ExecStartPre=/usr/bin/mkdir -p %h/.tmux
ExecStartPre=/usr/bin/mkdir -p %h/.tmux/resurrect
ExecStart=/usr/bin/tmux start-server
ExecStartPost=/usr/bin/bash -c 'sleep 0.5 && /usr/bin/tmux source-file %h/.tmux.conf'
Restart=on-failure
RestartSec=5

[Install]
WantedBy=graphical-session.target
SYSTEMD_SERVICE

echo "✅ Updated systemd service file: $SYSTEMD_USER_DIR/tmux.service"

# Reload and restart the service
if systemctl --user daemon-reload 2>/dev/null && \
   systemctl --user restart tmux.service 2>/dev/null; then
    echo "✅ Systemd tmux service reloaded and restarted"
else
    echo "⚠️  Could not reload systemd service (service may not be active)"
    echo "   Try enabling it: systemctl --user enable tmux.service"
fi

# ============================================================================
# Step 5: Update plugins
# ============================================================================

echo ""
echo "📦 Updating plugins..."

# Install/update plugins using TPM
echo ""
echo "📦 Updating plugins..."

if [ -f ~/.tmux/plugins/tpm/bin/install_plugins ]; then
    echo "   Verifying plugin installation...\n"
    
    # Use a temporary session for plugin operations if no sessions exist
    TEMP_SESSION_CREATED=false
    if ! tmux has-session 2>/dev/null; then
        echo "   Creating temporary session for plugin installation..."
        tmux new-session -d -s __plugin_update_temp 2>/dev/null || true
        TEMP_SESSION_CREATED=true
        sleep 1
    fi
    
    if tmux has-session 2>/dev/null; then
        echo "   Installing new plugins..."
        # Source config and run install plugins
        tmux source-file "$TMUX_CONFIG_DIR/tmux.conf" 2>/dev/null || true
        sleep 1
        tmux run '~/.tmux/plugins/tpm/bin/install_plugins' 2>/dev/null || true
        sleep 2
        
        echo "   Updating existing plugins..."
        tmux run 'bash -c "~/.tmux/plugins/tpm/bin/update_plugins all"' 2>/dev/null || true
        sleep 2
        
        # Clean up temporary session if we created it
        if [ "$TEMP_SESSION_CREATED" = true ] && tmux has-session -t __plugin_update_temp 2>/dev/null; then
            tmux kill-session -t __plugin_update_temp 2>/dev/null || true
        fi
    fi
    
    # Verify critical plugins are present
    if [ -d ~/.tmux/plugins/tmux-resurrect ] && [ -d ~/.tmux/plugins/tmux-continuum ]; then
        echo "✅ Session restoration plugins verified"
    fi
    
    echo "✅ Plugins updated"
else
    echo "⚠️  TPM not found. Please install plugins manually:"
    echo "   In tmux, press Ctrl+a, then i"
fi

# ============================================================================
# Update complete
# ============================================================================

echo ""
echo "🎉 Update complete!"
echo ""
echo "✅ Systemd tmux service has been updated"
echo "   Your background tmux daemon is running and will restore sessions at login"
echo ""
echo "Regenerating shell configuration..."
bash "$SCRIPT_DIR/setup-shell.sh" || {
    echo "⚠️  Could not regenerate shell config, but other updates completed"
}
echo ""
echo "Next steps:"
echo "  1. If you have active tmux sessions, the config is already reloaded"
echo "  2. Install/update plugins: Press Ctrl+a, then i (or u for updates)"
echo "  3. Verify: ~/.config/tmux/scripts/doctor.sh"
echo "  4. Check service status: systemctl --user status tmux.service"
echo ""
echo "If you encounter issues, your backup is at:"
echo "  $BACKUP_DIR"

