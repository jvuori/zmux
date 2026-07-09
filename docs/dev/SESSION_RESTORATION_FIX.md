# Session Restoration Fix

## Problem

When the computer restarts, tmux automatic session restoration was not working correctly. Instead of restoring the session that was active before shutdown, it would always select the "zmux" session or another arbitrary session based on activity timestamp.

## Root Cause

The original implementation relied on `session_activity` timestamps to determine which session was "most recent" and should be selected:

```bash
get_last_session() {
    tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2
}
```

**Problem with this approach:**

1. When tmux-continuum restores saved sessions, they all get similar timestamps (the time of restoration)
2. The first session in the list (which might be "zmux" or "default") would be selected
3. The actual active session before shutdown was lost

## Solution

The fix implements session state tracking across shutdown/restart:

### 1. **Save Active Session on Shutdown** (`save-session-before-shutdown.sh`)

Before tmux shuts down, we now save which session was active:

```bash
# Get the active client's session
ACTIVE_SESSION=$(tmux list-clients -F "#{client_session}" 2>/dev/null | head -1)

# Save the active session name
if [ -n "$ACTIVE_SESSION" ]; then
    echo "$ACTIVE_SESSION" > "$ACTIVE_SESSION_FILE"
fi
```

**File location:** `~/.local/share/tmux/resurrect/active-session.txt`

### 2. **Restore to Saved Session** (`tmux-start.sh`)

When tmux starts, we now check for the saved active session first:

```bash
get_last_session() {
    # First, check if we have a saved active session from before shutdown
    if [ -f "$ACTIVE_SESSION_FILE" ]; then
        SAVED_SESSION=$(cat "$ACTIVE_SESSION_FILE")
        # Verify the session still exists
        if [ -n "$SAVED_SESSION" ] && tmux has-session -t "$SAVED_SESSION" 2>/dev/null; then
            echo "$SAVED_SESSION"
            return 0
        fi
    fi

    # Fallback: get most recently active session by activity timestamp
    tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
        sort -t: -k1 -rn | \
        head -1 | \
        cut -d: -f2
}
```

### 3. **Clean up Helper Session** (`systemd-tmux-start.sh`)

The "default" session that was created to trigger continuum restoration is now removed after restoration completes:

```bash
# After restoration, clean up the "default" session if other sessions exist
SESSION_COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
if [ "$SESSION_COUNT" -gt 1 ]; then
    tmux kill-session -t default 2>/dev/null || true
fi
```

This prevents the "default" session from being selected as the active session.

## How It Works

### Shutdown Flow

1. System begins shutdown
2. `tmux-shutdown-save.service` triggers
3. `save-session-before-shutdown.sh` runs:
   - Saves active session to `~/.local/share/tmux/resurrect/active-session.txt`
   - Runs tmux-resurrect save to capture all session states

### Real-Time Session Tracking

The session file is **continuously updated** whenever you switch sessions:

```tmux
set-hook -g client-session-changed 'run-shell -b "echo #{client_session} > \"${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect/active-session.txt\""'
```

This hook runs every time a client changes sessions, ensuring the file always reflects the current active session. This protects against unexpected tmux crashes or system shutdowns.

### Startup Flow

1. systemd user session starts
2. `systemd-tmux-start.sh` runs:
   - Starts tmux server with a temporary "default" session
   - Waits for tmux-continuum to restore saved sessions
   - Removes the "default" helper session
   - Marks restoration as complete

3. Terminal emulator runs `tmux-start.sh`:
   - Waits for restoration to complete if needed
   - Calls `get_last_session()` which:
     - **Checks for saved active session first** (real-time tracked)
     - Returns the saved session if it still exists
     - Falls back to activity timestamp comparison if not found
   - Attaches to the correct session

## Real-Time Session Tracking

**Key improvement:** The active session is no longer just saved at shutdown. It's continuously tracked via a tmux hook in [tmux/sessions.conf](../tmux/sessions.conf) that calls a helper script:

```tmux
set-hook -g client-session-changed 'run-shell -b "~/.config/tmux/scripts/track-active-session.sh #{client_session}"'
```

The helper script [scripts/track-active-session.sh](../scripts/track-active-session.sh) updates the file every time you switch sessions:

```bash
SESSION_NAME="$1"
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
ACTIVE_FILE="$RESURRECT_DIR/active-session.txt"
echo "$SESSION_NAME" > "$ACTIVE_FILE"
```

This means:

- ✅ If you switch to session B then the system crashes, session B will be restored (not the one from last shutdown)
- ✅ If tmux is killed suddenly, we know which session was active
- ✅ The file is always in sync with your actual session usage
- ✅ Works even if systemd never runs (for fallback scenarios)

## Files Modified

1. **scripts/save-session-before-shutdown.sh**
   - Saves the active session name on shutdown
   - Creates the resurrect directory if needed

2. **scripts/tmux-start.sh**
   - Enhanced `get_last_session()` to check for saved active session first
   - Falls back to activity-based selection if saved session not found

3. **scripts/systemd-tmux-start.sh**
   - Cleans up the "default" helper session after restoration
   - Prevents the helper session from interfering with restoration

4. **scripts/track-active-session.sh** (NEW)
   - Helper script that updates the active session file
   - Called by tmux hook whenever session changes
   - Ensures real-time tracking of active sessions

5. **tmux/sessions.conf**
   - Added hook to track session changes in real-time
   - Updates active-session.txt whenever a client switches sessions

## Testing

A test script is provided at `tests/test-session-restoration.sh` that verifies:

1. Active session file is created correctly
2. Session can be found in tmux
3. Restoration reads the saved session correctly

Run with: `bash tests/test-session-restoration.sh`

## Edge Cases Handled

1. **Saved session no longer exists:** Falls back to activity-based selection
2. **No clients attached:** Uses most recently attached session
3. **First startup (no saved state):** Uses activity-based selection
4. **Multiple tmux windows open:** Uses the first client's session
5. **Manual session kill:** Automatically cleans up the helper "default" session
6. **Sudden tmux crash:** Real-time tracking ensures correct session is in file
7. **Corrupted/empty session file:** Detects and cleans up, falls back gracefully
8. **Session killed between crash and restart:** Verifies session exists before restoring, uses fallback if not

### Fallback Logic (Safe Default)

If the saved session file is missing or the saved session no longer exists, the system safely falls back:

```bash
# Fallback: get most recently active session by activity timestamp
tmux list-sessions -F "#{session_activity}:#{session_name}" 2>/dev/null | \
    sort -t: -k1 -rn | \
    head -1 | \
    cut -d: -f2
```

This ensures the system **never crashes** - it always finds _some_ session to restore, even in corner cases.

## Benefits

- ✅ Restores to the exact session that was active before shutdown
- ✅ Backward compatible (falls back to timestamp-based selection)
- ✅ Minimal overhead (single file write on shutdown)
- ✅ Automatic cleanup of helper sessions
- ✅ Works with both systemd and fallback restoration paths
