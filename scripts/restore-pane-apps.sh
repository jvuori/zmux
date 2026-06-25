#!/bin/bash
# restore-pane-apps.sh
# After tmux session restore, re-launch apps that were running in each pane.
# Reads pane-programs.txt written by save-pane-programs.sh at save time.
# Called on client-attached and after tmux-resurrect restore.

PROGRAMS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane-programs.txt"

# Extract cursor-agent session ID (36-char UUID) from pane scrollback
extract_cursor_session_id() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    echo "$content" | grep -i "cursor-agent" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1
}

# Extract copilot CLI session ID (36-char UUID) from pane scrollback
extract_copilot_session_id() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    echo "$content" | grep -i "copilot" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1
}

restore_pane_apps() {
    if [ ! -f "$PROGRAMS_FILE" ]; then
        return 0
    fi

    while IFS='|' read -r pane program full_cmd; do
        [ -z "$pane" ] || [ -z "$program" ] && continue
        # Fall back to program name if full_cmd is missing (old save file)
        [ -z "$full_cmd" ] && full_cmd="$program"

        case "$program" in
            claude)
                tmux send-keys -t "$pane" "claude --continue" Enter 2>/dev/null || true
                ;;
            cursor-agent)
                local cursor_id=$(extract_cursor_session_id "$pane")
                [ -n "$cursor_id" ] && tmux display-message -t "$pane" "To resume: cursor-agent --resume=$cursor_id" 2>/dev/null || true
                ;;
            copilot)
                local copilot_id=$(extract_copilot_session_id "$pane")
                [ -n "$copilot_id" ] && tmux display-message -t "$pane" "To resume: copilot --resume=$copilot_id" 2>/dev/null || true
                ;;
            bash|zsh|sh|fish|ksh|dash|csh|tcsh)
                # Shell — pane is already at a prompt, nothing to restore
                ;;
            dd|mkfs|mkfs.*|fdisk|parted|gdisk|apt|apt-get|dpkg|pacman|yum|dnf|brew)
                # Destructive or stateful system ops — never auto-restart
                ;;
            *)
                # Generic: re-launch with original arguments (vim file.txt, htop, etc.)
                tmux send-keys -t "$pane" "$full_cmd" Enter 2>/dev/null || true
                ;;
        esac
    done < "$PROGRAMS_FILE"
}

# Wait for processes to start and output to appear after restore
sleep 2

restore_pane_apps
