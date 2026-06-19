#!/bin/bash
# restore-pane-apps.sh
# After tmux session restore, re-launch apps that were running in each pane.
# Called on client-attached and after tmux-resurrect restore.

# Extract cursor-agent session ID (36-char UUID with hyphens)
extract_cursor_session_id() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)

    if [ -z "$content" ] || ! echo "$content" | grep -qi "cursor-agent\|resume.*session"; then
        return 1
    fi

    local session_id=$(echo "$content" | grep -i "cursor-agent" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)

    if [ -n "$session_id" ]; then
        echo "$session_id"
        return 0
    fi

    return 1
}

# Extract copilot CLI session ID (36-char UUID)
extract_copilot_session_id() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)

    if [ -z "$content" ] || ! echo "$content" | grep -qi "copilot"; then
        return 1
    fi

    local session_id=$(echo "$content" | grep -i "copilot" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)

    if [ -n "$session_id" ]; then
        echo "$session_id"
        return 0
    fi

    return 1
}

# Detect if pane had Claude Code running
detect_claude_pane() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    echo "$content" | grep -qi "claude" && return 0 || return 1
}

# Detect if pane had lazygit running
detect_lazygit_pane() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    echo "$content" | grep -qi "lazygit" && return 0 || return 1
}

# Re-launch apps in all restored panes
check_all_panes() {
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null | while read -r pane; do
        local cursor_id=$(extract_cursor_session_id "$pane")
        local copilot_id=$(extract_copilot_session_id "$pane")

        if [ -n "$cursor_id" ]; then
            tmux display-message -t "$pane" "To resume: cursor-agent --resume=$cursor_id"
        fi

        if [ -n "$copilot_id" ]; then
            tmux display-message -t "$pane" "To resume: copilot --resume=$copilot_id"
        fi

        # Claude Code: no session ID needed, --continue picks up the last conversation
        if detect_claude_pane "$pane"; then
            tmux send-keys -t "$pane" "claude --continue" Enter
        fi

        # LazyGit: just relaunch in the same directory
        if detect_lazygit_pane "$pane"; then
            tmux send-keys -t "$pane" "lazygit" Enter
        fi
    done
}

# Wait for processes to start and output to appear after restore
sleep 2

check_all_panes
