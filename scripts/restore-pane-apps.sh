#!/bin/bash
# restore-pane-apps.sh
# After tmux session restore, re-launch apps that were running in each pane.
# Reads pane-programs.txt written by save-pane-programs.sh at save time.
# Called on client-attached and after tmux-resurrect restore.

PROGRAMS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane-programs.txt"

restore_pane_apps() {
    if [ ! -f "$PROGRAMS_FILE" ]; then
        return 0
    fi

    while IFS='|' read -r pane program full_cmd; do
        [ -z "$pane" ] || [ -z "$program" ] && continue
        [ -z "$full_cmd" ] && full_cmd="$program"

        # Skip panes that are already running a non-shell program.
        # This prevents double-restore on re-attach without a full tmux restart.
        local current=$(tmux display-message -t "$pane" -p "#{pane_current_command}" 2>/dev/null)
        case "$current" in
            bash|zsh|sh|fish|ksh|dash|csh|tcsh) ;;  # at shell prompt, proceed
            *) continue ;;                            # already running something, skip
        esac

        case "$program" in
            claude)
                # Add --continue if not already present; preserve all other flags
                if echo "$full_cmd" | grep -q -- '--continue'; then
                    tmux send-keys -t "$pane" "$full_cmd" Enter 2>/dev/null || true
                else
                    tmux send-keys -t "$pane" "$full_cmd --continue" Enter 2>/dev/null || true
                fi
                ;;
            cursor-agent|copilot)
                # Session UUID is stored in the tool's own state and survives reboots.
                # Use the saved command as-is: --resume=UUID is still valid if it was there,
                # or absent if the user started without it (fresh session intended).
                tmux send-keys -t "$pane" "$full_cmd" Enter 2>/dev/null || true
                ;;
            bash|zsh|sh|fish|ksh|dash|csh|tcsh)
                # Shell — nothing to restore
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
