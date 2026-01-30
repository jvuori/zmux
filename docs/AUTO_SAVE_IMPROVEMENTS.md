# Session Auto-Save Improvements

## Problem

Sessions were being restored from old snapshots after reboot, with recent tabs/panes missing. This happened because:

1. **Auto-save interval was too long**: tmux-continuum was set to save every 15 minutes
2. **No shutdown hook**: There was no mechanism to save the session before system shutdown/reboot
3. **Systemd services get disabled on reboot**: User systemd services may get disabled after reboot
4. **Result**: Any changes made within the last 15 minutes before shutdown were lost

## Root Cause Analysis

After investigation, we found that:

- **Auto-save WAS working**: tmux-continuum saves every time the status bar updates (every few seconds)
- **But only if enough time has passed**: It checks if `interval` minutes have passed since last save
- **And only if there are changes**: If the session hasn't changed, it updates the timestamp but doesn't create a new file
- **Gap from 23:51 to 01:12**: This was because the system was rebooted/shut down, so tmux wasn't running during that period
- **The real issue**: No save happens before shutdown, so changes in the last 5-15 minutes are lost on reboot

## Solution Implemented

### 1. Reduced Auto-Save Interval

Changed the auto-save interval from 15 minutes to **5 minutes**:

**File**: [plugins/plugins.conf](../plugins/plugins.conf)

```conf
# Save every 5 minutes (reduced from 15 to minimize data loss on unexpected shutdown)
set -g @continuum-save-interval '5'
```

This means your session is now automatically saved every 5 minutes while tmux is running.

### 2. Added Shutdown Save Hook

Created a systemd service that saves the tmux session before system shutdown/reboot:

**Files Created**:

- [scripts/save-session-before-shutdown.sh](../scripts/save-session-before-shutdown.sh) - Script that saves the session
- [tmux-shutdown-save.service](../tmux-shutdown-save.service) - Systemd service definition

**How it works**:

1. The systemd service is configured to run before shutdown/reboot/halt
2. It calls the save script which uses tmux-resurrect to save the current session
3. The service has a 5-second timeout to ensure it doesn't delay shutdown

**Installation**: The service is automatically installed and enabled by:

- `install.sh` - For new installations
- `update.sh` - For existing installations

### 4. Auto-Enable Shutdown Service on Startup

Since systemd user services can get disabled after reboot, we added checks in both startup scripts to automatically re-enable the shutdown save service if it gets disabled:

**Files Modified**:

- [scripts/tmux-start.sh](../scripts/tmux-start.sh) - Checks and enables shutdown service on terminal startup
- [scripts/systemd-tmux-start.sh](../scripts/systemd-tmux-start.sh) - Checks and enables shutdown service on daemon startup

**How it works**:

1. Every time tmux starts (via terminal or XDG autostart), the startup script checks if the shutdown save service is enabled
2. If disabled, it automatically enables it again
3. This ensures the shutdown hook always works, even if systemd disables it after reboot

### 3. Updated Installation Scripts

Modified both installation scripts to include the shutdown save functionality:

**Updated Files**:

- [install.sh](../install.sh) - Copies the save script and installs the systemd service
- [update.sh](../update.sh) - Updates the save script and systemd service

## Verification

You can verify the setup with these commands:

```bash
# Check auto-save interval (should be 5)
tmux show-options -g | grep continuum-save-interval

# Check systemd service status
systemctl --user status tmux-shutdown-save.service

# Check if service is enabled
systemctl --user is-enabled tmux-shutdown-save.service

# Manually test the save script
~/.config/tmux/scripts/save-session-before-shutdown.sh
```

## Session Save Mechanisms

Your tmux session is now saved in three ways:

1. **Automatic periodic saves**: Every 5 minutes (tmux-continuum)
2. **On shutdown/reboot**: Before system shuts down (systemd service)
3. **Manual save**: Press `Ctrl+q` to save and quit tmux (configured in keybindings)

Additionally, you can manually save at any time with `Ctrl+a`, then `Ctrl+s`.

## Impact

- **Minimal data loss**: With 5-minute auto-saves, you'll lose at most 5 minutes of work on unexpected crashes
- **Clean shutdowns**: Normal reboots/shutdowns will preserve your exact session state
- **Better reliability**: Multiple save mechanisms provide redundancy

## Files Modified

1. [plugins/plugins.conf](../plugins/plugins.conf) - Reduced auto-save interval to 5 minutes
2. [install.sh](../install.sh) - Added shutdown save script and systemd service installation
3. [update.sh](../update.sh) - Added shutdown save script and systemd service update
4. [scripts/tmux-start.sh](../scripts/tmux-start.sh) - Added shutdown service enable check
5. [scripts/systemd-tmux-start.sh](../scripts/systemd-tmux-start.sh) - Added shutdown service enable check

## Files Created

1. [scripts/save-session-before-shutdown.sh](../scripts/save-session-before-shutdown.sh) - Save script
2. [tmux-shutdown-save.service](../tmux-shutdown-save.service) - Systemd service template

## Testing

To test that the shutdown save works:

1. Make some changes in tmux (create a new tab, pane, etc.)
2. Test the shutdown save script manually:
   ```bash
   ~/.config/tmux/scripts/save-session-before-shutdown.sh
   ```
3. Check that the save happened:
   ```bash
   ls -lh ~/.tmux/resurrect/last
   ```
4. You should see a recent timestamp

TheImportant Notes

### How tmux-continuum Auto-Save Works

tmux-continuum doesn't run as a separate background process. Instead:

1. It adds a script call to the status bar: `#(~/.tmux/plugins/tmux-continuum/scripts/continuum_save.sh)`
2. Every time the status bar refreshes (every few seconds), this script is executed
3. The script checks if enough time has passed since the last save (5 minutes)
4. If yes, AND if the session has changed, it saves a new snapshot
5. It always updates the `@continuum-save-last-timestamp` option to prevent excessive saves

**This means**:

- Auto-save only works while tmux is running
- If you reboot without the shutdown hook, the last 0-5 minutes of changes are lost
- The status bar must be enabled for auto-save to work

### Shutdown Save Service

- The systemd service runs **before** shutdown, so it has time to save
- The 5-second timeout ensures the shutdown process isn't delayed
- If tmux isn't running, the script exits gracefully without errors
- The service is enabled at the user level (doesn't require sudo)
- **Important**: Startup scripts auto-enable this service if it gets disabled after reboot

### Why There Was a Gap in Saves

The observed gap from 23:51 (Jan 30) to 01:12 (Jan 31) was NOT due to a broken auto-save. It was because:

1. The system was shut down or rebooted between those times
2. tmux wasn't running, so no auto-saves occurred
3. The shutdown hook didn't exist yet, so no final save was made
4. After reboot, the first save was at 01:12 when we manually triggered it

With the new shutdown hook, this gap will no longer occur - the session will be saved immediately before shutdown.

- If tmux isn't running, the script exits gracefully without errors
- The service is enabled at the user level (doesn't require sudo)
