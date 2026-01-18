#!/usr/bin/env bash
# Gentoo Hyprland install helper using package hints from ../gentoo-ddubs

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# Repo root (one level above scripts/)
DDUBS_ROOT="$(realpath "${SCRIPT_DIR}/..")"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[$1] is required but not found. Exiting." >&2
    exit 1
  fi
}

require_cmd sudo
require_cmd emerge

# Ensure equery is available for package checks
if ! command -v equery >/dev/null 2>&1; then
  echo "[INFO] Installing app-portage/gentoolkit for equery..."
  sudo emerge -v --ask=n app-portage/gentoolkit
fi

# Ensure qlist (portage-utils) is available for fast installed-package checks
if ! command -v qlist >/dev/null 2>&1; then
  echo "[INFO] Installing app-portage/portage-utils for qlist..."
  sudo emerge -v --ask=n app-portage/portage-utils
fi

ensure_use_flags() {
  echo "[INFO] Ensuring required USE flags for qtbase, libxkbcommon, gtkmm, gtk+, cairo/mesa"
  local use_file="/etc/portage/package.use/hyprland-qt"
  sudo mkdir -p /etc/portage/package.use
  sudo tee "$use_file" >/dev/null <<'EOF'
>=dev-qt/qtbase-6.10.1 wayland opengl icu
dev-qt/qtwayland wayland opengl
>=dev-qt/qtdeclarative-6.10.1 opengl
 x11-libs/libxkbcommon X wayland
>=sys-apps/systemd-259 policykit
dev-cpp/gtkmm:3.0 wayland X
# Waybar GTK/mesa stack (enable both X and Wayland to satisfy slot resolver)
>=x11-libs/gtk+-3.24.51 wayland X
>=media-libs/mesa-25.3.3 wayland
# cairo / cairomm for GTK/Waybar
# Align with Portage suggestion to resolve slot collision:
#   - x11-libs/cairo-1.18.4-r1 (Change USE: +X +aqua)
#   - dev-cpp/cairomm-1.18.0 (Change USE: +X)
>=x11-libs/cairo-1.18.4-r1 X aqua svg
>=dev-cpp/cairomm-1.18.0 X
# Thunar requires libxfce4ui with either wayland or X
>=xfce-base/libxfce4ui-4.20.2 wayland
# XFCE stack for Thunar + panel on Wayland
>=xfce-base/libxfce4windowing-4.20.5 wayland
>=xfce-base/xfce4-panel-4.20.6 wayland dbusmenu
>=xfce-base/exo-4.20.0 wayland
>=xfce-base/thunar-4.20.6 wayland
>=xfce-base/tumbler-4.20.1 wayland
# Panel deps
>=app-crypt/gcr-3.41.2 wayland
dev-libs/libdbusmenu gtk3
# PipeWire audio stack
media-video/pipewire pulseaudio
media-libs/libcanberra alsa pulseaudio
>=media-libs/libpulse-17.0 X
# swaync (GTK4) requirements
>=gui-libs/gtk-4.20.3-r2 wayland
>=gui-libs/gtk4-layer-shell-1.1.1-r1 vala introspection
# legacy GTK3 layer-shell helper
gui-libs/gtk-layer-shell introspection
# kitty Wayland build
x11-terms/kitty wayland
# mpv/vlc dependency
>=media-libs/vulkan-loader-1.4.335.0-r1 X
EOF
}
# ensure_unmask_hypr_qtutils() {
#   echo "[INFO] Unmasking gui-libs/hyprland-qtutils (temporarily masked upstream)"
#   local unmask_file="/etc/portage/package.unmask/hyprland-qtutils"
#   sudo mkdir -p /etc/portage/package.unmask
#   sudo tee "$unmask_file" >/dev/null <<'EOF'
# gui-libs/hyprland-qtutils
# EOF
# }
ensure_video_cards() {
  echo "[INFO] Ensuring VIDEO_CARDS includes virgl and detecting hardware..."
  local mc="/etc/portage/make.conf"
  sudo touch "$mc"

  # Default to virgl for your current VM setup
  local cards="virgl"

  # Detection logic for future HW moves
  if lspci | grep -qi "nvidia"; then
    cards="$cards nvidia"
  elif lspci | grep -qi "amd"; then
    cards="$cards amdgpu radeonsi"
  elif lspci | grep -qi "intel"; then
    cards="$cards intel i915"
  fi

  # Update make.conf if the line exists, otherwise append
  if grep -q '^VIDEO_CARDS=' "$mc"; then
    # This replaces the line entirely with our detected list
    sudo sed -i "s/^VIDEO_CARDS=.*/VIDEO_CARDS=\"$cards\"/" "$mc"
  else
    echo "VIDEO_CARDS=\"$cards\"" | sudo tee -a "$mc" >/dev/null
  fi
}

pkg_installed() {
  # Use qlist -I (from app-portage/portage-utils) for fast membership checks
  # Expects a full category/atom like gui-wm/hyprland.
  qlist -I "$1" >/dev/null 2>&1
}

# Generic helper: install a package only if it is not already installed.
# Uses the same pkg_installed() check as install_pkg, but keeps the call-site
# simple and avoids re-emerging things on script re-runs when they are
# already present.
install_if_missing() {
  local pkg="$1"
  if pkg_installed "$pkg"; then
    echo "[OK] $pkg is already installed, skipping."
    return 0
  fi

  echo "[INFO] Installing $pkg (first-time or previously failed build)..."
  install_pkg "$pkg"
}

prebuild_problematic_binaries() {
  local problematic=(
    "sci-libs/fftw"
    "sci-libs/openblas"
    "sci-libs/flexiblas"
  )

  echo "[INFO] Pre-building problematic math libraries from source to avoid Python async bugs..."
  for pkg in "${problematic[@]}"; do
    if ! qlist -I "$pkg" >/dev/null 2>&1; then
      echo "[INFO] Forcing source build for $pkg..."
      # --usepkg=n is the magic flag that ignores the buggy binaries
      sudo emerge -v --ask=n --usepkg=n "$pkg"
    else
      echo "[INFO] $pkg is already installed, skipping."
    fi
  done
}

install_pkg() {
  local pkg="$1"

  echo "[INFO] Installing $pkg ..."

  # First attempt: auto-fix typical config/USE issues and respect binpkg USE
  if sudo emerge --ask=n --autounmask-write --autounmask-continue --binpkg-respect-use=y "$pkg"; then
    echo "[SUCCESS] $pkg installed."
    return 0
  fi

  # If that failed, try to auto-apply pending config updates, then retry once
  echo "[RETRY] Applying Portage config changes and retrying $pkg..."
  if command -v etc-update >/dev/null 2>&1; then
    echo -e "-5\ny" | sudo etc-update >/dev/null || true
  else
    echo "[WARN] etc-update not found; skipping automatic config merge."
  fi

  sudo emerge --ask=n --oneshot "$pkg"
}

install_list() {
  local label="$1"
  shift
  local pkgs=("$@")
  echo "[INFO] Installing ${label} (${#pkgs[@]} items)"
  for pkg in "${pkgs[@]}"; do
    install_if_missing "$pkg"
  done
}

# Build and install hyprland-qtutils from source if not already present.
# This is needed because gui-libs/hyprland-qtutils is not yet available in
# the main Gentoo tree. We clone upstream, build with CMake, and install.
# On success, the temporary build directory is removed.
build_hyprland_qtutils() {
  echo "[INFO] Ensuring hyprland-qtutils is installed from source"

  if command -v hyprland-qtutils >/dev/null 2>&1; then
    echo "[OK] hyprland-qtutils already present in PATH, skipping source build."
    return 0
  fi

  require_cmd git
  require_cmd cmake

  local workdir
  workdir=$(mktemp -d -t hyprland-qtutils-XXXXXX) || {
    echo "[ERROR] Failed to create temporary directory for hyprland-qtutils build" >&2
    return 1
  }

  echo "[INFO] Using temporary build directory: $workdir"

  if ! (
    set -e
    cd "$workdir"
    echo "[INFO] Cloning hyprwm/hyprland-qtutils..."
    git clone https://github.com/hyprwm/hyprland-qtutils.git .
    echo "[INFO] Configuring hyprland-qtutils (CMake Release build)..."
    cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
    echo "[INFO] Building hyprland-qtutils..."
    cmake --build build --config Release --target all
    echo "[INFO] Installing hyprland-qtutils (sudo cmake --install build)..."
    sudo cmake --install build
  ); then
    echo "[ERROR] hyprland-qtutils build or install failed; leaving sources in $workdir for inspection." >&2
    return 1
  fi

  # Verify installation and clean up
  if command -v hyprland-qtutils >/dev/null 2>&1; then
    echo "[SUCCESS] hyprland-qtutils installed successfully. Cleaning up $workdir"
    rm -rf "$workdir" || echo "[WARN] Failed to remove temporary directory $workdir" >&2
  else
    echo "[WARN] hyprland-qtutils build finished but binary not found in PATH; keeping $workdir for debugging." >&2
  fi
}

copy_file() {
  local src="$1" dst="$2" mode="$3"
  if [[ -f "$src" ]]; then
    sudo install -Dm"$mode" "$src" "$dst"
    echo "[OK] Deployed $(basename "$src") -> $dst"
  else
    echo "[WARN] Missing source $src (skipped)"
  fi
}

configure_ly() {
  echo "[INFO] Ensuring ly login manager and configuration (systemd)"
  install_if_missing x11-misc/ly
  install_if_missing app-misc/cmatrix

  # Deploy config files from your ddubs repo
  copy_file "${DDUBS_ROOT}/system/etc/ly/config.ini" "/etc/ly/config.ini" 644
  copy_file "${DDUBS_ROOT}/system/etc/ly/wsetup.sh" "/etc/ly/wsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/ly/xsetup.sh" "/etc/ly/xsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/pam.d/ly" "/etc/pam.d/ly" 644
  copy_file "${DDUBS_ROOT}/system/etc/pam.d/hyprlock" "/etc/pam.d/hyprlock" 644

  # Force matrix animation and enable big clock
  if [[ -f /etc/ly/config.ini ]]; then
    sudo sed -i -e 's/^animation *=.*/animation = matrix/' \
      -e 's/^bigclock *=.*/bigclock = true/' /etc/ly/config.ini
  fi

  # Enable the service via systemd
  echo "[INFO] Enabling ly.service via systemd"
  sudo systemctl enable ly.service
}

configure_gtk_dark_theme() {
  echo "[INFO] Setting GTK to prefer dark theme for current user"
  mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
  cat >"${HOME}/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
EOF
  cp "${HOME}/.config/gtk-3.0/settings.ini" "${HOME}/.config/gtk-4.0/settings.ini"
}

ensure_gentoo_rsync_repo() {
  echo "[INFO] Configuring Gentoo main repo to use rsync"
  local repo_conf_dir="/etc/portage/repos.conf"
  local gentoo_conf="${repo_conf_dir}/gentoo.conf"

  sudo mkdir -p "${repo_conf_dir}"
  sudo tee "${gentoo_conf}" >/dev/null <<'EOF'
[gentoo]
location = /var/db/repos/gentoo
sync-type = rsync
sync-uri = rsync://rsync.gentoo.org/gentoo-portage
auto-sync = yes
EOF

  if [ -d /var/db/repos/gentoo ]; then
    echo "[INFO] Removing any git metadata from /var/db/repos/gentoo for rsync"
    sudo find /var/db/repos/gentoo -maxdepth 1 -name '.git*' -exec rm -rf {} +
  fi
}

HYPR_PACKAGES=(
  gui-wm/hyprland
  gui-apps/hypridle
  gui-apps/hyprlock
  gui-apps/hyprpaper
  gui-apps/hyprshot
  gui-libs/hyprcursor
  gui-libs/xdg-desktop-portal-hyprland
  gui-libs/hyprland-qt-support
  gui-apps/waybar
  gui-apps/wlogout
  gui-apps/wofi
  gui-apps/swaync
  media-sound/cava
  gui-apps/awww
  gui-apps/waypaper
  gui-apps/grim
  gui-apps/slurp
  gui-apps/swappy
  gui-apps/clipman
  gui-apps/nwg-displays
  gui-apps/quickshell
  gui-apps/nwg-drawer
  app-misc/nwg-look
  gui-apps/wlr-randr
  gui-apps/wl-clipboard
  x11-misc/matugen
  # app-misc/app2unit   # need find source for this
  app-misc/ranger
  #gui-libs/hyprland-qtutils
  xfce-base/thunar
  xfce-base/tumbler
  xfce-base/xfce4-panel
  xfce-base/libxfce4windowing
  xfce-base/libxfce4ui
  xfce-base/exo
  dev-libs/libdbusmenu
  app-crypt/gcr
  x11-misc/wallust
  x11-misc/xdg-user-dirs
  x11-terms/kitty
  app-misc/tmux
  app-misc/yazi
  dev-lang/python
  sys-apps/bat
  sys-fs/ncdu
  app-shells/zoxide
  app-shells/starship
  sys-apps/eza
  dev-libs/newt
  #  media-video/vlc  # Causes build failures not essential
  sys-apps/flatpak
  media-libs/mesa
  x11-libs/libdrm
  media-video/pipewire
  #media-video/pipewire-pulse  # not valid package?
  media-video/wireplumber
  media-libs/alsa-lib
  media-sound/alsa-utils
  media-sound/pavucontrol
  # media-sound/pamixer
  #   2026-01-18: Temporarily disabled.
  #   Fails to build (ICU / C++14 mismatch in /usr/include/unicode/unistr.h; needs ebuild/overlay fix).
  media-sound/playerctl
  media-sound/pavucontrol
  media-libs/libcanberra
  sys-auth/rtkit
  net-wireless/bluez
  net-wireless/bluez-tools
  media-video/mpv
  net-misc/networkmanager
  app-misc/fastfetch
  app-misc/nwg-look
)

FONTS=(
  media-fonts/cardo
  media-fonts/cascadia-code
  media-fonts/dejavu
  media-fonts/fira-code
  media-fonts/fontawesome
  media-fonts/hack
  media-fonts/jetbrains-mono
  media-fonts/nerdfonts
  media-fonts/droid
  media-fonts/victor-mono
  media-fonts/fantasque-sans-mono
  media-fonts/noto
  media-fonts/noto-emoji
  media-fonts/source-code-pro
  media-fonts/symbols-nerd-font
  media-fonts/urw-fonts
)

SET_DARK_ONLY=0

while [[ $# -gt 0 ]]; do
  case "$1" in
  --set-dark)
    SET_DARK_ONLY=1
    shift
    ;;
  -h | --help)
    echo "Usage: $0 [--set-dark]"
    echo "  --set-dark   Only configure GTK dark theme for current user and exit."
    exit 0
    ;;
  *)
    echo "Unknown option: $1" >&2
    exit 1
    ;;
  esac
done

if [[ "$SET_DARK_ONLY" -eq 1 ]]; then
  configure_gtk_dark_theme
  echo "[DONE] GTK dark theme configured."
  exit 0
fi

echo "[INFO] Starting Gentoo Hyprland package installation"
ensure_use_flags
# ensure_unmask_hypr_qtutils  # disabled until gui-libs/hyprland-qtutils lands in main Gentoo repo
ensure_video_cards
ensure_gentoo_rsync_repo
prebuild_problematic_binaries
install_list "Hyprland stack" "${HYPR_PACKAGES[@]}"

# Build hyprland-qtutils from source if needed (not in main Gentoo repo yet)
build_hyprland_qtutils || echo "[WARN] hyprland-qtutils build failed; continuing without it."

install_list "Fonts" "${FONTS[@]}"

configure_ly
configure_gtk_dark_theme

echo "[DONE] Hyprland environment packages and ly login manager ready."
