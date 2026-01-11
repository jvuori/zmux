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

# Build ordered session list with smart ordering:
# 1. Previous session first (automatically selected)
# 2. Then all other sessions sorted by recency (most recently visited first)
# Get sessions with their last_attached timestamps for sorting
TEMP_SESSIONS="/tmp/tmux_sessions_$$"
tmux list-sessions -F "#{session_last_attached} #{session_name}" > "$TEMP_SESSIONS" 2>/dev/null

# Separate sessions: previous, current, and others
PREVIOUS_SESSION=""
OTHER_SESSIONS_ARRAY=()

while IFS= read -r line; do
    if [ -z "$line" ]; then
        continue
    fi
    
    TIMESTAMP=$(echo "$line" | awk '{print $1}')
    SESSION_NAME=$(echo "$line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    
    # Skip current session
    if [ "$SESSION_NAME" = "$CURRENT_SESSION" ]; then
        continue
    fi
    
    # Identify previous session
    if [ -n "$LAST_SESSION" ] && [ "$SESSION_NAME" = "$LAST_SESSION" ]; then
        PREVIOUS_SESSION="$TIMESTAMP $SESSION_NAME"
    else
        OTHER_SESSIONS_ARRAY+=("$TIMESTAMP $SESSION_NAME")
    fi
done < "$TEMP_SESSIONS"

# Sort other sessions by timestamp (most recent first)
IFS=$'\n' SORTED_OTHERS=($(printf '%s\n' "${OTHER_SESSIONS_ARRAY[@]}" | sort -rn))
unset IFS

# Build final list: previous first, then sorted others
FINAL_LIST=""
if [ -n "$PREVIOUS_SESSION" ]; then
    # Extract just the session name (remove timestamp)
    PREV_NAME=$(echo "$PREVIOUS_SESSION" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    FINAL_LIST="$PREV_NAME"
fi

# Add sorted other sessions (extract session names, remove timestamps)
for session_line in "${SORTED_OTHERS[@]}"; do
    SESSION_NAME=$(echo "$session_line" | awk '{for(i=2;i<=NF;i++) printf "%s%s", $i, (i<NF?" ":""); print ""}' | sed 's/ $//')
    if [ -n "$FINAL_LIST" ]; then
        FINAL_LIST="$FINAL_LIST"$'\n'"$SESSION_NAME"
    else
        FINAL_LIST="$SESSION_NAME"
    fi
done

# Clean up temp file
rm -f "$TEMP_SESSIONS" 2>/dev/null

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

# Try fzf-tmux first (best option), fallback to regular fzf
if [ -n "$FZF_TMUX_CMD" ]; then
    SELECTED=$(echo "$FINAL_LIST" | "$FZF_TMUX_CMD" -p 80%,60% \
        --header="Select session (previous session is highlighted, press Enter to select)" \
        --reverse \
        --preview="$PREVIEW_SCRIPT {}" \
        --preview-window=right:40%:follow \
        --bind 'enter:accept' \
        --bind 'ctrl-c:abort' \
        2>/dev/null)
else
    # Fallback: use regular fzf (might not work in all contexts)
    SELECTED=$(echo "$FINAL_LIST" | "$FZF_CMD" \
        --header="Select session (previous session is highlighted, press Enter to select)" \
        --height=40% \
        --reverse \
        --preview="$PREVIEW_SCRIPT {}" \
        --preview-window=right:40%:follow \
        --bind 'enter:accept' \
        --bind 'ctrl-c:abort' \
        2>/dev/null)
fi

# Clean up preview script
rm -f "$PREVIEW_SCRIPT" 2>/dev/null

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
