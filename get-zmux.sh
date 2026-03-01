#!/usr/bin/env bash
# ============================================================================
# get-zmux.sh - Bootstrap installer for zmux
# ============================================================================
# Run with:
#   curl -fsSL https://raw.githubusercontent.com/jvuori/zmux/master/get-zmux.sh | bash
# Or with options:
#   curl -fsSL https://raw.githubusercontent.com/jvuori/zmux/master/get-zmux.sh | bash -s -- --yes
#
# Options:
#   --yes / -y   Non-interactive install (accept all defaults)
#   --version    Install a specific version, e.g. --version 0.1.0
#                (defaults to the latest GitHub release)

set -e

GITHUB_REPO="jvuori/zmux"
# /releases/latest skips pre-releases; use /releases and take the first entry instead
GITHUB_API="https://api.github.com/repos/${GITHUB_REPO}/releases"
YES=false
REQUESTED_VERSION=""

# ============================================================================
# Parse arguments
# ============================================================================

while [ $# -gt 0 ]; do
    case "$1" in
        --yes|-y)    YES=true        ;;
        --version)   REQUESTED_VERSION="$2"; shift ;;
        --version=*) REQUESTED_VERSION="${1#*=}" ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--yes] [--version <tag>]"
            exit 1
            ;;
    esac
    shift
done

# ============================================================================
# Helpers
# ============================================================================

info()    { echo "  $*"; }
success() { echo "✅ $*"; }
warn()    { echo "⚠️  $*"; }
error()   { echo "❌ $*" >&2; exit 1; }

need_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        error "Required command not found: $1  Please install it and retry."
    fi
}

download() {
    local url="$1" dest="$2"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL --progress-bar "$url" -o "$dest"
    elif command -v wget >/dev/null 2>&1; then
        wget -q --show-progress "$url" -O "$dest"
    else
        error "Neither curl nor wget found. Please install one and retry."
    fi
}

fetch_text() {
    local url="$1"
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$url"
    fi
}

# ============================================================================
# Determine version to install
# ============================================================================

echo ""
echo "════════════════════════════════════════════════"
echo "  zmux installer"
echo "════════════════════════════════════════════════"
echo ""

if [ -n "$REQUESTED_VERSION" ]; then
    # Version is already plain semver; no stripping needed
    RELEASE_TAG="${REQUESTED_VERSION}"
    info "Requested version: ${RELEASE_TAG}"
else
    info "Fetching latest release information..."
    API_RESPONSE="$(fetch_text "$GITHUB_API" 2>/dev/null || true)"
    if [ -z "$API_RESPONSE" ]; then
        error "Could not reach GitHub API. Check your internet connection."
    fi
    RELEASE_TAG="$(echo "$API_RESPONSE" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')"
    if [ -z "$RELEASE_TAG" ]; then
        error "Could not determine latest release tag. Visit https://github.com/${GITHUB_REPO}/releases"
    fi
    info "Latest release: ${RELEASE_TAG}"
fi

RELEASE_VERSION="${RELEASE_TAG}"
ARCHIVE_NAME="zmux-${RELEASE_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/${GITHUB_REPO}/releases/download/${RELEASE_TAG}/${ARCHIVE_NAME}"
CHECKSUM_URL="${DOWNLOAD_URL}.sha256"

# ============================================================================
# Check prerequisites
# ============================================================================

need_cmd tar
need_cmd bash

# ============================================================================
# Download
# ============================================================================

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE_NAME}"

echo ""
info "Downloading ${ARCHIVE_NAME}..."
download "$DOWNLOAD_URL" "$ARCHIVE_PATH"

# Verify checksum if sha256sum is available
if command -v sha256sum >/dev/null 2>&1; then
    CHECKSUM_FILE="${TMP_DIR}/${ARCHIVE_NAME}.sha256"
    if fetch_text "$CHECKSUM_URL" > "$CHECKSUM_FILE" 2>/dev/null && [ -s "$CHECKSUM_FILE" ]; then
        info "Verifying checksum..."
        # sha256sum file has the archive name as the second field - fix path so it resolves
        EXPECTED="$(awk '{print $1}' "$CHECKSUM_FILE")"
        ACTUAL="$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')"
        if [ "$EXPECTED" = "$ACTUAL" ]; then
            success "Checksum verified"
        else
            error "Checksum mismatch! Download may be corrupted. Please try again."
        fi
    else
        warn "Could not fetch checksum file, skipping verification."
    fi
fi

# ============================================================================
# Extract
# ============================================================================

info "Extracting..."
tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

EXTRACT_DIR="${TMP_DIR}/zmux-${RELEASE_VERSION}"
if [ ! -d "$EXTRACT_DIR" ]; then
    # Fallback: find the single extracted directory
    EXTRACT_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d | grep -v "^${TMP_DIR}$" | head -1)"
fi

if [ ! -f "${EXTRACT_DIR}/install.sh" ]; then
    error "Extracted archive looks incomplete (install.sh not found)."
fi

# ============================================================================
# Run installer
# ============================================================================

echo ""
info "Running installer from zmux ${RELEASE_TAG}..."
echo ""

INSTALL_ARGS=()
if [ "$YES" = "true" ]; then
    INSTALL_ARGS+=("--yes")
fi

bash "${EXTRACT_DIR}/install.sh" "${INSTALL_ARGS[@]}"
