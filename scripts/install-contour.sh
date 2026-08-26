#!/usr/bin/env bash
# ==============================================================================
# Script: install-contour-gentoo.sh
# Description: Installs gui-apps/contour on Gentoo Linux with all necessary
#              overlay configurations, dependency masks, and USE flags.
# ==============================================================================

set -euo pipefail

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo "[!] This script must be run as root (or with sudo)." >&2
    exit 1
fi

echo "[*] Step 1: Ensuring eselect-repository is installed..."
if ! command -v eselect-repository &>/dev/null; then
    emerge --noreplace app-eselect/eselect-repository
fi

echo "[*] Step 2: Enabling and syncing the 'guru' overlay..."
eselect repository enable guru || true
emaint sync -r guru

echo "[*] Step 3: Configuring package.accept_keywords for Contour and GURU dependencies..."
mkdir -p /etc/portage/package.accept_keywords
cat << 'EOF' > /etc/portage/package.accept_keywords/contour
gui-apps/contour ~amd64
media-libs/libunicode ~amd64
dev-cpp/boxed-cpp ~amd64
dev-cpp/reflection-cpp ~amd64
EOF

echo "[*] Step 4: Masking libunicode >= 0.8.0 (fixes Contour 0.6.1 'breakable' build error)..."
mkdir -p /etc/portage/package.mask
cat << 'EOF' > /etc/portage/package.mask/libunicode
# Contour 0.6.1 is incompatible with libunicode-0.8.0+ due to grapheme_segmenter API change
>=media-libs/libunicode-0.8.0
EOF

echo "[*] Step 5: Enabling 'qml' USE flag on dev-qt/qtmultimedia (fixes Contour runtime crash)..."
mkdir -p /etc/portage/package.use
cat << 'EOF' > /etc/portage/package.use/qtmultimedia
# Required by Contour QML UI (Terminal.qml)
dev-qt/qtmultimedia qml
EOF

echo "[*] Step 6: Updating dev-qt/qtmultimedia with new USE flag..."
emerge --changed-use --noreplace dev-qt/qtmultimedia

echo "[*] Step 7: Emerging gui-apps/contour..."
emerge -av gui-apps/contour

echo "[+] Installation complete! You can now launch Contour with: contour"

