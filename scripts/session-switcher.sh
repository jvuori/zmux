#!/bin/bash
# ============================================================================
# Session Switcher Script
# ============================================================================
# Interactive session switcher using sainnhe/tmux-fzf (required plugin)
# This plugin provides fullscreen session switching via fzf

# Ensure PATH includes common fzf locations
export PATH="$HOME/.fzf/bin:$HOME/.local/bin:$PATH"

# Execute the plugin's session.sh script directly with "switch" action
# We change to the plugin directory to ensure relative paths work correctly
TMUX_FZF_DIR="$HOME/.tmux/plugins/tmux-fzf"

# Debug: Log execution
echo "Session switcher called" >> /tmp/tmux_session_switcher.log 2>&1
echo "PATH: $PATH" >> /tmp/tmux_session_switcher.log 2>&1
echo "fzf: $(command -v fzf 2>&1)" >> /tmp/tmux_session_switcher.log 2>&1

if [ -f "$TMUX_FZF_DIR/scripts/session.sh" ]; then
    # Change to plugin directory and execute the script
    cd "$TMUX_FZF_DIR" || exit 1
    echo "Executing: $TMUX_FZF_DIR/scripts/session.sh switch" >> /tmp/tmux_session_switcher.log 2>&1
    # Use bash explicitly and ensure we're in the right directory
    bash -c "cd '$TMUX_FZF_DIR' && bash scripts/session.sh switch" 2>> /tmp/tmux_session_switcher.log
    exit $?
else
    echo "ERROR: $TMUX_FZF_DIR/scripts/session.sh not found" >> /tmp/tmux_session_switcher.log 2>&1
    tmux display-message "Session switcher: Plugin script not found"
    exit 1
fi

# Fallback to main.sh if session.sh doesn't exist (shouldn't happen)
if [ -f ~/.tmux/plugins/tmux-fzf/main.sh ]; then
    # Launch tmux-fzf main menu - user can then select "session"
    ~/.tmux/plugins/tmux-fzf/main.sh
    exit 0
fi

# If tmux-fzf is not available, show error and instructions
echo "❌ tmux-fzf plugin (sainnhe/tmux-fzf) is not installed!"
echo ""
echo "zmux requires tmux-fzf for session switching."
echo "Please install plugins:"
echo "  1. In tmux, press Ctrl+a, then I"
echo "  2. Or run: bash ~/.tmux/plugins/tpm/bin/install_plugins"
echo ""
read -p "Press Enter to continue..."
exit 1

