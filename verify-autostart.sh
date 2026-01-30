#!/bin/bash
# verify-autostart.sh - Verify zmux XDG autostart is properly configured

set -e

echo "🔍 Verifying zmux autostart setup..."
echo ""

ISSUES=0

# Check 1: User systemd session (for tmux-resurrect/continuum functionality)
echo "1️⃣  Checking user systemd session (used by tmux plugins)..."
if [ -n "$XDG_RUNTIME_DIR" ]; then
    echo "   ✅ XDG_RUNTIME_DIR is set: $XDG_RUNTIME_DIR"
else
    echo "   ⚠️  XDG_RUNTIME_DIR not set (some tmux plugins may not work optimally)"
fi

# Check 2: XDG autostart file
echo ""
echo "2️⃣  Checking XDG autostart configuration..."
XDG_AUTOSTART_FILE="$HOME/.config/autostart/zmux-daemon.desktop"
if [ -f "$XDG_AUTOSTART_FILE" ]; then
    echo "   ✅ XDG autostart configured: $XDG_AUTOSTART_FILE"
    echo "      This runs when you log into your desktop, BEFORE opening terminals"
else
    echo "   ❌ XDG autostart not found: $XDG_AUTOSTART_FILE"
    echo "      Run ./install.sh or ./update.sh to set it up"
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

# Check 5: tmux-start.sh script
echo ""
echo "5️⃣  Checking tmux-start.sh script..."
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

# Check 7: tmux sessions
echo ""
echo "7️⃣  Checking tmux sessions..."
if tmux list-sessions >/dev/null 2>&1; then
    COUNT=$(tmux list-sessions 2>/dev/null | wc -l)
    echo "   ✅ tmux server is running with $COUNT session(s)"
    tmux list-sessions | sed 's/^/      /'
else
    echo "   ℹ️  tmux server not running (will start at next login via XDG autostart)"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
if [ $ISSUES -eq 0 ]; then
    echo "✅ All checks passed! XDG autostart is properly configured."
    echo ""
    echo "Sessions will restore automatically:"
    echo "  • At next login (XDG autostart runs before any terminal opens)"
    echo "  • When you open WezTerm, sessions are already restored!"
else
    echo "❌ Found $ISSUES issue(s) that need fixing"
    echo ""
    echo "Fix the issues above, then verify again with:"
    echo "  ./verify-autostart.sh"
fi
echo "════════════════════════════════════════════════════════════"
