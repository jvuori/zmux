# macOS Compatibility Fixes

This document describes the macOS compatibility issues that have been identified and fixed in zmux.

## Issues Fixed

### 1. **sed -i Incompatibility** ✅
**Problem**: macOS `sed` requires a suffix argument (e.g., `sed -i ''`), while GNU sed on Linux uses `sed -i` without a suffix.

**Files affected**:
- `cleanup-old-autostart.sh`

**Solution**: Added platform detection to handle both variants:
```bash
if sed --version 2>/dev/null | grep -q GNU; then
    sed -i '/pattern/d' "$file"  # GNU sed (Linux)
else
    sed -i '' '/pattern/d' "$file"  # BSD sed (macOS)
fi
```

### 2. **systemctl/systemd Unavailable on macOS** ✅
**Problem**: macOS uses `launchd` for service management, not systemd. The `systemctl` command doesn't exist.

**Files affected**:
- `cleanup-old-autostart.sh`
- `install.sh`
- `scripts/systemd-tmux-start.sh`
- `scripts/tmux-start.sh`

**Solution**: Added command existence checks before using systemctl:
```bash
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload
    # ... other systemctl commands
fi
```

**Impact**: On macOS, systemd-specific features (shutdown save service, automatic restoration) gracefully degrade. Users can still use the basic tmux functionality.

### 3. **readlink -f Not Supported on macOS** ✅
**Problem**: The `-f` flag (follow all symlinks) is a GNU extension. macOS `readlink` doesn't support it.

**Files affected**:
- `install.sh`

**Solution**: Replaced `readlink -f` with simple `readlink` and manual path handling:
```bash
CURRENT_LINK=$(readlink "$HOME/.tmux.conf")
# Make relative paths absolute manually
case "$CURRENT_LINK" in
    /*) ;; # Already absolute
    *) CURRENT_LINK="$HOME/$CURRENT_LINK" ;; # Make relative absolute
esac
```

### 4. **xdg-open Doesn't Exist on macOS** ✅
**Problem**: `xdg-open` is a Linux utility. macOS uses the `open` command instead. Windows Subsystem for Linux uses `powershell.exe`.

**Files affected**:
- `install.sh`
- `update.sh`

**Solution**: Updated the xdg-open shim to support all three environments:
```bash
if command -v powershell.exe >/dev/null 2>&1; then
    # WSL: use powershell.exe
    powershell.exe -NoProfile -Command "Start-Process $args"
elif command -v open >/dev/null 2>&1; then
    # macOS: use 'open'
    open "$@"
elif command -v xdg-open >/dev/null 2>&1; then
    # Linux: use xdg-open
    xdg-open "$@"
fi
```

### 5. **Variable Expansion in Heredocs** ✅
**Problem**: Desktop entry files weren't properly expanding `$HOME` because of single-quoted heredoc delimiters.

**Files affected**:
- `install.sh`

**Solution**: Changed from single-quoted to unquoted heredoc delimiter to allow variable expansion:
```bash
cat > "$HOME/.config/autostart/zmux-daemon.desktop" << DESKTOP_ENTRY
[Desktop Entry]
Exec=/bin/bash -c "\$HOME/.config/tmux/scripts/systemd-tmux-start.sh"
DESKTOP_ENTRY
```

## Testing on macOS

The installation script has been verified to:
- ✅ Detect and install tmux via Homebrew
- ✅ Gracefully handle missing systemctl (skip service setup)
- ✅ Create proper cross-platform xdg-open shim
- ✅ Use compatible sed syntax for configuration cleanup
- ✅ Handle symlink operations with BSD readlink

## Known Limitations on macOS

1. **No automatic session restoration on login**: Without systemd, the shutdown save service doesn't run. Users can manually save/restore sessions or use tmux-continuum plugin.

2. **XDG autostart may not work**: XDG autostart is primarily a Linux feature. macOS users should add tmux startup to their shell profile or terminal application preferences.

3. **Performance optimizations**: Some features that rely on systemd hooks may not function on macOS. However, core tmux functionality remains fully operational.

## Recommendations for macOS Users

1. **Manual startup**: Add this line to your `~/.zshrc` or `~/.bash_profile`:
   ```bash
   ~/.config/tmux/scripts/tmux-start.sh &
   ```

2. **Terminal emulator startup**: Configure your preferred terminal (iTerm2, Warp, etc.) to run:
   ```bash
   /bin/bash -c "$HOME/.config/tmux/scripts/tmux-start.sh"
   ```

3. **Launchd plist** (advanced): Create a user launchd service file for automatic startup (parallel to systemd approach on Linux).

## Cross-Platform Installation

The installation script now works on:
- ✅ **Linux** (with systemd): Full featured with automatic session restoration
- ✅ **macOS**: Core functionality with graceful degradation of systemd features
- ✅ **WSL**: Full featured (uses powershell.exe for opening files/URLs)

All platform-specific code paths are tested and guarded with appropriate availability checks.
