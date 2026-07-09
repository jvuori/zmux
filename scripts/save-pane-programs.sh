#!/bin/bash
# save-pane-programs.sh
# Saves the foreground program + arguments for each pane alongside tmux-resurrect.
# Format: session:window.pane|program_name|full_command_with_args
# restore-pane-apps.sh reads this file to re-launch programs after restore.

PROGRAMS_FILE="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/pane-programs.txt"

save_pane() {
    local pane="$1" shell_pid="$2" program="$3"

    # For shells there are no args to capture — record name only
    case "$program" in
        bash|zsh|sh|fish|ksh|dash|csh|tcsh)
            printf '%s|%s|%s\n' "$pane" "$program" "$program"
            return
            ;;
    esac

    # Find the child process of the shell that matches the program name
    local child_pid full_cmd
    child_pid=$(ps -o pid=,comm= --ppid "$shell_pid" 2>/dev/null \
                | awk -v p="$program" '$2==p{print $1;exit}')

    if [ -n "$child_pid" ]; then
        # Read full command from /proc, stripping leading path from argv[0]
        full_cmd=$(ps -o args= -p "$child_pid" 2>/dev/null | sed 's|^[^ ]*/||')
    fi

    printf '%s|%s|%s\n' "$pane" "$program" "${full_cmd:-$program}"
}

> "$PROGRAMS_FILE"
while IFS='|' read -r pane shell_pid program; do
    save_pane "$pane" "$shell_pid" "$program"
done < <(tmux list-panes -a \
    -F "#{session_name}:#{window_index}.#{pane_index}|#{pane_pid}|#{pane_current_command}" \
    2>/dev/null) >> "$PROGRAMS_FILE"
