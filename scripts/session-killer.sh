#!/bin/bash
# ============================================================================
# Session Killer Script
# ============================================================================
# Delete sessions using sainnhe/tmux-fzf (required plugin)

# Ensure PATH includes common fzf locations
export PATH="$HOME/.fzf/bin:$HOME/.local/bin:$PATH"

# We'll override the header after the plugin sets it
# The plugin appends to FZF_DEFAULT_OPTS, so we need to ensure our warning
# header comes last (fzf uses the last --header option)

# Execute the plugin's session.sh script with "kill" action
TMUX_FZF_DIR="$HOME/.tmux/plugins/tmux-fzf"

if [ -f "$TMUX_FZF_DIR/scripts/session.sh" ]; then
    # Change to plugin directory
    cd "$TMUX_FZF_DIR" || exit 1
    # Create a wrapper that patches the header after the plugin sets it
    # We'll use sed to replace the header line in the script's output/execution
    # Actually, simpler: we'll modify FZF_DEFAULT_OPTS after sourcing .envs but before the kill action
    # The cleanest way is to patch the script call to add our header after theirs
    bash -c "
        cd '$TMUX_FZF_DIR'
        source scripts/.envs
        # Override width to make dialog wider (80% instead of default 62%)
        # This ensures the warning text isn't truncated
        export TMUX_FZF_OPTIONS=\"-p -w 80% -h 38% -m\"
        # The plugin will set its header, but we append ours which takes precedence
        export FZF_DEFAULT_OPTS=\"\$FZF_DEFAULT_OPTS --header='⚠️  WARNING: DELETE session(s)! This cannot be undone. Press TAB for multiple selection.'\"
        # Now call the kill action with our modified environment
        action='kill'
        sessions=\$(tmux list-sessions)
        if [[ -z \"\$TMUX_FZF_SWITCH_CURRENT\" ]]; then
            current_session=\$(tmux display-message -p | sed -e 's/^\[//' -e 's/\].*//')
            sessions=\$(echo \"\$sessions\" | grep -v \"^\$current_session: \")
        fi
        FZF_DEFAULT_OPTS=\"\$FZF_DEFAULT_OPTS --header='⚠️  WARNING: DELETE session(s)! This cannot be undone. Press TAB for multiple selection.'\"
        target_origin=\$(printf \"%s\n[cancel]\" \"\$sessions\" | eval \"\$TMUX_FZF_BIN \$TMUX_FZF_OPTIONS \$TMUX_FZF_PREVIEW_SESSION_OPTIONS\")
        [[ \"\$target_origin\" == \"[cancel]\" || -z \"\$target_origin\" ]] && exit
        echo \"\$target_origin\" | sort -r | xargs -I{} tmux kill-session -t \"{}\"
    " 2>> /tmp/tmux_session_killer.log
    exit $?
else
    tmux display-message "Session killer: Plugin script not found"
    exit 1
fi
