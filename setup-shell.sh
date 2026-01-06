#!/bin/bash
# ============================================================================
# Setup Shell Configuration for zmux
# ============================================================================
# This script creates a separate shell config file that can be sourced from
# your ~/.bashrc or ~/.zshrc, making it easy to enable/disable

set -e

SHELL_CONFIG=""
SHELL_NAME=""
ZMUX_SHELL_CONFIG="$HOME/.config/zmux/shell-config"

# Detect shell
if [ -n "$ZSH_VERSION" ]; then
    SHELL_NAME="zsh"
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -n "$BASH_VERSION" ]; then
    SHELL_NAME="bash"
    SHELL_CONFIG="$HOME/.bashrc"
else
    echo "❌ Unsupported shell. Please configure manually (see docs/shell-config.md)"
    exit 1
fi

echo "🔧 Setting up $SHELL_NAME configuration for zmux..."
echo ""

# Create zmux config directory
mkdir -p "$HOME/.config/zmux"

# Create the shell config file
if [ "$SHELL_NAME" = "bash" ]; then
    cat > "$ZMUX_SHELL_CONFIG" << 'EOF'
# zmux shell configuration
# Disable readline shortcuts that conflict with zmux when inside tmux
# To disable, comment out or remove the source line from your ~/.bashrc

if [ -n "$TMUX" ]; then
    # Disable Ctrl+p (previous command) - zmux uses it for pane mode
    bind '"\C-p": ""'
    # Disable Ctrl+n (next command) - zmux uses it for resize mode
    bind '"\C-n": ""'
    # Disable Ctrl+h (backspace) - zmux uses it for move mode
    bind '"\C-h": ""'
    # Disable Ctrl+g (abort) - zmux uses it for lock mode
    bind '"\C-g": ""'
    # Use Alt+Arrow for history instead
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi
EOF
elif [ "$SHELL_NAME" = "zsh" ]; then
    cat > "$ZMUX_SHELL_CONFIG" << 'EOF'
# zmux shell configuration
# Disable readline shortcuts that conflict with zmux when inside tmux
# To disable, comment out or remove the source line from your ~/.zshrc

if [ -n "$TMUX" ]; then
    # Disable Ctrl+p (previous command) - zmux uses it for pane mode
    bindkey -r '^P'
    # Disable Ctrl+n (next command) - zmux uses it for resize mode
    bindkey -r '^N'
    # Disable Ctrl+h (backspace) - zmux uses it for move mode
    bindkey -r '^H'
    # Disable Ctrl+g (abort) - zmux uses it for lock mode
    bindkey -r '^G'
    # Use Alt+Arrow for history instead
    bindkey '^[[A' history-search-backward
    bindkey '^[[B' history-search-forward
fi
EOF
fi

echo "✅ Created shell config file: $ZMUX_SHELL_CONFIG"

# Check if already sourced in shell config
SOURCE_LINE="[ -f $ZMUX_SHELL_CONFIG ] && source $ZMUX_SHELL_CONFIG  # zmux shell config"
if grep -q "zmux shell config" "$SHELL_CONFIG" 2>/dev/null; then
    echo "✅ Already configured in $SHELL_CONFIG"
    echo ""
    echo "To disable zmux keybindings, comment out this line in $SHELL_CONFIG:"
    grep "zmux shell config" "$SHELL_CONFIG" | head -1
else
    echo ""
    echo "📝 Adding source line to $SHELL_CONFIG..."
    echo "" >> "$SHELL_CONFIG"
    echo "$SOURCE_LINE" >> "$SHELL_CONFIG"
    echo "✅ Added to $SHELL_CONFIG"
fi

echo ""
echo "✅ Setup complete!"
echo ""
echo "The configuration is in: $ZMUX_SHELL_CONFIG"
echo ""
echo "To enable/disable zmux keybindings:"
echo "  - Edit $SHELL_CONFIG"
echo "  - Comment/uncomment the line:"
echo "    # [ -f $ZMUX_SHELL_CONFIG ] && source $ZMUX_SHELL_CONFIG  # zmux shell config"
echo ""
echo "⚠️  Reload your shell configuration:"
echo "   source $SHELL_CONFIG"
