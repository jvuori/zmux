#!/bin/bash
# restore-pane-apps.sh
# After tmux session restore, re-launch apps that were running in each pane.
# Reads program state from the tmux-resurrect 'last' file, which continuum keeps
# up-to-date automatically every ~15 minutes. No separate save step needed.
# Called on client-attached and after tmux-resurrect restore.

RESURRECT_LAST="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/last"
ORDER_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/session-order.txt"

# Resurrect file format (tab-separated, 11 fields):
#   pane | session | window | win_active | win_flags | pane_idx | pane_title | :dir | pane_active | cmd | :full_cmd
_read_resurrect_file() {
    [ -e "$RESURRECT_LAST" ] || return 1
    awk -F '\t' '$1 == "pane" {
        pane = $2 ":" $3 "." $6
        prog = $10
        full = $11
        sub(/^:/, "", full)
        if (full == "") full = prog
        print pane "|" prog "|" full
    }' "$RESURRECT_LAST" 2>/dev/null
}

restore_session_order() {
    [ -f "$ORDER_FILE" ] || return 0
    while IFS='|' read -r timestamp session_name; do
        [ -z "$session_name" ] && continue
        tmux set-option -t "$session_name" @zmux_last_used "$timestamp" 2>/dev/null || true
    done < "$ORDER_FILE"
}

restore_pane_apps() {
    local data
    data=$(_read_resurrect_file) || return 0
    [ -z "$data" ] && return 0

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
    done <<< "$data"
}

# Wait for processes to start and output to appear after restore
sleep 2

restore_session_order
restore_pane_apps
