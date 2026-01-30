#!/bin/bash
# verify-systemd.sh - Verify systemd tmux service is properly configured

set -e

echo "🔍 Verifying zmux systemd service setup..."
echo ""

ISSUES=0

# Check 1: User systemd session
echo "1️⃣  Checking user systemd session..."
if [ -n "$XDG_RUNTIME_DIR" ]; then
    echo "   ✅ XDG_RUNTIME_DIR is set: $XDG_RUNTIME_DIR"
else
    echo "   ❌ XDG_RUNTIME_DIR not set (systemd user session inactive)"
    ISSUES=$((ISSUES + 1))
fi

# Check 2: Service file exists
echo ""
echo "2️⃣  Checking service file..."
SERVICE_FILE="$HOME/.config/systemd/user/tmux.service"
if [ -f "$SERVICE_FILE" ]; then
    echo "   ✅ Service file exists: $SERVICE_FILE"
else
    echo "   ❌ Service file not found: $SERVICE_FILE"
    ISSUES=$((ISSUES + 1))
fi

# Check 3: Startup script exists
echo ""
echo "3️⃣  Checking startup script..."
STARTUP_SCRIPT="$HOME/.config/tmux/scripts/systemd-tmux-start.sh"
if [ -f "$STARTUP_SCRIPT" ]; then
    if [ -x "$STARTUP_SCRIPT" ]; then
        echo "   ✅ Startup script exists and is executable: $STARTUP_SCRIPT"
    else
        echo "   ⚠️  Startup script exists but is NOT executable: $STARTUP_SCRIPT"
        echo "      Run: chmod +x $STARTUP_SCRIPT"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "   ❌ Startup script not found: $STARTUP_SCRIPT"
    ISSUES=$((ISSUES + 1))
fi

# Check 4: tmux binary
echo ""
echo "4️⃣  Checking tmux installation..."
if command -v tmux >/dev/null 2>&1; then
    TMUX_VERSION=$(tmux -V)
    echo "   ✅ tmux is installed: $TMUX_VERSION"
else
    echo "   ❌ tmux not found in PATH"
    ISSUES=$((ISSUES + 1))
fi

# Check 5: Service status
echo ""
echo "5️⃣  Checking service status..."
if systemctl --user is-enabled tmux.service 2>/dev/null; then
    STATUS="enabled"
    echo "   ✅ Service is enabled"
else
    STATUS="disabled"
    echo "   ❌ Service is DISABLED"
    ISSUES=$((ISSUES + 1))
fi

if systemctl --user is-active tmux.service 2>/dev/null; then
    echo "   ✅ Service is currently running"
else
    echo "   ℹ️  Service is not currently running (normal until login)"
fi

# Check 6: Status file
echo ""
echo "6️⃣  Checking status file..."
STATUS_FILE="$HOME/.tmux/daemon-status"
if [ -f "$STATUS_FILE" ]; then
    STATUS=$(cat "$STATUS_FILE")
    if [ "$STATUS" = "ready" ]; then
        echo "   ✅ Status file shows: ready"
    elif [ "$STATUS" = "restoring" ]; then
        echo "   ⚠️  Status file shows: restoring (still in progress)"
    else
        echo "   ⚠️  Status file contains: $STATUS (unexpected)"
    fi
else
    echo "   ℹ️  Status file not yet created (normal until first login)"
fi

# Check 7: tmux-start.sh script
echo ""
echo "7️⃣  Checking tmux-start.sh script..."
TMUX_START_SCRIPT="$HOME/.config/tmux/scripts/tmux-start.sh"
if [ -f "$TMUX_START_SCRIPT" ]; then
    if [ -x "$TMUX_START_SCRIPT" ]; then
        echo "   ✅ Script exists and is executable: $TMUX_START_SCRIPT"
    else
        echo "   ⚠️  Script exists but is NOT executable"
        echo "      Run: chmod +x $TMUX_START_SCRIPT"
        ISSUES=$((ISSUES + 1))
    fi
else
    echo "   ❌ Script not found: $TMUX_START_SCRIPT"
    ISSUES=$((ISSUES + 1))
fi

# Check 8: tmux sessions
echo ""
echo "8️⃣  Checking tmux sessions..."
if tmux list-sessions >/dev/null 2>&1; then
    COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    echo "   ✅ tmux server is running with $COUNT session(s)"
    tmux list-sessions | sed 's/^/      /'
else
    echo "   ℹ️  tmux server not running (will start at login)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
if [ $ISSUES -eq 0 ]; then
    echo "✅ All checks passed! Systemd setup looks good."
    echo ""
    echo "Sessions will restore automatically:"
    echo "  • At next login (systemd starts the service)"
    echo "  • When you open WezTerm (attaches to restored session)"
else
    echo "❌ Found $ISSUES issue(s) that need fixing"
    echo ""
    echo "Fix the issues above, then verify again with:"
    echo "  ./verify-systemd.sh"
fi
echo "════════════════════════════════════════════════════════════"
