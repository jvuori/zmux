#!/usr/bin/env bash
# ============================================================================
# zmux - command-line facade for the zmux tmux configuration
# ============================================================================
# Installed to: ~/.local/bin/zmux
# Usage:
#   zmux                  Start (or attach to) a tmux session
#   zmux start            Start (or attach to) a tmux session
#   zmux version          Print the installed zmux version
#   zmux update           Check for updates and apply if available
#   zmux doctor           Run the diagnostic helper
#   zmux help             Show this help

set -e

ZMUX_CONFIG_DIR="$HOME/.config/tmux"
ZMUX_VERSION_FILE="$ZMUX_CONFIG_DIR/zmux-version"
ZMUX_SCRIPTS_DIR="$ZMUX_CONFIG_DIR/scripts"
GITHUB_REPO="jvuori/zmux"
# /releases/latest skips pre-releases; use /releases and take the first entry instead
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases"

# ============================================================================
# Helpers
# ============================================================================

installed_version() {
    if [ -f "$ZMUX_VERSION_FILE" ]; then
        cat "$ZMUX_VERSION_FILE" | tr -d '[:space:]'
    else
        echo "unknown"
    fi
}

latest_release_tag() {
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$GITHUB_API" 2>/dev/null \
            | grep '"tag_name"' \
            | head -1 \
            | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$GITHUB_API" 2>/dev/null \
            | grep '"tag_name"' \
            | head -1 \
            | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/'
    else
        echo ""
    fi
}

# Simple semver comparison: returns 0 if $1 < $2
version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -1)" = "$1" ] && [ "$1" != "$2" ]
}

# ============================================================================
# Commands
# ============================================================================

cmd_version() {
    local ver
    ver="$(installed_version)"
    echo "zmux version ${ver}"
}

cmd_start() {
    if [ -x "$ZMUX_SCRIPTS_DIR/tmux-start.sh" ]; then
        exec "$ZMUX_SCRIPTS_DIR/tmux-start.sh" "$@"
    else
        exec tmux "$@"
    fi
}

cmd_doctor() {
    if [ -x "$ZMUX_SCRIPTS_DIR/doctor.sh" ]; then
        exec "$ZMUX_SCRIPTS_DIR/doctor.sh" "$@"
    else
        echo "❌ doctor.sh not found. Is zmux installed?"
        exit 1
    fi
}

cmd_update() {
    echo "🔄 Checking for zmux updates..."

    # Check network tools
    if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
        echo "❌ Neither curl nor wget is available. Please install one of them."
        exit 1
    fi

    local current_ver latest_tag latest_ver
    current_ver="$(installed_version)"
    latest_tag="$(latest_release_tag)"

    if [ -z "$latest_tag" ]; then
        echo "❌ Could not fetch latest release information from GitHub."
        echo "   Check your internet connection or visit:"
        echo "   https://github.com/${GITHUB_REPO}/releases"
        exit 1
    fi

    latest_ver="${latest_tag}"

    echo "   Installed : ${current_ver}"
    echo "   Latest    : ${latest_ver} (tag: ${latest_tag})"

    if [ "$current_ver" = "unknown" ]; then
        echo "⚠️  Could not determine installed version. Proceeding with update."
    elif ! version_lt "$current_ver" "$latest_ver"; then
        echo "✅ Already up to date!"
        return 0
    fi

    echo ""
    echo "⬇️  Downloading zmux ${latest_tag}..."

    local archive_name="zmux-${latest_ver}.tar.gz"
    local download_url="https://github.com/${GITHUB_REPO}/releases/download/${latest_tag}/${archive_name}"
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    # shellcheck disable=SC2064
    trap "rm -rf '$tmp_dir'" EXIT

    local archive_path="${tmp_dir}/${archive_name}"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --progress-bar "$download_url" -o "$archive_path"
    else
        wget -q --show-progress "$download_url" -O "$archive_path"
    fi

    echo "📦 Extracting..."
    tar -xzf "$archive_path" -C "$tmp_dir"

    local extract_dir="${tmp_dir}/zmux-${latest_ver}"
    if [ ! -d "$extract_dir" ]; then
        # Fallback: find whatever directory was extracted
        extract_dir="$(find "$tmp_dir" -maxdepth 1 -type d | grep -v "^${tmp_dir}$" | head -1)"
    fi

    if [ ! -f "${extract_dir}/update.sh" ]; then
        echo "❌ Extracted archive looks incomplete (no update.sh found)."
        exit 1
    fi

    echo "🚀 Running update.sh from ${latest_tag}..."
    bash "${extract_dir}/update.sh" --yes

    echo ""
    echo "✅ zmux updated to ${latest_ver}!"
    # Exit immediately — update.sh has replaced this script on disk.
    # Without exit, bash may try to read the new file's content and hit a parse error.
    exit 0
}

cmd_help() {
    cat <<'EOF'
zmux - Zellij-like tmux configuration

Usage:
  zmux [command] [args...]

Commands:
  (none) / start    Start or attach to a tmux session
  version           Print the installed zmux version
  update            Check for a newer release and update if available
  doctor            Run diagnostic checks on your zmux setup
  help              Show this help message

Examples:
  zmux                  # open/attach tmux session
  zmux version          # show version
  zmux update           # self-update to latest release
  zmux doctor           # diagnose problems

EOF
}

# ============================================================================
# Dispatch
# ============================================================================

COMMAND="${1:-start}"
shift || true

case "$COMMAND" in
    start)        cmd_start "$@"   ;;
    version)      cmd_version      ;;
    update)       cmd_update       ;;
    doctor)       cmd_doctor "$@"  ;;
    help|--help|-h) cmd_help       ;;
    *)
        echo "❌ Unknown command: $COMMAND"
        echo "   Run 'zmux help' for usage."
        exit 1
        ;;
esac
