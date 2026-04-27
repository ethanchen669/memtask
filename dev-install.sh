#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# SagTask — Developer installer
#
# Clones the full git repo to ~/.hermes/sag_tasks/sagtask-devop/src/ and
# copies src/sagtask/ to ~/.hermes/plugins/sagtask/ for Hermes to load.
#
# Usage:
#   chmod +x dev-install.sh && ./dev-install.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

OWNER="ethanchen669"
REPO="sagtask"
REPO_DIR="${HOME}/.hermes/sag_tasks/sagtask-devop/src"
PLUGIN_DIR="${HOME}/.hermes/plugins/sagtask"
REPO_URL="git@github.com:${OWNER}/${REPO}.git"

echo "→ SagTask developer installer"
echo ""

# ── Clone / Update git repo ─────────────────────────────────────────────────

if [[ -d "${REPO_DIR}/.git" ]]; then
    echo "→ Pulling latest into ${REPO_DIR}..."
    git -C "$REPO_DIR" pull origin main
    echo "✓ Updated to $(git -C "$REPO_DIR" log -1 --oneline)"
elif [[ -d "$REPO_DIR" ]]; then
    echo "✗ ${REPO_DIR} exists but is not a git repo. Remove it first."
    exit 1
else
    echo "→ Cloning SagTask into ${REPO_DIR}..."
    mkdir -p "$(dirname "$REPO_DIR")"
    git clone "$REPO_URL" "$REPO_DIR"
    echo "✓ Cloned $(git -C "$REPO_DIR" log -1 --oneline)"
fi

# ── Copy plugin to plugins directory ───────────────────────────────────────

echo "→ Copying src/sagtask → ${PLUGIN_DIR}..."
rm -rf "$PLUGIN_DIR"
cp -rf "${REPO_DIR}/sagtask" "$PLUGIN_DIR"

# ── Verify ───────────────────────────────────────────────────────────────────

if [[ ! -f "${PLUGIN_DIR}/__init__.py" ]]; then
    echo "✗ ${PLUGIN_DIR}/__init__.py not found — installation may be corrupt."
    exit 1
fi

if [[ ! -f "${PLUGIN_DIR}/plugin.yaml" ]]; then
    echo "✗ ${PLUGIN_DIR}/plugin.yaml not found."
    exit 1
fi

echo "✓ Plugin files verified"

# ── Check gateway ───────────────────────────────────────────────────────────

if pgrep -f "hermes.*gateway" > /dev/null 2>&1; then
    echo ""
    echo "⚠  Hermes gateway is running. Restart it to load the updated plugin:"
    echo "   hermes gateway restart"
else
    echo "✓ No gateway process detected."
fi

echo ""
echo "✓ Developer install complete."
echo "   Git repo: ${REPO_DIR}"
echo "   Plugin:   ${PLUGIN_DIR}"
echo "   Next: restart Hermes gateway, then type 'task_list' to verify."
echo ""
echo "   After editing code, re-run this script to update the plugin."
