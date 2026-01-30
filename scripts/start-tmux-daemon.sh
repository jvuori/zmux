#!/bin/bash
# start-tmux-daemon.sh - Start tmux daemon at login (shell profile version)
#
# This script is sourced from shell profile files (~/.profile, ~/.zprofile)
# to start the tmux daemon with session restoration at login time.
# More reliable than systemd user services across different distros.

# Only run if we're in an interactive login shell and not already running
if [ -n "$PS1" ] && [ -z "$TMUX_DAEMON_STARTED" ]; then
    export TMUX_DAEMON_STARTED=1
    
    # Check if tmux daemon is already running
    if ! tmux list-sessions >/dev/null 2>&1; then
        # Start daemon in background, don't block login
        (
            "$HOME/.config/tmux/scripts/systemd-tmux-start.sh" >/dev/null 2>&1 &
        )
    fi
fi
