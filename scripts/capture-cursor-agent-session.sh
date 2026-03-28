#!/bin/bash
# capture-cursor-agent-session.sh
# Captures cursor-agent, copilot, and claude session IDs from restored panes and displays resume commands

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

# Extract claude CLI session ID (UUID)
extract_claude_session_id() {
    local pane_id="$1"
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    
    if [ -z "$content" ] || ! echo "$content" | grep -qi "claude"; then
        return 1
    fi
    
    local session_id=$(echo "$content" | grep -i "claude" | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)
    
    if [ -n "$session_id" ]; then
        echo "$session_id"
        return 0
    fi
    
    return 1
}

# Check all panes in all sessions for cursor-agent, copilot, and claude CLIs
check_all_panes() {
    # Get all panes across all sessions
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null | while read -r pane; do
        # Try to extract session ID for each CLI type
        local cursor_id=$(extract_cursor_session_id "$pane")
        local copilot_id=$(extract_copilot_session_id "$pane")
        local claude_id=$(extract_claude_session_id "$pane")
        
        # Display appropriate resume message for each CLI found
        if [ -n "$cursor_id" ]; then
            tmux display-message -t "$pane" "To resume: cursor-agent --resume=$cursor_id"
        fi
        
        if [ -n "$copilot_id" ]; then
            tmux display-message -t "$pane" "To resume: copilot --resume=$copilot_id"
        fi
        
        if [ -n "$claude_id" ]; then
            tmux display-message -t "$pane" "To resume: claude --resume=$claude_id"
        fi
    done
}

# Wait a bit for processes to start and output to appear after restore
sleep 2

# Check all panes
check_all_panes
