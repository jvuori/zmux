#!/bin/bash
# ============================================================================
# Clean zmux Installation Helper
# ============================================================================
# This script removes old zmux installation files while preserving user data
# (session saves, resurrect data, custom configurations, etc.)
#
# Usage:
#   ./clean-installation.sh          # Interactive - shows what will be deleted
#   ./clean-installation.sh --yes    # Non-interactive - delete without prompting

set -e

TMUX_CONFIG_DIR="$HOME/.config/tmux"
SCRIPTS_DIR="$TMUX_CONFIG_DIR/scripts"
RESURRECT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/tmux/resurrect"
NONINTERACTIVE=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --yes|-y) NONINTERACTIVE=true ;;
        *) echo "Unknown option: $arg"; echo "Usage: $0 [--yes]"; exit 1 ;;
    esac
done

echo "🧹 zmux Installation Cleaner"
echo "═══════════════════════════════════════════════════════════════════════"
echo ""

# Check if zmux is installed
if [ ! -d "$TMUX_CONFIG_DIR" ]; then
    echo "❌ zmux is not installed at $TMUX_CONFIG_DIR"
    exit 1
fi

echo "📍 Installation directory: $TMUX_CONFIG_DIR"
echo ""
echo "This script will remove OLD zmux files:"
echo "  • Configuration files (.conf files)"
echo "  • Shell scripts (.sh files)"
echo "  • Cross-platform xdg-open wrapper"
echo ""
echo "This script will PRESERVE user data:"
echo "  • Session saves (tmux-resurrect history)"
echo "  • Session restoration data (tmux-continuum)"
echo "  • Custom tmux configurations"
echo "  • Third-party plugins"
echo "  • Any files not part of zmux distribution"
echo ""

# List of known config files to remove
CONFIG_FILES=(
    "tmux.conf"
    "keybindings.conf"
    "lock-mode-bindings.conf"
    "statusbar.conf"
    "sessions.conf"
    "plugins.conf"
)

# Count what will be deleted
DELETE_COUNT=0
PRESERVE_COUNT=0

# Count config files
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$TMUX_CONFIG_DIR/$file" ]; then
        DELETE_COUNT=$((DELETE_COUNT + 1))
    fi
done

# Count .conf files in modes directory
if [ -d "$TMUX_CONFIG_DIR/modes" ]; then
    MODES_COUNT=$(find "$TMUX_CONFIG_DIR/modes" -maxdepth 1 -name "*.conf" -type f 2>/dev/null | wc -l)
    DELETE_COUNT=$((DELETE_COUNT + MODES_COUNT))
fi

# Count .sh files in scripts directory
if [ -d "$SCRIPTS_DIR" ]; then
    SCRIPTS_COUNT=$(find "$SCRIPTS_DIR" -maxdepth 1 -name "*.sh" -type f 2>/dev/null | wc -l)
    DELETE_COUNT=$((DELETE_COUNT + SCRIPTS_COUNT))
fi

# Count files to preserve
if [ -d "$SCRIPTS_DIR" ]; then
    # Non-.sh files in scripts (user files, plugins, etc.)
    PRESERVE_COUNT=$(find "$SCRIPTS_DIR" -maxdepth 1 ! -name "*.sh" -type f 2>/dev/null | wc -l)
fi

# Count resurrect files
if [ -d "$RESURRECT_DIR" ]; then
    RESURRECT_COUNT=$(find "$RESURRECT_DIR" -type f 2>/dev/null | wc -l)
    if [ "$RESURRECT_COUNT" -gt 0 ]; then
        PRESERVE_COUNT=$((PRESERVE_COUNT + RESURRECT_COUNT))
    fi
fi

echo "📊 Summary:"
echo "  Files to DELETE: $DELETE_COUNT (old zmux files)"
echo "  Files to PRESERVE: $PRESERVE_COUNT (user data)"
echo ""

if [ "$DELETE_COUNT" -eq 0 ]; then
    echo "ℹ️  No old zmux files found to clean up. Installation is already clean!"
    exit 0
fi

# Show what will be deleted
echo "📋 Files to be deleted:"
echo ""
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$TMUX_CONFIG_DIR/$file" ]; then
        echo "  • $file"
    fi
done

if [ -d "$TMUX_CONFIG_DIR/modes" ]; then
    find "$TMUX_CONFIG_DIR/modes" -maxdepth 1 -name "*.conf" -type f -printf "  • modes/%f\n" 2>/dev/null || true
fi

if [ -d "$SCRIPTS_DIR" ]; then
    find "$SCRIPTS_DIR" -maxdepth 1 -name "*.sh" -type f -printf "  • scripts/%f\n" 2>/dev/null | sort || true
fi

if [ -f "$HOME/.local/bin/xdg-open" ]; then
    echo "  • ~/.local/bin/xdg-open"
fi

echo ""

# Ask for confirmation
if [ "$NONINTERACTIVE" != "true" ]; then
    read -p "Proceed with cleanup? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Cancelled. No files deleted."
        exit 1
    fi
fi

echo ""
echo "🗑️  Deleting old files..."

# Remove known config files
for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$TMUX_CONFIG_DIR/$file" ]; then
        rm -f "$TMUX_CONFIG_DIR/$file"
        echo "  ✓ Deleted $file"
    fi
done

# Remove .conf files from modes directory
if [ -d "$TMUX_CONFIG_DIR/modes" ]; then
    find "$TMUX_CONFIG_DIR/modes" -maxdepth 1 -name "*.conf" -type f -delete 2>/dev/null || true
fi

# Remove all .sh scripts from scripts directory
if [ -d "$SCRIPTS_DIR" ]; then
    DELETED=$(find "$SCRIPTS_DIR" -maxdepth 1 -name "*.sh" -type f -delete 2>/dev/null && find "$SCRIPTS_DIR" -maxdepth 1 -name "*.sh" -type f | wc -l || echo "0")
fi

# Clean up xdg-open wrapper
if [ -f "$HOME/.local/bin/xdg-open" ]; then
    rm -f "$HOME/.local/bin/xdg-open"
    echo "  ✓ Deleted ~/.local/bin/xdg-open"
fi

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "📊 Result:"
echo "  • Removed: $DELETE_COUNT old zmux files"
echo "  • Preserved: $PRESERVE_COUNT user data files"
echo "  • Sessions saved: $RESURRECT_DIR"
echo ""
echo "💡 Next steps:"
echo "   • Run ./install.sh to reinstall with fresh files"
echo "   • Or ./update.sh to update the configuration"
echo "   • Your session data and user files have been preserved"
echo ""
