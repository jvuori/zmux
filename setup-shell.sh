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

# Detect shell - prefer user's default shell, fall back to current shell
# Check user's default shell first (from $SHELL environment variable)
if [ -n "$SHELL" ]; then
    case "$SHELL" in
        *zsh*)
            SHELL_NAME="zsh"
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        *bash*)
            SHELL_NAME="bash"
            SHELL_CONFIG="$HOME/.bashrc"
            ;;
        *)
            # Fall through to check current shell
            ;;
    esac
fi

# If not detected from $SHELL, check current shell environment
if [ -z "$SHELL_NAME" ]; then
    if [ -n "$ZSH_VERSION" ]; then
        SHELL_NAME="zsh"
        SHELL_CONFIG="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_NAME="bash"
        SHELL_CONFIG="$HOME/.bashrc"
    else
        # Last resort: check which config file exists
        if [ -f "$HOME/.zshrc" ] && [ ! -f "$HOME/.bashrc" ]; then
            SHELL_NAME="zsh"
            SHELL_CONFIG="$HOME/.zshrc"
        elif [ -f "$HOME/.bashrc" ]; then
            SHELL_NAME="bash"
            SHELL_CONFIG="$HOME/.bashrc"
        else
            echo "❌ Could not detect shell. Please configure manually (see docs/shell-config.md)"
            exit 1
        fi
    fi
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
    # Disable Ctrl+a (beginning of line) - zmux uses it for lock mode
    bind '"\C-a": ""'
    # Disable Ctrl+o (operate) - zmux uses it for session mode
    bind '"\C-o": ""'
    # Use Alt+Arrow for history instead
    bind '"\e[A": history-search-backward'
    bind '"\e[B": history-search-forward'
fi

# fzf key binding configuration
# Change Ctrl+T (default) to Ctrl+F for file search
# Note: This requires fzf key bindings to be loaded (usually via ~/.fzf.bash)
if command -v fzf >/dev/null 2>&1; then
    # Function to configure fzf bindings
    _zmux_configure_fzf_bash() {
        # Unbind default Ctrl+T binding
        bind -r "\C-t" 2>/dev/null || true
        # Bind Ctrl+F to fzf file search (same as Ctrl+T was)
        # Check if __fzf_ctrl_t__ function exists (standard fzf function)
        if type __fzf_ctrl_t__ >/dev/null 2>&1; then
            bind '"\C-f": "\C-u \C-a\C-k$(__fzf_ctrl_t__)\e\C-e\C-y\C-a\C-y\ey\C-h\C-e\C-a\C-k"'
        fi
    }
    # Try to configure (will work if fzf key bindings are already loaded)
    _zmux_configure_fzf_bash
    # If fzf key bindings load later, they will override this
    # User may need to source this config again after fzf loads, or
    # ensure fzf.bash is sourced before this config in ~/.bashrc
fi

# Git operations with Ctrl+g prefix
# Ctrl+g, b: Git branch (fuzzy search with fzf)
_zmux_setup_git_bash() {
    if command -v fzf >/dev/null 2>&1 && [ -x "$HOME/.config/tmux/scripts/fzf-git-branch.sh" ]; then
        # Define git operation menu
        _git_operation() {
            read -t 0.5 -n 1 op
            case "$op" in
                b) ~/.config/tmux/scripts/fzf-git-branch.sh checkout ;;
                *) echo "Unknown git operation: $op" ;;
            esac
        }
        # Bind Ctrl+g to show git menu (requires second key)
        bind -x '"\C-g": _git_operation'
    fi
}
_zmux_setup_git_bash
EOF
elif [ "$SHELL_NAME" = "zsh" ]; then
    cat > "$ZMUX_SHELL_CONFIG" << 'EOF'
# zmux shell configuration
# Disable readline shortcuts that conflict with zmux when inside tmux
# To disable, comment out or remove the source line from your ~/.zshrc
# This configuration is compatible with Powerlevel10k instant prompt and Starship

# Function to configure zmux keybindings silently
# This avoids console output during zsh initialization (Powerlevel10k compatibility)
_zmux_configure_keys() {
    if [ -n "$TMUX" ]; then
        # Suppress all output from bindkey commands to avoid Powerlevel10k warnings
        {
            # Disable Ctrl+p (previous command) - zmux uses it for pane mode
            bindkey -r '^P'
            # Disable Ctrl+n (next command) - zmux uses it for resize mode
            bindkey -r '^N'
            # Disable Ctrl+h (backspace) - zmux uses it for move mode
            bindkey -r '^H'
            # Disable Ctrl+a (beginning of line) - zmux uses it for lock mode
            bindkey -r '^A'
            # Disable Ctrl+o (operate) - zmux uses it for session mode
            bindkey -r '^O'
            # Use Alt+Arrow for history instead
            bindkey '^[[A' history-search-backward
            bindkey '^[[B' history-search-forward
        } >/dev/null 2>&1
    fi
}

# Configure keys - function call is silent and produces no console output
_zmux_configure_keys

# fzf key binding configuration
# Change Ctrl+T (default) to Ctrl+F for file search
# Note: Ensure fzf key bindings are loaded (usually via ~/.fzf.zsh) before this config
_zmux_configure_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        {
            # Unbind default Ctrl+T binding
            bindkey -r '^T' 2>/dev/null || true
            # Bind Ctrl+F to fzf file search
            # Try the standard fzf widget names
            if (( $+functions[fzf-file-widget] )); then
                bindkey '^F' fzf-file-widget
            elif (( $+functions[__fzf_ctrl_t__] )); then
                bindkey '^F' __fzf_ctrl_t__
            fi
        } >/dev/null 2>&1
    fi
}

# Git operations with Ctrl+g prefix (zsh)
# Ctrl+g, b: Git branch (fuzzy search with fzf)
_zmux_configure_git_zsh() {
    if command -v fzf >/dev/null 2>&1 && [ -x "$HOME/.config/tmux/scripts/fzf-git-branch.sh" ]; then
        {
            # Define git operation menu widget
            _zmux_git_operation() {
                local op
                read -k op 2>/dev/null
                case "$op" in
                    b) ~/.config/tmux/scripts/fzf-git-branch.sh checkout ;;
                    *) echo "Unknown git operation: $op" ;;
                esac
            }
            zle -N _zmux_git_operation
            # Bind Ctrl+g to git menu
            bindkey '^G' _zmux_git_operation
        } >/dev/null 2>&1
    fi
}
_zmux_configure_git_zsh

# Configure fzf keys - try immediately and also set up hook for delayed loading
if [ -z "$_zmux_fzf_configured" ]; then
    # Try immediately (fzf might already be loaded)
    _zmux_configure_fzf
    
    # Set up precmd hook to configure after fzf loads (runs once)
    autoload -Uz add-zsh-hook 2>/dev/null || true
    if command -v add-zsh-hook >/dev/null 2>&1; then
        _zmux_fzf_hook() {
            _zmux_configure_fzf
            # Remove hook after first successful run
            if (( $+functions[fzf-file-widget] )) || (( $+functions[__fzf_ctrl_t__] )); then
                _zmux_fzf_configured=1
                add-zsh-hook -d precmd _zmux_fzf_hook 2>/dev/null || true
            fi
        }
        add-zsh-hook precmd _zmux_fzf_hook 2>/dev/null || true
    fi
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
