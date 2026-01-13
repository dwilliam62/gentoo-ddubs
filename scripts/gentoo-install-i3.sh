#!/usr/bin/env bash
# Gentoo i3 install helper using package hints from ../gentoo-ddubs

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
DDUBS_ROOT="$(realpath "${SCRIPT_DIR}/../gentoo-ddubs")"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[$1] is required but not found. Exiting." >&2
    exit 1
  fi
}

require_cmd sudo
require_cmd emerge

if ! command -v equery >/dev/null 2>&1; then
  echo "[INFO] Installing app-portage/gentoolkit for equery..."
  sudo emerge -v --ask=n app-portage/gentoolkit
fi
ensure_package_use() {
  echo "[INFO] Ensuring package.use entries (kitty Wayland)"
  local use_file="/etc/portage/package.use/i3-extras"
  sudo mkdir -p /etc/portage/package.use
  sudo tee "$use_file" >/dev/null <<'EOF'
x11-terms/kitty wayland
x11-libs/libxkbcommon wayland
>=media-libs/vulkan-loader-1.4.335.0-r1 X
>=sys-apps/systemd-259 policykit
>=dev-qt/qtdeclarative-6.10.1 opengl
EOF
}
ensure_video_cards() {
  echo "[INFO] Ensuring VIDEO_CARDS includes virgl for virtual GPUs"
  local mc="/etc/portage/make.conf"
  sudo touch "$mc"
  if grep -q '^VIDEO_CARDS=' "$mc"; then
    if ! grep -q 'virgl' "$mc"; then
      sudo sed -i 's/^VIDEO_CARDS=\"\?\(.*\)\"\?$/VIDEO_CARDS=\"\1 virgl\"/' "$mc"
    fi
  else
    echo 'VIDEO_CARDS=\"virgl\"' | sudo tee -a "$mc" >/dev/null
  fi
}

pkg_installed() {
  equery -q list "$1" >/dev/null 2>&1
}

install_pkg() {
  local pkg="$1"
  if pkg_installed "$pkg"; then
    echo "[OK] $pkg already installed"
  else
    echo "[INFO] Installing $pkg ..."
    sudo emerge -v --ask=n "$pkg"
  fi
}

install_list() {
  local label="$1"; shift
  local pkgs=("$@")
  echo "[INFO] Installing ${label} (${#pkgs[@]} items)"
  for pkg in "${pkgs[@]}"; do
    install_pkg "$pkg"
  done
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
  echo "[INFO] Ensuring ly login manager and configuration"
  install_pkg x11-misc/ly

  copy_file "${DDUBS_ROOT}/system/etc/init.d/ly" "/etc/init.d/ly" 755
  copy_file "${DDUBS_ROOT}/system/etc/ly/config.ini" "/etc/ly/config.ini" 644
  copy_file "${DDUBS_ROOT}/system/etc/ly/wsetup.sh" "/etc/ly/wsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/ly/xsetup.sh" "/etc/ly/xsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/pam.d/ly" "/etc/pam.d/ly" 644
  # Force matrix animation and enable big clock
  if [[ -f /etc/ly/config.ini ]]; then
    sudo sed -i -e 's/^animation *=.*/animation = matrix/' \
                -e 's/^bigclock *=.*/bigclock = true/' /etc/ly/config.ini
  fi

  sudo rc-update add ly default || true
  sudo rc-service ly restart || true
}

I3_PACKAGES=(
  x11-wm/i3
  x11-misc/i3status
  x11-misc/i3lock
  x11-misc/dmenu
  x11-misc/picom
  x11-misc/nitrogen
  x11-misc/stalonetray
  x11-misc/sxhkd
  x11-misc/rofi
  x11-misc/wallust
  gui-apps/awww
  gui-apps/swaync
  gui-apps/wl-clipboard
  gui-apps/wlr-randr
  gui-apps/matugen
  app-misc/app2unit
  x11-apps/xinit
  x11-apps/xrandr
  x11-apps/xsetroot
  x11-base/xorg-server
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
  media-video/vlc
  sys-apps/flatpak
  x11-terms/wezterm
  x11-terms/ghostty
  gnome-extra/polkit-gnome
  gnome-extra/nm-applet
  gnome-base/gvfs
  xfce-base/thunar
  x11-misc/qt5ct
  app-misc/nwg-look
  media-video/pipewire
  media-sound/pavucontrol
  media-sound/pamixer
  media-sound/playerctl
  media-video/mpv
  net-misc/networkmanager
  app-misc/fastfetch
  media-libs/mesa
  x11-libs/libdrm
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

echo "[INFO] Starting Gentoo i3 package installation"
ensure_package_use
ensure_video_cards
install_list "i3 stack" "${I3_PACKAGES[@]}"
install_list "Fonts" "${FONTS[@]}"

configure_ly

echo "[DONE] i3 environment packages and ly login manager ready."
