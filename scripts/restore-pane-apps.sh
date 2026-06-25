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
                # Skip non-interactive modes — one-shot commands with no session to restore
                if echo "$full_cmd" | grep -qE '(^| )(-p|--print|--bg|--background)( |=|$)'; then
                    continue
                fi

                # Strip one-time flags whose side effects must not replay:
                #   --fork-session  → would fork the session again instead of continuing the fork
                #   --worktree/-w   → would create another worktree
                local restore_cmd
                restore_cmd=$(echo "$full_cmd" \
                    | sed 's/[[:space:]]*--fork-session\b//g' \
                    | sed 's/[[:space:]]*--worktree\b[[:space:]]*[^[:space:]-][^[:space:]]*//g' \
                    | sed 's/[[:space:]]*--worktree\b//g' \
                    | sed 's/[[:space:]]*-w\b[[:space:]]*[^[:space:]-][^[:space:]]*//g' \
                    | sed 's/[[:space:]]*-w\b//g' \
                    | tr -s ' ' | sed 's/^ //; s/ $//')

                # --continue, --resume, --session-id, --from-pr all target a specific session
                # and are self-sufficient — use as-is without adding --continue
                if echo "$restore_cmd" | grep -qE -- '--continue|--resume|--session-id|--from-pr'; then
                    tmux send-keys -t "$pane" "$restore_cmd" Enter 2>/dev/null || true
                else
                    tmux send-keys -t "$pane" "$restore_cmd --continue" Enter 2>/dev/null || true
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
