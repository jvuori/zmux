#!/bin/bash
# Test zmux installation procedure
# Verifies that install.sh completes successfully and all files are in place

set -e

echo "Testing zmux installation..."

# Run the installer with non-interactive mode
# Skip shell config prompts by answering 'y' automatically
if ! echo "y" | bash install.sh; then
    echo "ERROR: Installation failed"
    exit 1
fi

echo "✓ Installation completed"

# Check if tmux config directory exists
if [ ! -d "$HOME/.config/tmux" ]; then
    echo "ERROR: Tmux config directory not created"
    exit 1
fi

echo "✓ Config directory created"

# Check if main config files exist
REQUIRED_FILES=(
    "$HOME/.config/tmux/tmux.conf"
    "$HOME/.config/tmux/keybindings.conf"
    "$HOME/.config/tmux/statusbar.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Required file missing: $file"
        exit 1
    fi
done

echo "✓ Main config files present"

# Check if scripts directory exists and has scripts
if [ ! -d "$HOME/.config/tmux/scripts" ]; then
    echo "ERROR: Scripts directory not created"
    exit 1
fi

# Check for key scripts
REQUIRED_SCRIPTS=(
    "$HOME/.config/tmux/scripts/session-switcher.sh"
    "$HOME/.config/tmux/scripts/doctor.sh"
    "$HOME/.config/tmux/scripts/tmux-start.sh"
    "$HOME/.config/tmux/scripts/fzf-git-branch.sh"
    "$HOME/.config/tmux/scripts/git-branch-popup.sh"
    "$HOME/.config/tmux/scripts/fzf-git-commits.sh"
    "$HOME/.config/tmux/scripts/git-commits-popup.sh"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ ! -f "$script" ]; then
        echo "ERROR: Required script missing: $script"
        exit 1
    fi
    if [ ! -x "$script" ]; then
        echo "ERROR: Script not executable: $script"
        exit 1
    fi
done

echo "✓ All required scripts present and executable"

# Check if TPM is installed
if [ ! -d "$HOME/.config/tmux/plugins/tpm" ]; then
    echo "ERROR: TPM not installed"
    exit 1
fi

echo "✓ TPM installed"

# Check if tmux.conf includes the plugins configuration
# Note: Plugins are dynamically added by install.sh
if [ ! -f "$HOME/.config/tmux/tmux.conf" ]; then
    echo "ERROR: tmux.conf not found"
    exit 1
fi

# Verify that tmux.conf sources TPM
if ! grep -q "tpm" "$HOME/.config/tmux/tmux.conf"; then
    echo "ERROR: TPM not configured in tmux.conf"
    exit 1
fi

echo "✓ Plugins configured in tmux.conf"

# Check if fzf is installed
if [ ! -d "$HOME/.fzf" ]; then
    echo "ERROR: fzf not installed"
    exit 1
fi

if [ ! -x "$HOME/.fzf/bin/fzf" ]; then
    echo "ERROR: fzf binary not executable"
    exit 1
fi

echo "✓ fzf installed"

echo ""
echo "All installation tests passed!"
exit 0
