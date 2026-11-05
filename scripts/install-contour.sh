#!/usr/bin/env bash
# ==============================================================================
# Script: install-contour.sh
# Description: Installs gui-apps/contour on Gentoo Linux with all necessary
#              overlay configurations, dependency masks, and USE flags.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

need_root "$@"

step "Step 1: Ensuring eselect-repository is installed..."
# eselect-repository is an eselect module, not a standalone binary, so probe the
# module through eselect itself instead of looking for a command of that name.
if ! have eselect || ! eselect repository list >/dev/null 2>&1; then
  emerge --noreplace app-eselect/eselect-repository ||
    die "Failed to install app-eselect/eselect-repository."
fi

step "Step 2: Enabling and syncing the 'guru' overlay..."
eselect repository enable guru ||
  log_warn "Could not enable the guru overlay; it may already be configured."
if have emaint; then
  emaint sync -r guru || log_warn "Syncing guru failed; continuing with existing metadata."
else
  log_warn "emaint not found; skipping guru sync."
fi

step "Step 3: Configuring package.accept_keywords for Contour and GURU dependencies..."
mkdir -p /etc/portage/package.accept_keywords
cat << 'EOF' > /etc/portage/package.accept_keywords/contour
gui-apps/contour ~amd64
media-libs/libunicode ~amd64
dev-cpp/boxed-cpp ~amd64
dev-cpp/reflection-cpp ~amd64
EOF

step "Step 4: Masking libunicode >= 0.8.0 (fixes Contour 0.6.1 'breakable' build error)..."
mask_dir="/etc/portage/package.mask"
mkdir -p "$mask_dir"
cat << 'EOF' > "${mask_dir}/libunicode"
# Contour 0.6.1 is incompatible with libunicode-0.8.0+ due to grapheme_segmenter API change
>=media-libs/libunicode-0.8.0
EOF

step "Step 5: Configuring USE flags for Qt and Contour dependencies..."
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

step "Step 6: Updating Qt dependencies with new USE flags..."
emerge --changed-use --noreplace dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qtquick3d dev-qt/qt5compat ||
  die "Failed to rebuild the Qt dependencies with the new USE flags."

step "Step 7: Emerging gui-apps/contour..."
if [ -t 0 ]; then
  emerge -av gui-apps/contour || die "gui-apps/contour failed to build."
else
  emerge -v gui-apps/contour || die "gui-apps/contour failed to build."
fi

log_ok "Installation complete! You can now launch Contour with: contour"
