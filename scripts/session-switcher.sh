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

# Build ordered session list: last session first (if it exists and is not current), then others
ORDERED_SESSIONS=""
OTHER_SESSIONS=""

while IFS= read -r session; do
    if [ -z "$session" ]; then
        continue
    fi
    
    # Skip current session
    if [ "$session" = "$CURRENT_SESSION" ]; then
        continue
    fi
    
    # Put last session first
    if [ -n "$LAST_SESSION" ] && [ "$session" = "$LAST_SESSION" ] && [ "$session" != "$CURRENT_SESSION" ]; then
        ORDERED_SESSIONS="$session"$'\n'"$ORDERED_SESSIONS"
    else
        OTHER_SESSIONS="$OTHER_SESSIONS"$'\n'"$session"
    fi
done <<< "$ALL_SESSIONS"

# Combine: last session first, then others
FINAL_LIST=$(echo -e "$ORDERED_SESSIONS$OTHER_SESSIONS" | grep -v '^$')

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
        --header="Select session (first is previous session, press Enter to select)" \
        --reverse \
        --preview="$PREVIEW_SCRIPT {}" \
        --preview-window=right:40%:follow \
        --bind 'enter:accept' \
        --bind 'ctrl-c:abort' \
        2>/dev/null)
else
    # Fallback: use regular fzf (might not work in all contexts)
    SELECTED=$(echo "$FINAL_LIST" | "$FZF_CMD" \
        --header="Select session (first is previous session, press Enter to select)" \
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
