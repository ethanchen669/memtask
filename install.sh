#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SagTask — One-line installer for Hermes Agent (user mode)
#
# Downloads the pre-built sagtask.tar.gz from GitHub releases and extracts
# it to ~/.hermes/plugins/sagtask/. No git required.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ethanchen669/sagtask/main/install.sh | bash
#
# Or download and run locally:
#   chmod +x install.sh && ./install.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

OWNER="ethanchen669"
REPO="sagtask"
PLUGIN_DIR="${HOME}/.hermes/plugins/sagtask"
TMPDIR=$(mktemp -d)

cleanup() { rm -rf "$TMPDIR"; }
trap cleanup EXIT

echo "→ SagTask installer (user mode)"
echo ""

# ── Detect existing installation ───────────────────────────────────────────

if [[ -d "$PLUGIN_DIR" ]]; then
    # If it has .git, it's either a developer gitfile or an old git clone — not our tarball install
    if [[ -L "$PLUGIN_DIR/.git" ]] || [[ -d "$PLUGIN_DIR/.git" ]]; then
        echo "✗ ${PLUGIN_DIR} appears to be a git installation (gitfile or clone)."
        echo "  For updates, use:  cd ${PLUGIN_DIR} && git pull"
        echo "  To switch to release mode: rm -rf ${PLUGIN_DIR} && $0"
        exit 1
    fi
    echo "⚠  ${PLUGIN_DIR} already exists. Overwriting with latest release..."
    rm -rf "$PLUGIN_DIR"
fi

# ── Fetch latest release ─────────────────────────────────────────────────────

echo "→ Fetching latest SagTask release..."

RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest")
TARBALL_URL=$(echo "$RELEASE_JSON" | grep -o '"tarball_url": "[^"]*"' | cut -d'"' -f4)

if [[ -z "$TARBALL_URL" ]]; then
    echo "✗ Could not find latest release. Is there a release published?"
    exit 1
fi

VERSION=$(echo "$RELEASE_JSON" | grep -o '"tag_name": "[^"]*"' | cut -d'"' -f4)
echo "  Release: ${VERSION}"

# ── Download & extract ───────────────────────────────────────────────────────

echo "→ Downloading ${TARBALL_URL}..."
cd "$TMPDIR"
curl -fsSL "$TARBALL_URL" -o sagtask.tar.gz

echo "→ Extracting to ${PLUGIN_DIR}..."
mkdir -p "$(dirname "$PLUGIN_DIR")"
# The tarball extracts to a temp dir with the repo name as root — find and move it
tar -xzf sagtask.tar.gz
TEMP_EXTRACT=$(find "$TMPDIR" -mindepth 1 -maxdepth 1 -type d)
mv "$TEMP_EXTRACT/sagtask" "$PLUGIN_DIR"

# ── Verify ───────────────────────────────────────────────────────────────────

if [[ ! -f "${PLUGIN_DIR}/__init__.py" ]]; then
    echo "✗ ${PLUGIN_DIR}/__init__.py not found — installation may be corrupt."
    exit 1
fi

if [[ ! -f "${PLUGIN_DIR}/plugin.yaml" ]]; then
    echo "✗ ${PLUGIN_DIR}/plugin.yaml not found — this may not be a SagTask release."
    exit 1
fi

echo "✓ Plugin files verified"

# ── Check gateway ───────────────────────────────────────────────────────────

if pgrep -f "hermes.*gateway" > /dev/null 2>&1; then
    echo ""
    echo "⚠  Hermes gateway is running. Restart it to load the plugin:"
    echo ""
    echo "   hermes gateway restart"
else
    echo "✓ No gateway process detected."
fi

echo ""
echo "✓ SagTask ${VERSION} installed successfully!"
echo "   Next: restart Hermes gateway, then type 'task_list' to verify."
