#!/bin/bash
# systemd-tmux-start.sh - Start tmux for systemd service
# This script ensures tmux starts properly for background daemon use
# and triggers tmux-continuum to restore previous sessions.

# Ensure required directories exist
mkdir -p ~/.tmux/resurrect
mkdir -p ~/.config/tmux/scripts

# Kill any existing tmux server to ensure clean start
tmux kill-server 2>/dev/null || true
sleep 0.3

# Start tmux server with a "default" session
# This session will trigger tmux-continuum auto-restore of saved sessions
# Using "default" as the session name since this is the fallback session
/usr/bin/tmux new-session -d -s default -c "$HOME" -x 200 -y 60

# Wait for continuum to restore sessions
# The continuum plugin will detect saved sessions and restore them
sleep 3

# Exit successfully - the tmux server continues running in the background
exit 0
