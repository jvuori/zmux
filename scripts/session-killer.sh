#!/bin/bash
# ============================================================================
# Session Killer Script
# ============================================================================
# Delete sessions using sainnhe/tmux-fzf (required plugin)

# Ensure PATH includes common fzf locations
export PATH="$HOME/.fzf/bin:$HOME/.local/bin:$PATH"

# Execute the plugin's session.sh script with "kill" action
TMUX_FZF_DIR="$HOME/.tmux/plugins/tmux-fzf"

if [ -f "$TMUX_FZF_DIR/scripts/session.sh" ]; then
    # Change to plugin directory and execute the script
    cd "$TMUX_FZF_DIR" || exit 1
    # Override width to make dialog wider (80% instead of default 62%)
    export TMUX_FZF_OPTIONS="-p -w 80% -h 38% -m"
    # Override the header - the plugin will set its header, but we override it
    # by setting FZF_DEFAULT_OPTS with our header (fzf uses the last --header)
    export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS} --header='⚠️  WARNING: DELETE session(s)! This cannot be undone. Press TAB for multiple selection.'"
    # Execute the plugin script directly with "kill" action
    exec bash scripts/session.sh kill
else
    tmux display-message "Session killer: Plugin script not found"
    exit 1
fi
