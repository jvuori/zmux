#!/bin/bash
# ============================================================================
# Doctor Script - Check zmux Installation
# ============================================================================
# This script checks if zmux is properly installed and configured

echo "🔍 zmux Doctor - Checking installation..."
echo ""

ERRORS=0
WARNINGS=0

# Check if tmux is installed
if ! command -v tmux >/dev/null 2>&1; then
    echo "❌ ERROR: tmux is not installed"
    ERRORS=$((ERRORS + 1))
else
    TMUX_VERSION=$(tmux -V | awk '{print $2}')
    echo "✅ tmux is installed (version: $TMUX_VERSION)"
fi

# Check if tmux config directory exists
if [ ! -d "$HOME/.config/tmux" ]; then
    echo "❌ ERROR: ~/.config/tmux directory does not exist"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ tmux config directory exists"
fi

# Check if main config file exists
if [ ! -f "$HOME/.config/tmux/tmux.conf" ]; then
    echo "❌ ERROR: ~/.config/tmux/tmux.conf does not exist"
    ERRORS=$((ERRORS + 1))
else
    echo "✅ Main config file exists"
fi

# Check if TPM is installed
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo "⚠️  WARNING: TPM (Tmux Plugin Manager) is not installed"
    WARNINGS=$((WARNINGS + 1))
    echo "   Run: git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
else
    echo "✅ TPM is installed"
fi

# Check if plugins are installed
if [ -d "$HOME/.tmux/plugins/tpm" ]; then
    PLUGIN_COUNT=$(find "$HOME/.tmux/plugins" -mindepth 1 -maxdepth 1 -type d | wc -l)
    if [ "$PLUGIN_COUNT" -lt 2 ]; then
        echo "⚠️  WARNING: Plugins may not be installed"
        echo "   Run: prefix+i in tmux to install plugins"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✅ Plugins directory exists ($PLUGIN_COUNT plugins found)"
    fi
fi

# Check if scripts are executable
if [ -f "$HOME/.config/tmux/scripts/session-switcher.sh" ]; then
    if [ ! -x "$HOME/.config/tmux/scripts/session-switcher.sh" ]; then
        echo "⚠️  WARNING: session-switcher.sh is not executable"
        echo "   Run: chmod +x ~/.config/tmux/scripts/session-switcher.sh"
        WARNINGS=$((WARNINGS + 1))
    else
        echo "✅ Scripts are executable"
    fi
fi

# Check if fzf is available (optional, for session-switcher)
if ! command -v fzf >/dev/null 2>&1; then
    echo "ℹ️  INFO: fzf is not installed (optional, for better session switching)"
else
    echo "✅ fzf is installed (enhanced session switching available)"
fi

# Check if lazygit is available (optional, for git operations)
if ! command -v lazygit >/dev/null 2>&1; then
    echo "ℹ️  INFO: lazygit is not installed (optional, for git UI - Ctrl+g, l)"
else
    echo "✅ lazygit is installed (git UI available)"
fi

# Check for CSI u / Kitty keyboard protocol vs tmux extended-keys compatibility
# WezTerm with enable_csi_u_key_encoding=true and neovim/yazi installs commonly enable CSI u.
# When active, Ctrl+G sends \x1b[7u instead of \x07. tmux needs extended-keys on to decode this.
CSI_U_SOURCE=""
if [ -f "$HOME/.config/wezterm/wezterm.lua" ] && grep -q "enable_csi_u_key_encoding.*true" "$HOME/.config/wezterm/wezterm.lua" 2>/dev/null; then
    CSI_U_SOURCE="WezTerm (enable_csi_u_key_encoding=true in ~/.config/wezterm/wezterm.lua)"
elif [ "${TERM_PROGRAM}" = "WezTerm" ] || [ -n "${WEZTERM_PANE}" ]; then
    CSI_U_SOURCE="WezTerm (detected via environment)"
fi

if [ -n "$CSI_U_SOURCE" ]; then
    TMUX_EXTENDED=$(tmux show-options -gv extended-keys 2>/dev/null)
    if [ "$TMUX_EXTENDED" = "on" ] || [ "$TMUX_EXTENDED" = "always" ]; then
        echo "✅ CSI u key encoding ($CSI_U_SOURCE) compatible with tmux extended-keys=$TMUX_EXTENDED"
    else
        echo "❌ ERROR: $CSI_U_SOURCE sends CSI u key sequences, but tmux extended-keys is off"
        echo "   Ctrl+G and other modal bindings will silently fail."
        echo "   Fix: ensure 'set -g extended-keys on' is in ~/.config/tmux/tmux.conf and reload tmux."
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check tmux server
if tmux has-session 2>/dev/null; then
    echo "✅ tmux server is running"
    SESSION_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    echo "   Active sessions: $SESSION_COUNT"
else
    echo "ℹ️  INFO: tmux server is not running (this is normal if you haven't started tmux)"
fi

echo ""
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "🎉 All checks passed! zmux is properly installed."
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  Installation complete with $WARNINGS warning(s). See above for details."
    exit 0
else
    echo "❌ Installation has $ERRORS error(s) and $WARNINGS warning(s)."
    echo "   Please fix the errors above and run this script again."
    exit 1
fi

