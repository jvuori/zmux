#!/bin/bash
# ============================================================================
# zmux Update Script
# ============================================================================
# This script updates an existing zmux installation with the latest
# configuration files and plugins
#
# Usage:
#   ./update.sh          # Interactive update
#   ./update.sh --yes    # Non-interactive update

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"
NONINTERACTIVE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --yes|-y) NONINTERACTIVE=true ;;
        *) echo "Unknown option: $arg"; echo "Usage: $0 [--yes]"; exit 1 ;;
    esac
done

echo "🔄 Updating zmux configuration..."
echo ""

# Check if zmux is installed
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    echo "❌ zmux is not installed. Please run install.sh first."
    exit 1
fi

# ============================================================================
# Cleanup Function (removes old zmux files while preserving user data)
# ============================================================================

cleanup_old_installation() {
    local config_dir="$1"
    local scripts_dir="$config_dir/scripts"
    
    # Only proceed if the directories exist
    if [ ! -d "$config_dir" ]; then
        return 0
    fi
    
    echo "🧹 Cleaning up old installation files..."
    
    # List of known config files to remove (safe to delete - only zmux-provided files)
    local config_files=(
        "tmux.conf"
        "keybindings.conf"
        "lock-mode-bindings.conf"
        "statusbar.conf"
        "sessions.conf"
        "plugins.conf"
    )
    
    # Remove known config files
    for file in "${config_files[@]}"; do
        if [ -f "$config_dir/$file" ]; then
            rm -f "$config_dir/$file"
        fi
    done
    
    # Remove .conf files from modes directory
    if [ -d "$config_dir/modes" ]; then
        find "$config_dir/modes" -maxdepth 1 -name "*.conf" -type f -delete 2>/dev/null || true
    fi
    
    # Remove all .sh scripts from scripts directory (safe - only zmux scripts here)
    if [ -d "$scripts_dir" ]; then
        find "$scripts_dir" -maxdepth 1 -name "*.sh" -type f -delete 2>/dev/null || true
    fi
    
    # Clean up tmux-open wrapper if it exists (custom wrapper we provide)
    rm -f "$HOME/.local/bin/xdg-open" 2>/dev/null || true
    
    echo "   ✅ Old files removed (user data preserved)"
}

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
# Step 2: Clean up old files and update configuration
# ============================================================================

echo ""
echo "📋 Updating configuration files..."

# Clean up old files first (preserves user data)
cleanup_old_installation "$TMUX_CONFIG_DIR"

# Ensure directories exist
mkdir -p "$TMUX_CONFIG_DIR"
mkdir -p "$TMUX_CONFIG_DIR/modes"
mkdir -p "$TMUX_CONFIG_DIR/scripts"
# Use XDG data directory for resurrect - MUST match @resurrect-dir in plugins.conf
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
mkdir -p "$RESURRECT_DIR"

# Migrate old resurrect data if it exists (from ~/.tmux/resurrect to XDG location)
# This ensures users don't lose their session data when updating
if [ -d "$HOME/.tmux/resurrect" ] && [ "$(ls -A "$HOME/.tmux/resurrect" 2>/dev/null)" ]; then
    echo "📦 Migrating existing session data to XDG location..."
    for f in "$HOME/.tmux/resurrect"/tmux_resurrect_*.txt; do
        [ -f "$f" ] || continue
        basename=$(basename "$f")
        if [ ! -f "$RESURRECT_DIR/$basename" ]; then
            cp "$f" "$RESURRECT_DIR/"
        fi
    done
    # Copy pane contents if they exist
    if [ -f "$HOME/.tmux/resurrect/pane_contents.tar.gz" ]; then
        cp "$HOME/.tmux/resurrect/pane_contents.tar.gz" "$RESURRECT_DIR/" 2>/dev/null || true
    fi
    # Update last symlink to point to the newest save
    latest=$(ls "$RESURRECT_DIR"/tmux_resurrect_*.txt 2>/dev/null | sort | tail -1)
    if [ -n "$latest" ]; then
        ln -sf "$(basename "$latest")" "$RESURRECT_DIR/last"
    fi
    echo "✅ Session data migrated to: $RESURRECT_DIR"
fi

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
cp "$SCRIPT_DIR/scripts/systemd-tmux-start.sh" "$TMUX_CONFIG_DIR/scripts/systemd-tmux-start.sh"
cp "$SCRIPT_DIR/scripts/save-session-before-shutdown.sh" "$TMUX_CONFIG_DIR/scripts/save-session-before-shutdown.sh"
cp "$SCRIPT_DIR/scripts/track-active-session.sh" "$TMUX_CONFIG_DIR/scripts/track-active-session.sh"
cp "$SCRIPT_DIR/scripts/show-help.sh" "$TMUX_CONFIG_DIR/scripts/show-help.sh"
cp "$SCRIPT_DIR/scripts/get-mode-help.sh" "$TMUX_CONFIG_DIR/scripts/get-mode-help.sh"
cp "$SCRIPT_DIR/scripts/capture-cursor-agent-session.sh" "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"
cp "$SCRIPT_DIR/scripts/toggle-lock-mode.sh" "$TMUX_CONFIG_DIR/scripts/toggle-lock-mode.sh"
cp "$SCRIPT_DIR/scripts/lock-mode-indicator.sh" "$TMUX_CONFIG_DIR/scripts/lock-mode-indicator.sh"
cp "$SCRIPT_DIR/scripts/swap-pane-left.sh" "$TMUX_CONFIG_DIR/scripts/swap-pane-left.sh"
cp "$SCRIPT_DIR/scripts/swap-pane-right.sh" "$TMUX_CONFIG_DIR/scripts/swap-pane-right.sh"
cp "$SCRIPT_DIR/scripts/move-focus-or-tab-left.sh" "$TMUX_CONFIG_DIR/scripts/move-focus-or-tab-left.sh"
cp "$SCRIPT_DIR/scripts/move-focus-or-tab-right.sh" "$TMUX_CONFIG_DIR/scripts/move-focus-or-tab-right.sh"
cp "$SCRIPT_DIR/scripts/session-killer.sh" "$TMUX_CONFIG_DIR/scripts/session-killer.sh"
cp "$SCRIPT_DIR/scripts/fzf-git-branch.sh" "$TMUX_CONFIG_DIR/scripts/fzf-git-branch.sh"
cp "$SCRIPT_DIR/scripts/git-branch-popup.sh" "$TMUX_CONFIG_DIR/scripts/git-branch-popup.sh"
cp "$SCRIPT_DIR/scripts/fzf-git-commits.sh" "$TMUX_CONFIG_DIR/scripts/fzf-git-commits.sh"
cp "$SCRIPT_DIR/scripts/git-commits-popup.sh" "$TMUX_CONFIG_DIR/scripts/git-commits-popup.sh"
cp "$SCRIPT_DIR/scripts/lazygit-popup.sh" "$TMUX_CONFIG_DIR/scripts/lazygit-popup.sh"
cp "$SCRIPT_DIR/scripts/zmux.sh" "$TMUX_CONFIG_DIR/scripts/zmux.sh"
cp "$SCRIPT_DIR/scripts/check-update.sh" "$TMUX_CONFIG_DIR/scripts/check-update.sh"
cp "$SCRIPT_DIR/scripts/run-update.sh" "$TMUX_CONFIG_DIR/scripts/run-update.sh"
cp "$SCRIPT_DIR/scripts/notify-waiting.sh" "$TMUX_CONFIG_DIR/scripts/notify-waiting.sh"
cp "$SCRIPT_DIR/scripts/notify-done.sh" "$TMUX_CONFIG_DIR/scripts/notify-done.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-switcher.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/doctor.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/systemd-tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/save-session-before-shutdown.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/track-active-session.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/show-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/get-mode-help.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/capture-cursor-agent-session.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/toggle-lock-mode.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/lock-mode-indicator.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/swap-pane-left.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/swap-pane-right.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/move-focus-or-tab-left.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/move-focus-or-tab-right.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-killer.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-branch.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-branch-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-commits.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-commits-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/lazygit-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/zmux.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/check-update.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/run-update.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/notify-waiting.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/notify-done.sh"

echo "✅ Configuration files updated"

# ============================================================================
# Ensure xdg-open shim is installed (WSL + macOS + Linux compatible)
# ============================================================================
echo ""
echo "🔧 Ensuring xdg-open shim is installed for cross-platform compatibility..."
if [ ! -f "$HOME/.local/bin/xdg-open" ]; then
        mkdir -p "$HOME/.local/bin"
        cat > "$HOME/.local/bin/xdg-open" <<'SH'
#!/bin/sh
# Cross-platform xdg-open shim
# Supports: WSL (Windows), macOS, and Linux

if command -v powershell.exe >/dev/null 2>&1; then
    # WSL: use powershell.exe to open in Windows
    args=""
    for a in "$@"; do
        args="$args '$a'"
    done
    powershell.exe -NoProfile -Command "Start-Process $args" >/dev/null 2>&1 || exit 1
    exit 0
elif command -v open >/dev/null 2>&1; then
    # macOS: use the 'open' command
    open "$@" >/dev/null 2>&1 || exit 1
    exit 0
elif command -v xdg-open >/dev/null 2>&1; then
    # Linux: use xdg-open
    xdg-open "$@" >/dev/null 2>&1 || exit 1
    exit 0
fi

echo "xdg-open shim: no opener available" >&2
exit 1
SH
        chmod +x "$HOME/.local/bin/xdg-open"
        echo "✅ Installed cross-platform xdg-open shim to ~/.local/bin/xdg-open"
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
# Step 4: Setup XDG autostart (runs at graphical login, BEFORE terminals)
# ============================================================================

echo ""
echo "🚀 Updating automatic session restoration..."

# Create XDG autostart directory
mkdir -p "$HOME/.config/autostart"

# Create desktop entry for XDG autostart
cat > "$HOME/.config/autostart/zmux-daemon.desktop" << 'DESKTOP_ENTRY'
[Desktop Entry]
Type=Application
Name=zmux Daemon
Comment=Start tmux daemon with session restoration before any terminal opens
Exec=/bin/bash -c '$HOME/.config/tmux/scripts/systemd-tmux-start.sh'
Terminal=false
X-GNOME-Autostart-enabled=true
Hidden=false
NoDisplay=true
DESKTOP_ENTRY

echo "✅ XDG autostart configured: ~/.config/autostart/zmux-daemon.desktop"
echo ""
echo "🎯 Sessions will restore automatically at login:"
echo "   • XDG autostart runs when you log into your desktop"
echo "   • Daemon starts BEFORE you open any terminal"
echo "   • All previous sessions are restored in the background"
echo "   • When you open WezTerm, your session appears instantly!"

# ============================================================================
# Step 4.5: Setup/update systemd shutdown save service
# ============================================================================

echo ""
echo "💾 Updating automatic session save on shutdown..."

# Create systemd user directory
mkdir -p "$HOME/.config/systemd/user"

# Copy the systemd service file
cat > "$HOME/.config/systemd/user/tmux-shutdown-save.service" << 'SERVICE_FILE'
[Unit]
Description=Save tmux session before shutdown
DefaultDependencies=no
Before=shutdown.target reboot.target halt.target

[Service]
Type=oneshot
ExecStart=%h/.config/tmux/scripts/save-session-before-shutdown.sh
TimeoutStartSec=5

[Install]
WantedBy=halt.target reboot.target shutdown.target
SERVICE_FILE

# Enable the service
systemctl --user daemon-reload
systemctl --user enable tmux-shutdown-save.service 2>/dev/null && \
    echo "✅ Shutdown save service enabled" || \
    echo "⚠️  Could not enable shutdown save service (will try again after first login)"

echo ""
echo "💾 Session will be automatically saved:"
echo "   • Every 5 minutes (auto-save)"
echo "   • Before system shutdown/reboot"
echo "   • When you press Ctrl+q (quit tmux)"

# ============================================================================
# Step 5: Update plugins
# ============================================================================

echo ""
echo "📦 Updating plugins..."

# Install/update plugins using TPM
if [ -f ~/.tmux/plugins/tpm/bin/install_plugins ]; then
    # Use a temporary session for plugin operations if no sessions exist
    TEMP_SESSION_CREATED=false
    if ! tmux has-session 2>/dev/null; then
        tmux new-session -d -s __plugin_update_temp 2>/dev/null || true
        TEMP_SESSION_CREATED=true
        sleep 1
    fi
    
    if tmux has-session 2>/dev/null; then
        # Source config and run install plugins (suppress all output)
        tmux source-file "$TMUX_CONFIG_DIR/tmux.conf" 2>/dev/null || true
        sleep 1
        tmux run 'bash -c "~/.tmux/plugins/tpm/bin/install_plugins >/dev/null 2>&1"' || true
        sleep 2
        
        # Update plugins (suppress all output)
        tmux run 'bash -c "~/.tmux/plugins/tpm/bin/update_plugins all >/dev/null 2>&1"' || true
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
echo "✅ XDG autostart is configured for automatic session restoration"
echo "   Your background tmux daemon will start at next login"
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
echo ""
echo "If you encounter issues, your backup is at:"
echo "  $BACKUP_DIR"

# ============================================================================
# Set up Claude Code notification hooks (optional, if installed)
# ============================================================================

setup_claude_code_hook() {
    local notify_script="$HOME/.config/tmux/scripts/notify-waiting.sh"
    local done_script="$HOME/.config/tmux/scripts/notify-done.sh"
    local settings_file="$HOME/.claude/settings.json"

    [ -d "$HOME/.claude" ] || return 0

    echo ""
    echo "🤖 Setting up Claude Code notification hooks..."

    if ! command -v python3 >/dev/null 2>&1; then
        echo "   ⚠️  python3 not found, skipping Claude Code hook setup"
        return 0
    fi

    python3 - "$settings_file" "$notify_script" "$done_script" <<'PYEOF'
import json, os, sys

settings_file, notify_script, done_script = sys.argv[1], sys.argv[2], sys.argv[3]

if os.path.exists(settings_file):
    with open(settings_file, 'r') as f:
        try:
            settings = json.load(f)
        except (json.JSONDecodeError, ValueError):
            settings = {}
else:
    settings = {}

if "hooks" not in settings:
    settings["hooks"] = {}

def has_command(hooks_list, cmd):
    return any(
        any(h.get("command") == cmd for h in group.get("hooks", []))
        for group in hooks_list
    )

def add_hook(hooks_list, cmd):
    if not has_command(hooks_list, cmd):
        hooks_list.append({"hooks": [{"type": "command", "command": cmd}]})
        return True
    return False

if "Stop" not in settings["hooks"]:
    settings["hooks"]["Stop"] = []
stop_added = add_hook(settings["hooks"]["Stop"], notify_script)

if "PreToolUse" not in settings["hooks"]:
    settings["hooks"]["PreToolUse"] = []
pre_added = add_hook(settings["hooks"]["PreToolUse"], done_script)

if stop_added or pre_added:
    with open(settings_file, 'w') as f:
        json.dump(settings, f, indent=2)
        f.write('\n')
    print("   ✅ Claude Code notification hooks configured")
else:
    print("   ✅ Claude Code notification hooks already configured")
PYEOF
}

setup_claude_code_hook

# ============================================================================
# Update zmux CLI and version file
# ============================================================================

echo ""
echo "🔧 Updating zmux command in ~/.local/bin/zmux..."
mkdir -p "$HOME/.local/bin"
cp "$TMUX_CONFIG_DIR/scripts/zmux.sh" "$HOME/.local/bin/zmux"
chmod +x "$HOME/.local/bin/zmux"
echo "✅ zmux command updated"

# Write new version file
# VERSION is only present in release tarballs (it is gitignored and written
# by the GitHub Actions release workflow).  When updating from a git work
# tree the file is absent; in that case remove any stale zmux-version so
# check-update.sh treats this as a development install and always shows the
# update notification.
if [ -f "$SCRIPT_DIR/VERSION" ]; then
    cp "$SCRIPT_DIR/VERSION" "$TMUX_CONFIG_DIR/zmux-version"
    echo "✅ Version updated to: $(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')"
else
    rm -f "$TMUX_CONFIG_DIR/zmux-version"
    echo "⚠️  Git work tree update — no release version recorded (update hint will always appear)"
fi

# ============================================================================
# Run version check to update notification
# ============================================================================
# Re-evaluate whether an update is available now that the version file is
# written. This ensures any running tmux session gets the updated
# @update_available immediately (e.g., if upgraded from dev to release,
# the hint disappears; if downgraded from release to dev, it reappears).
bash "$TMUX_CONFIG_DIR/scripts/check-update.sh" 2>/dev/null || true

