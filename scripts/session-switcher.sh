#!/bin/bash
# ============================================================================
# Session Switcher Script
# ============================================================================
# Interactive session switcher with last session as default
# Orders sessions so the previously active session is first and selected by default

# Note: We handle errors explicitly, so we don't use set -e

# Ensure PATH includes common fzf locations
export PATH="$HOME/.fzf/bin:$HOME/.local/bin:$PATH"

# Get the last active session (previously active session)
LAST_SESSION=$(tmux display-message -p "#{client_last_session}" 2>/dev/null)

# Get current session (to exclude it from the list)
CURRENT_SESSION=$(tmux display-message -p "#S" 2>/dev/null)

# Get all sessions
ALL_SESSIONS=$(tmux list-sessions -F "#{session_name}" 2>/dev/null)

if [ -z "$ALL_SESSIONS" ]; then
    tmux display-message "No sessions available"
    exit 1
fi

# Check if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
    echo "❌ fzf is not installed!"
    echo ""
    echo "zmux requires fzf for session switching."
    echo "Please install fzf:"
    echo "  - Ubuntu/Debian: sudo apt install fzf"
    echo "  - Or visit: https://github.com/junegunn/fzf"
    echo ""
    read -p "Press Enter to continue..."
    exit 1
fi

# Function to build the session list (used for initial load and reload)
build_session_list() {
    local current_session="$1"
    local last_session="$2"
    local temp_file="$3"
    
    local previous_session=""
    local other_sessions_array=()
    
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            continue
        fi
        
        local timestamp=$(echo "$line" | awk '{print $1}')
        local session_name=$(echo "$line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
        
        # Skip current session
        if [ "$session_name" = "$current_session" ]; then
            continue
        fi
        
        # Identify previous session
        if [ -n "$last_session" ] && [ "$session_name" = "$last_session" ]; then
            previous_session="$timestamp $session_name"
        else
            other_sessions_array+=("$timestamp $session_name")
        fi
    done < "$temp_file"
    
    # Sort other sessions by timestamp (most recent first)
    local IFS=$'\n'
    local sorted_others=($(printf '%s\n' "${other_sessions_array[@]}" | sort -rn))
    unset IFS
    
    # Build final list: previous first, then sorted others
    local final_list=""
    if [ -n "$previous_session" ]; then
        local prev_name=$(echo "$previous_session" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
        final_list="$prev_name"
    fi
    
    # Add sorted other sessions
    for session_line in "${sorted_others[@]}"; do
        local session_name=$(echo "$session_line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
        if [ -n "$final_list" ]; then
            final_list="$final_list"$'\n'"$session_name"
        else
            final_list="$session_name"
        fi
    done
    
    echo "$final_list"
}

# Build ordered session list with smart ordering:
# 1. Previous session first (automatically selected)
# 2. Then all other sessions sorted by recency (most recently visited first)
TEMP_SESSIONS="/tmp/tmux_sessions_$$"
tmux list-sessions -F "#{session_last_attached} #{session_name}" > "$TEMP_SESSIONS" 2>/dev/null

FINAL_LIST=$(build_session_list "$CURRENT_SESSION" "$LAST_SESSION" "$TEMP_SESSIONS")

# Create reload script that rebuilds the list (for use after killing sessions)
RELOAD_SCRIPT="/tmp/tmux_session_reload_$$"
cat > "$RELOAD_SCRIPT" << 'RELOAD_EOF'
#!/bin/bash
CURRENT=$(tmux display-message -p "#S" 2>/dev/null)
LAST=$(tmux display-message -p "#{client_last_session}" 2>/dev/null)
TEMP=$(mktemp)
tmux list-sessions -F "#{session_last_attached} #{session_name}" > "$TEMP" 2>/dev/null

PREVIOUS_SESSION=""
OTHER_SESSIONS_ARRAY=()

while IFS= read -r line; do
    [ -z "$line" ] && continue
    TIMESTAMP=$(echo "$line" | awk '{print $1}')
    SESSION_NAME=$(echo "$line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    [ "$SESSION_NAME" = "$CURRENT" ] && continue
    if [ -n "$LAST" ] && [ "$SESSION_NAME" = "$LAST" ]; then
        PREVIOUS_SESSION="$TIMESTAMP $SESSION_NAME"
    else
        OTHER_SESSIONS_ARRAY+=("$TIMESTAMP $SESSION_NAME")
    fi
done < "$TEMP"

IFS=$'\n' SORTED_OTHERS=($(printf '%s\n' "${OTHER_SESSIONS_ARRAY[@]}" | sort -rn))
unset IFS

FINAL_LIST=""
if [ -n "$PREVIOUS_SESSION" ]; then
    PREV_NAME=$(echo "$PREVIOUS_SESSION" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    FINAL_LIST="$PREV_NAME"
fi

for session_line in "${SORTED_OTHERS[@]}"; do
    SESSION_NAME=$(echo "$session_line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    if [ -n "$FINAL_LIST" ]; then
        FINAL_LIST="$FINAL_LIST"$'\n'"$SESSION_NAME"
    else
        FINAL_LIST="$SESSION_NAME"
    fi
done

echo "$FINAL_LIST"
rm -f "$TEMP" 2>/dev/null
RELOAD_EOF
chmod +x "$RELOAD_SCRIPT"

# If no sessions (other than current), exit
if [ -z "$FINAL_LIST" ]; then
    tmux display-message "No other sessions available"
    exit 0
fi


# Use fzf to select session, with the first item (last session) selected by default
# Use fzf-tmux which is designed to work properly with tmux
# --select-1 would auto-select if only one, but we want to show the list
# Instead, we'll use --header to indicate the first is the previous session

# Use fzf-tmux which is designed to work with tmux
# This handles the TTY properly and displays correctly
FZF_TMUX_CMD=$(command -v fzf-tmux 2>/dev/null || echo "")
FZF_CMD=$(command -v fzf 2>/dev/null || echo "fzf")

# Create a preview function to show session pane content (like original tmux-fzf)
PREVIEW_SCRIPT="/tmp/tmux_session_preview_$$"
cat > "$PREVIEW_SCRIPT" << 'PREVIEW_EOF'
#!/bin/bash
SESSION_NAME="$1"
if [ -z "$SESSION_NAME" ] || [ "$SESSION_NAME" = "[cancel]" ]; then
    echo "No session selected"
    exit 0
fi

# Extract session name (in case it has formatting)
SESSION_NAME=$(echo "$SESSION_NAME" | sed 's/: .*$//')

# Show the pane content from the first window of the session (like original tmux-fzf)
tmux capture-pane -ep -t "$SESSION_NAME:" 2>/dev/null || echo "Session not found or no content"
PREVIEW_EOF
chmod +x "$PREVIEW_SCRIPT"

# Create a kill session script for the Ctrl+x key binding
KILL_SCRIPT="/tmp/tmux_session_kill_$$"
cat > "$KILL_SCRIPT" << 'KILL_EOF'
#!/bin/bash
SESSION_NAME="$1"
if [ -z "$SESSION_NAME" ]; then
    exit 1
fi

# Extract session name (in case it has formatting)
SESSION_NAME=$(echo "$SESSION_NAME" | sed 's/: .*$//')

# Don't allow killing the current session
CURRENT=$(tmux display-message -p "#S" 2>/dev/null)
if [ "$SESSION_NAME" = "$CURRENT" ]; then
    tmux display-message "Cannot kill current session" 2>/dev/null
    exit 1
fi

# Kill the session and wait for it to complete
tmux kill-session -t "$SESSION_NAME" 2>/dev/null
KILL_RESULT=$?

# Small delay to ensure tmux fully processes the kill before reload happens
sleep 0.15

if [ $KILL_RESULT -eq 0 ]; then
    tmux display-message "Session '$SESSION_NAME' killed" 2>/dev/null
    exit 0
else
    tmux display-message "Failed to kill session '$SESSION_NAME'" 2>/dev/null
    exit 1
fi
KILL_EOF
chmod +x "$KILL_SCRIPT"

# Try fzf-tmux first (best option), fallback to regular fzf
if [ -n "$FZF_TMUX_CMD" ]; then
    SELECTED=$(echo "$FINAL_LIST" | "$FZF_TMUX_CMD" -p 70%,60% \
        --header="Select session (Enter: switch, Ctrl+x: kill)" \
        --reverse \
        --preview="$PREVIEW_SCRIPT {}" \
        --preview-window=right:55%:follow \
        --bind 'enter:accept' \
        --bind 'ctrl-x:execute-silent('"$KILL_SCRIPT"' {})+reload(sleep 0.2; '"$RELOAD_SCRIPT"')' \
        --bind 'ctrl-c:abort' \
        2>/dev/null)
else
    # Fallback: use regular fzf (might not work in all contexts)
    SELECTED=$(echo "$FINAL_LIST" | "$FZF_CMD" \
        --header="Select session (Enter: switch, Ctrl+x: kill)" \
        --height=40% \
        --reverse \
        --preview="$PREVIEW_SCRIPT {}" \
        --preview-window=right:55%:follow \
        --bind 'enter:accept' \
        --bind 'ctrl-x:execute-silent('"$KILL_SCRIPT"' {})+reload(sleep 0.2; '"$RELOAD_SCRIPT"')' \
        --bind 'ctrl-c:abort' \
        2>/dev/null)
fi

# Clean up scripts
rm -f "$PREVIEW_SCRIPT" "$KILL_SCRIPT" "$RELOAD_SCRIPT" "$TEMP_SESSIONS" 2>/dev/null

# If user cancelled (ESC or Ctrl+C), exit
if [ -z "$SELECTED" ]; then
    exit 0
fi

# Validate that the selected session still exists
if ! tmux has-session -t "$SELECTED" 2>/dev/null; then
    tmux display-message "Session '$SELECTED' no longer exists"
    exit 0
fi

# Switch to the selected session
if ! tmux switch-client -t "$SELECTED" 2>/dev/null; then
    # If switch fails, show error but exit 0 to avoid status bar error
    tmux display-message "Failed to switch to session: $SELECTED"
    exit 0
fi

exit 0
