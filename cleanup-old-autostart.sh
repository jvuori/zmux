#!/bin/bash
# cleanup-old-autostart.sh - Remove old systemd and shell profile autostart mechanisms
# Run this to clean up previous installation attempts that used unreliable methods

set -e

echo "🧹 Cleaning up old autostart mechanisms..."
echo ""

CLEANED=0

# 1. Remove systemd service
echo "1️⃣  Removing systemd service..."
if systemctl --user is-enabled tmux.service 2>/dev/null; then
    systemctl --user disable tmux.service 2>/dev/null && echo "   ✅ Disabled systemd service"
    CLEANED=$((CLEANED + 1))
fi

if systemctl --user is-active tmux.service 2>/dev/null; then
    systemctl --user stop tmux.service 2>/dev/null && echo "   ✅ Stopped systemd service"
    CLEANED=$((CLEANED + 1))
fi

if [ -f "$HOME/.config/systemd/user/tmux.service" ]; then
    rm "$HOME/.config/systemd/user/tmux.service"
    echo "   ✅ Removed service file"
    CLEANED=$((CLEANED + 1))
fi

# 2. Remove shell profile entries
echo ""
echo "2️⃣  Removing shell profile autostart entries..."
for profile in ~/.profile ~/.zprofile ~/.bash_profile ~/.bashrc ~/.zshrc; do
    if [ -f "$profile" ]; then
        if grep -q "start-tmux-daemon.sh" "$profile" 2>/dev/null; then
            # Create backup
            cp "$profile" "${profile}.backup-$(date +%Y%m%d_%H%M%S)"
            # Remove the zmux autostart lines
            sed -i '/# zmux: Auto-start tmux daemon/d' "$profile"
            sed -i '/start-tmux-daemon\.sh/d' "$profile"
            echo "   ✅ Removed autostart from $profile (backup created)"
            CLEANED=$((CLEANED + 1))
        fi
    fi
done

# 3. Remove start-tmux-daemon.sh script (no longer needed)
echo ""
echo "3️⃣  Removing obsolete scripts..."
if [ -f "$HOME/.config/tmux/scripts/start-tmux-daemon.sh" ]; then
    rm "$HOME/.config/tmux/scripts/start-tmux-daemon.sh"
    echo "   ✅ Removed start-tmux-daemon.sh"
    CLEANED=$((CLEANED + 1))
fi

# 4. Disable lingering if no other user services exist
echo ""
echo "4️⃣  Checking user lingering..."
USER_SERVICES=$(systemctl --user list-units --type=service --state=enabled 2>/dev/null | wc -l)
if [ "$USER_SERVICES" -le 1 ]; then
    if loginctl show-user "$USER" 2>/dev/null | grep -q "Linger=yes"; then
        echo "   ℹ️  User lingering is enabled but no zmux services use it"
        echo "   You can disable it manually if you don't need it:"
        echo "   sudo loginctl disable-linger $USER"
    fi
else
    echo "   ℹ️  User lingering still needed by other services"
fi

# Summary
echo ""
echo "════════════════════════════════════════════════════════════"
if [ $CLEANED -gt 0 ]; then
    echo "✅ Cleanup complete! Removed $CLEANED old autostart mechanism(s)"
    echo ""
    echo "Only XDG autostart remains:"
    echo "  ~/.config/autostart/zmux-daemon.desktop"
    echo ""
    echo "This will run when you log into your desktop, BEFORE any terminal opens"
else
    echo "✅ No old mechanisms found - system is already clean!"
fi
echo "════════════════════════════════════════════════════════════"

# Reload systemd to pick up changes
if systemctl --user daemon-reload 2>/dev/null; then
    echo ""
    echo "✅ Systemd configuration reloaded"
fi
