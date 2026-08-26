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

echo "[*] Step 5: Configuring USE flags for Qt and Contour dependencies..."
mkdir -p /etc/portage/package.use
cat << 'EOF' > /etc/portage/package.use/contour
# Required by Contour QML UI (Terminal.qml) and Qt6 Wayland/OpenGL/Vulkan stack
dev-qt/qtbase opengl vulkan
dev-qt/qtdeclarative opengl vulkan
dev-qt/qtmultimedia qml opengl vulkan
dev-qt/qtquick3d opengl vulkan
dev-qt/qt5compat qml
sys-libs/zlib minizip
EOF

echo "[*] Step 6: Updating Qt dependencies with new USE flags..."
emerge --changed-use --noreplace dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qtquick3d dev-qt/qt5compat

echo "[*] Step 7: Emerging gui-apps/contour..."
if [[ -t 0 ]]; then
    emerge -av gui-apps/contour
else
    emerge -v gui-apps/contour
fi

echo "[+] Installation complete! You can now launch Contour with: contour"

