#!/bin/bash
# restore-pane-apps.sh
# After tmux session restore, re-launch apps that were running in each pane.
# Reads pane-programs.txt written by save-pane-programs.sh at save time.
# Called on client-attached and after tmux-resurrect restore.

PROGRAMS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane-programs.txt"

# Extract a UUID from pane scrollback, optionally filtering by a keyword
extract_uuid_from_scrollback() {
    local pane_id="$1" keyword="$2"
    tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null \
        | grep -i "$keyword" \
        | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' \
        | head -1
}

# Strip a flag and its value (--flag=value or --flag) from a command string
strip_flag() {
    local cmd="$1" flag="$2"
    echo "$cmd" | sed "s/\s*${flag}=[^ ]*//g; s/\s*${flag}\b//g" | tr -s ' ' | sed 's/^ //; s/ $//'
}

restore_pane_apps() {
    if [ ! -f "$PROGRAMS_FILE" ]; then
        return 0
    fi

    while IFS='|' read -r pane program full_cmd; do
        [ -z "$pane" ] || [ -z "$program" ] && continue
        [ -z "$full_cmd" ] && full_cmd="$program"

        case "$program" in
            claude)
                # Preserve original flags; strip any stale --continue and re-append it
                local base_cmd=$(strip_flag "$full_cmd" "--continue")
                tmux send-keys -t "$pane" "$base_cmd --continue" Enter 2>/dev/null || true
                ;;
            cursor-agent)
                # Preserve original flags; replace any stale --resume with the new UUID
                local base_cmd=$(strip_flag "$full_cmd" "--resume")
                local cursor_id=$(extract_uuid_from_scrollback "$pane" "cursor-agent")
                if [ -n "$cursor_id" ]; then
                    tmux send-keys -t "$pane" "$base_cmd --resume=$cursor_id" Enter 2>/dev/null || true
                else
                    tmux send-keys -t "$pane" "$base_cmd" Enter 2>/dev/null || true
                fi
                ;;
            copilot)
                # Preserve original flags; replace any stale --resume with the new UUID
                local base_cmd=$(strip_flag "$full_cmd" "--resume")
                local copilot_id=$(extract_uuid_from_scrollback "$pane" "copilot")
                if [ -n "$copilot_id" ]; then
                    tmux send-keys -t "$pane" "$base_cmd --resume=$copilot_id" Enter 2>/dev/null || true
                else
                    tmux send-keys -t "$pane" "$base_cmd" Enter 2>/dev/null || true
                fi
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
