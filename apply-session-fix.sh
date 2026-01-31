#!/bin/bash
# Quick update script to apply session restoration fix
# This copies all updated scripts to the installation directory

echo "Applying session restoration fix..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUX_CONFIG_DIR="$HOME/.config/tmux"

# Ensure directory exists
mkdir -p "$TMUX_CONFIG_DIR/scripts"

# Copy updated scripts
echo "  Copying updated scripts..."
cp "$SCRIPT_DIR/scripts/tmux-start.sh" "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
cp "$SCRIPT_DIR/scripts/systemd-tmux-start.sh" "$TMUX_CONFIG_DIR/scripts/systemd-tmux-start.sh"
cp "$SCRIPT_DIR/scripts/save-session-before-shutdown.sh" "$TMUX_CONFIG_DIR/scripts/save-session-before-shutdown.sh"
cp "$SCRIPT_DIR/scripts/track-active-session.sh" "$TMUX_CONFIG_DIR/scripts/track-active-session.sh"

# Make executable
chmod +x "$TMUX_CONFIG_DIR/scripts/tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/systemd-tmux-start.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/save-session-before-shutdown.sh"
chmod +x "$TMUX_CONFIG_DIR/scripts/track-active-session.sh"

echo "  Copying updated config..."
cp "$SCRIPT_DIR/tmux/sessions.conf" "$TMUX_CONFIG_DIR/sessions.conf"

echo
echo "✓ All scripts updated!"
echo
echo "To test the restoration logic:"
echo "  1. Switch to the session you want to restore to (e.g., mlp)"
echo "  2. The hook will update ~/.local/share/tmux/resurrect/active-session.txt"
echo "  3. Reboot your computer"
echo "  4. When you open a terminal, it should restore to the saved session"
echo
echo "Current status:"
ACTIVE_FILE="$HOME/.local/share/tmux/resurrect/active-session.txt"
if [ -f "$ACTIVE_FILE" ]; then
    echo "  Saved session: $(cat $ACTIVE_FILE)"
else
    echo "  No saved session yet (will be saved when you switch sessions)"
fi
