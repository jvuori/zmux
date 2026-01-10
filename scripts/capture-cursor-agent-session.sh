#!/bin/bash
# capture-cursor-agent-session.sh
# Captures cursor-agent session IDs from restored panes and displays resume command

# Function to extract session ID from pane content
extract_session_id() {
    local pane_id="$1"
    # Capture the last 100 lines of the pane to find the session ID message
    local content=$(tmux capture-pane -t "$pane_id" -p -S -100 2>/dev/null)
    
    if [ -z "$content" ]; then
        return 1
    fi
    
    # First, check if cursor-agent is mentioned in the content (to avoid false positives)
    if ! echo "$content" | grep -qi "cursor-agent\|resume.*session"; then
        return 1
    fi
    
    # Look for the pattern: "To resume this session: cursor-agent --resume=UUID"
    # or just "--resume=UUID" pattern (must be near cursor-agent context)
    local session_id=$(echo "$content" | grep -i "cursor-agent" | grep -oE '--resume=[a-f0-9-]{36}' | head -1 | sed 's/--resume=//')
    
    if [ -n "$session_id" ]; then
        echo "$session_id"
        return 0
    fi
    
    # Also try to find the full message pattern: "To resume this session: cursor-agent --resume=UUID"
    session_id=$(echo "$content" | grep -oE 'To resume this session: cursor-agent --resume=[a-f0-9-]{36}' | grep -oE '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}' | head -1)
    
    if [ -n "$session_id" ]; then
        echo "$session_id"
        return 0
    fi
    
    return 1
}

# Check all panes in all sessions for cursor-agent
check_all_panes() {
    # Get all panes across all sessions
    tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" 2>/dev/null | while read -r pane; do
        # Check if cursor-agent might be in this pane by checking pane content
        # First, try to extract session ID directly from pane content
        local session_id=$(extract_session_id "$pane")
        
        if [ -n "$session_id" ]; then
            # Found a session ID, display the message
            tmux display-message -t "$pane" "To resume this session: cursor-agent --resume=$session_id"
        fi
    done
}

# Wait a bit for processes to start and output to appear after restore
sleep 2

# Check all panes
check_all_panes
