#!/bin/bash
# ============================================================================
# zmux Installation Script
# ============================================================================
# This script installs tmux and configures it to work like Zellij

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"
TMUX_PLUGINS_DIR="$HOME/.tmux/plugins"

echo "🚀 Installing zmux (Zellij-like tmux configuration)..."
echo ""

# Check if running as root (we don't want that)
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please do not run this script as root"
    exit 1
fi

# ============================================================================
# Step 1: Install tmux
# ============================================================================

if ! command -v tmux >/dev/null 2>&1; then
    echo "📦 tmux is not installed. Installing..."
    
    if command -v apt-get >/dev/null 2>&1; then
        # Debian/Ubuntu
        sudo apt-get update
        sudo apt-get install -y tmux
    elif command -v yum >/dev/null 2>&1; then
        # RHEL/CentOS
        sudo yum install -y tmux
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        sudo dnf install -y tmux
    elif command -v pacman >/dev/null 2>&1; then
        # Arch Linux
        sudo pacman -S --noconfirm tmux
    elif command -v brew >/dev/null 2>&1; then
        # macOS
        brew install tmux
    else
        echo "❌ Could not detect package manager. Please install tmux manually."
        echo "   Visit: https://github.com/tmux/tmux/wiki/Installing"
        exit 1
    fi
    
    echo "✅ tmux installed successfully"
else
    TMUX_VERSION=$(tmux -V | awk '{print $2}')
    echo "✅ tmux is already installed (version: $TMUX_VERSION)"
fi

# ============================================================================
# Step 2: Create configuration directory
# ============================================================================

echo ""
echo "📁 Creating configuration directory..."
mkdir -p "$TMUX_CONFIG_DIR"
mkdir -p "$TMUX_CONFIG_DIR/modes"
mkdir -p "$TMUX_CONFIG_DIR/scripts"
mkdir -p "$HOME/.tmux/resurrect"
echo "✅ Configuration directory created: $TMUX_CONFIG_DIR"

# ============================================================================
# Step 3: Copy configuration files
# ============================================================================

echo ""
echo "📋 Copying configuration files..."

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
cp "$SCRIPT_DIR/scripts/toggle-lock-mode.sh" "$TMUX_CONFIG_DIR/scripts/toggle-lock-mode.sh"
cp "$SCRIPT_DIR/scripts/lock-mode-indicator.sh" "$TMUX_CONFIG_DIR/scripts/lock-mode-indicator.sh"
cp "$SCRIPT_DIR/scripts/swap-pane-left.sh" "$TMUX_CONFIG_DIR/scripts/swap-pane-left.sh"
cp "$SCRIPT_DIR/scripts/swap-pane-right.sh" "$TMUX_CONFIG_DIR/scripts/swap-pane-right.sh"
cp "$SCRIPT_DIR/scripts/session-killer.sh" "$TMUX_CONFIG_DIR/scripts/session-killer.sh"
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
chmod +x "$TMUX_CONFIG_DIR/scripts/toggle-lock-mode.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/lock-mode-indicator.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/swap-pane-left.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/swap-pane-right.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/session-killer.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-branch.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-branch-popup.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/fzf-git-commits.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/git-commits-popup.sh"

echo "✅ Configuration files copied"

# ============================================================================
# Step 4: Install TPM (Tmux Plugin Manager)
# ============================================================================

echo ""
echo "🔌 Installing Tmux Plugin Manager (TPM)..."

if [ ! -d "$TMUX_PLUGINS_DIR/tpm" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TMUX_PLUGINS_DIR/tpm" 2>/dev/null || {
        echo "⚠️  WARNING: Could not clone TPM. You may need to install it manually:"
        echo "   git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    }
    echo "✅ TPM installed"
else
    echo "✅ TPM is already installed"
fi

# ============================================================================
# Step 5: Handle existing ~/.tmux.conf
# ============================================================================

echo ""
if [ -f "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
    echo "⚠️  Existing ~/.tmux.conf detected"
    
    # Check if it's already pointing to our config
    if [ -L "$HOME/.tmux.conf" ]; then
        CURRENT_LINK=$(readlink -f "$HOME/.tmux.conf")
        if [ "$CURRENT_LINK" = "$TMUX_CONFIG_DIR/tmux.conf" ]; then
            echo "✅ ~/.tmux.conf already points to zmux configuration"
        else
            echo "   Current symlink points to: $CURRENT_LINK"
            read -p "   Backup and replace with zmux config? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                BACKUP_FILE="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
                echo "   Backing up to: $BACKUP_FILE"
                cp -L "$HOME/.tmux.conf" "$BACKUP_FILE" 2>/dev/null || true
                rm "$HOME/.tmux.conf"
                ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
                echo "✅ Replaced ~/.tmux.conf with zmux configuration"
            else
                echo "ℹ️  Keeping existing config. To use zmux, manually update ~/.tmux.conf"
                echo "   Or source zmux config: source-file $TMUX_CONFIG_DIR/tmux.conf"
            fi
        fi
    else
        # It's a regular file
        read -p "   Backup and replace with zmux config? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            BACKUP_FILE="$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
            echo "   Backing up to: $BACKUP_FILE"
            cp "$HOME/.tmux.conf" "$BACKUP_FILE"
            rm "$HOME/.tmux.conf"
            ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
            echo "✅ Replaced ~/.tmux.conf with zmux configuration"
        else
            echo "ℹ️  Keeping existing config. To use zmux, manually update ~/.tmux.conf"
            echo "   Or add this line to your ~/.tmux.conf:"
            echo "   source-file $TMUX_CONFIG_DIR/tmux.conf"
        fi
    fi
else
    echo "🔗 Creating symlink: ~/.tmux.conf -> $TMUX_CONFIG_DIR/tmux.conf"
    ln -s "$TMUX_CONFIG_DIR/tmux.conf" "$HOME/.tmux.conf"
    echo "✅ Symlink created"
fi

# ============================================================================
# Step 5.5: Install WSL-aware xdg-open shim
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
# Step 6: Install plugins
# ============================================================================

echo ""
echo "📦 Installing tmux plugins..."

# Check if fzf is installed (required for tmux-fzf)
if ! command -v fzf >/dev/null 2>&1; then
    echo "⚠️  fzf is required for tmux-fzf plugin. Installing..."
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y fzf 2>/dev/null || {
            echo "❌ Could not install fzf automatically. Please install it manually:"
            echo "   sudo apt-get install fzf"
            echo "   Or visit: https://github.com/junegunn/fzf#installation"
        }
    elif command -v brew >/dev/null 2>&1; then
        brew install fzf 2>/dev/null || {
            echo "❌ Could not install fzf automatically. Please install it manually:"
            echo "   brew install fzf"
        }
    else
        echo "❌ Please install fzf manually:"
        echo "   Visit: https://github.com/junegunn/fzf#installation"
    fi
fi

# Start tmux server if not running (needed for plugin installation)
if ! tmux has-session 2>/dev/null; then
    echo "   Starting tmux server for plugin installation..."
    tmux start-server 2>/dev/null || true
    sleep 1
fi

# Install plugins using TPM
echo "   Installing plugins via TPM..."

# List of essential plugins to install
ESSENTIAL_PLUGINS=(
    "tmux-plugins/tpm"
    "tmux-plugins/tmux-sensible"
    "tmux-plugins/tmux-resurrect"
    "tmux-plugins/tmux-continuum"
    "tmux-plugins/tmux-prefix-highlight"
    "sainnhe/tmux-fzf"
    "tmux-plugins/tmux-yank"
    "tmux-plugins/tmux-open"
)

# Function to install a single plugin
install_plugin() {
    local plugin_spec=$1
    local plugin_name=$(echo $plugin_spec | cut -d'/' -f2)
    local plugin_path="$TMUX_PLUGINS_DIR/$plugin_name"
    
    if [ -d "$plugin_path" ]; then
        return 0  # Already installed
    fi
    
    if git clone https://github.com/$plugin_spec.git "$plugin_path" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Try TPM automatic installation first
if [ -f "$TMUX_PLUGINS_DIR/tpm/bin/install_plugins" ]; then
    INSTALL_SUCCESS=true
    
    # TPM auto-install works best inside tmux. If no sessions exist, create one temporarily.
    if ! tmux has-session 2>/dev/null; then
        tmux new-session -d -s __install_plugins_temp 2>/dev/null || true
        sleep 1
    fi
    
    # Source config and run TPM installation
    if tmux has-session 2>/dev/null; then
        tmux send-keys -t __install_plugins_temp 'source ~/.tmux.conf' Enter 2>/dev/null || true
        sleep 1
        tmux send-keys -t __install_plugins_temp '~/.tmux/plugins/tpm/bin/install_plugins' Enter 2>/dev/null || true
        sleep 3
        
        # Clean up temporary session if we created it
        if tmux has-session -t __install_plugins_temp 2>/dev/null; then
            tmux kill-session -t __install_plugins_temp 2>/dev/null || true
        fi
    fi
fi

# If TPM installation didn't work or incomplete, manually install critical plugins
echo "   Verifying essential plugins..."
for plugin in "${ESSENTIAL_PLUGINS[@]}"; do
    plugin_name=$(echo $plugin | cut -d'/' -f2)
    plugin_path="$TMUX_PLUGINS_DIR/$plugin_name"
    
    if [ -d "$plugin_path" ]; then
        echo "   ✓ $plugin_name"
    else
        echo "   Installing $plugin_name..."
        if install_plugin "$plugin"; then
            echo "   ✅ $plugin_name installed"
        else
            echo "   ⚠️  Failed to install $plugin_name (network issue?)"
        fi
    fi
done

# Final verification
if [ -d "$TMUX_PLUGINS_DIR/tmux-resurrect" ] && [ -d "$TMUX_PLUGINS_DIR/tmux-continuum" ]; then
    echo "✅ Session restoration plugins installed"
fi

if [ -d "$TMUX_PLUGINS_DIR/tmux-fzf" ]; then
    echo "✅ All critical plugins installed"
else
    echo "⚠️  Some plugins failed to install. You can retry in tmux with: Ctrl+a, then i"
fi

# ============================================================================
# Step 7: Shell Configuration (Important!)
# ============================================================================

echo ""
echo "⚠️  IMPORTANT: Shell Configuration"
echo ""
echo "zmux uses Ctrl+p, Ctrl+n, Ctrl+h, and Ctrl+a which conflict with"
echo "shell readline shortcuts. You need to disable these in your shell."
echo ""
echo "The setup script will create ~/.config/zmux/shell-config and add"
echo "a source line to your ~/.bashrc or ~/.zshrc. You can easily disable"
echo "it by commenting out that line."
echo ""
read -p "Set up shell configuration automatically? [Y/n] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    "$SCRIPT_DIR/setup-shell.sh"
else
    echo "ℹ️  Skipping shell configuration. You can run it later:"
    echo "   ./setup-shell.sh"
    echo "   Or see docs/shell-config.md for manual setup"
fi

# ============================================================================
# Step 8: Optional dependencies
# ============================================================================

echo ""
echo "🔍 Verifying dependencies..."

if ! command -v fzf >/dev/null 2>&1; then
    echo "⚠️  fzf is not installed (required for tmux-fzf)"
    echo "   Please install it manually if automatic installation failed"
else
    echo "✅ fzf is installed"
fi

# ============================================================================
# Installation complete
# ============================================================================

echo ""
echo "🎉 Installation complete!"
echo ""
echo "⚠️  IMPORTANT: If you have an active tmux session, reload the config:"
echo "   1. In tmux, press your current prefix key (usually Ctrl+b)"
echo "   2. Then type: :source-file ~/.tmux.conf"
echo "   3. Or restart tmux: exit and run 'tmux' again"
echo ""
echo "Next steps:"
echo "  1. Reload config in existing sessions (see above) or start new tmux: tmux"
echo "  2. Plugins should be installed automatically (if installation failed, press Ctrl+a, then i)"
echo "  3. Verify installation: ~/.config/tmux/scripts/doctor.sh"
echo ""
echo "Key bindings (after reload):"
echo "  - Lock/Unlock: Ctrl+a"
echo "  - Pane mode: Ctrl+p"
echo "  - Resize mode: Ctrl+n (arrow keys resize)"
echo "  - Move mode: Ctrl+h (arrow keys move)"
echo "  - Tab mode: Ctrl+t"
echo "  - Scroll mode: Ctrl+s"
echo ""
echo "For more information, see README.md"

