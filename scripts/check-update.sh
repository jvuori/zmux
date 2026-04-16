#!/usr/bin/env bash
# ============================================================================
# check-update.sh - Background release check for zmux
# ============================================================================
# Called on each tmux client-attached event via hooks in tmux config.
# Handlers must be appended with set-hook -ag so this check is not overwritten.
# Rate-limited to at most one GitHub API call per 24 hours (unless --force).
#
# Usage: check-update.sh [--force]
#   --force: Bypass rate-limiting; always fetch latest version from GitHub
#
# Version file semantics:
#   absent  → installed from a git work tree (no release tag stamped); always
#             show the update notification so the user knows a packaged release
#             is available.  The VERSION file is gitignored and only present in
#             release tarballs, so install.sh removes zmux-version when the
#             source has no VERSION.
#   "0.x.y" → installed from a release tarball; compare against latest tag.
#
# On any failure (no network, API rate-limit, etc.) → exits silently without
# modifying any tmux option, so an existing notification stays visible.

# Parse command-line options
force_check=false
[ "$1" = "--force" ] && force_check=true

ZMUX_CONFIG_DIR="$HOME/.config/tmux"
TIMESTAMP_FILE="$ZMUX_CONFIG_DIR/.update-check-ts"
ZMUX_VERSION_FILE="$ZMUX_CONFIG_DIR/zmux-version"
GITHUB_REPO="jvuori/zmux"
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases"

# Detect install type:
#   dev_install=true  → zmux-version absent (git work tree install)
#   dev_install=false → zmux-version present (release tarball install)
dev_install=false
current_ver=""
if [ -f "$ZMUX_VERSION_FILE" ]; then
    current_ver=$(cat "$ZMUX_VERSION_FILE" 2>/dev/null | tr -d '[:space:]')
    [ -z "$current_ver" ] && dev_install=true   # file exists but empty → treat as dev
else
    dev_install=true
fi

# Rate limit: at most one API call per 24 hours (86400 seconds), unless --force.
now=$(date +%s 2>/dev/null) || exit 0
if [ "$force_check" = false ]; then
    if [ -f "$TIMESTAMP_FILE" ]; then
        last=$(cat "$TIMESTAMP_FILE" 2>/dev/null | tr -d '[:space:]')
        if [ -n "$last" ] && [ "$((now - last))" -lt 86400 ] 2>/dev/null; then
            # Within the 24-hour window.
            if $dev_install; then
                # Dev install: skip the API call if the notification is already set.
                cur=$(tmux display-message -p "#{@update_available}" 2>/dev/null)
                [ -n "$cur" ] && exit 0
                # Notification absent — fall through to fetch so the hint appears
                # immediately after a fresh tmux start; don't reset the timer.
            else
                exit 0
            fi
        fi
    fi
fi

# Record check timestamp before fetching (prevents rapid retries on failure)
printf '%s\n' "$now" > "$TIMESTAMP_FILE" 2>/dev/null || true

# Fetch latest release tag from GitHub (silent on any error)
latest_tag=""
if command -v curl >/dev/null 2>&1; then
    latest_tag=$(curl -fsSL --connect-timeout 8 --max-time 15 \
        "$GITHUB_API" 2>/dev/null \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
elif command -v wget >/dev/null 2>&1; then
    latest_tag=$(wget -qO- --timeout=15 \
        "$GITHUB_API" 2>/dev/null \
        | grep '"tag_name"' | head -1 \
        | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
fi

# Exit silently if the fetch failed or returned unexpected data
[ -z "$latest_tag" ] && exit 0

# Simple semver comparison: returns 0 if $1 < $2 (i.e. update available)
version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

if $dev_install || version_lt "$current_ver" "$latest_tag"; then
    # Dev install or behind latest release → show notification
    tmux set-option -gq @update_available "$latest_tag" 2>/dev/null || true
else
    # Already on latest release → clear any lingering notification
    tmux set-option -gq @update_available "" 2>/dev/null || true
fi
