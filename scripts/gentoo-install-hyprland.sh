#!/usr/bin/env bash
# Gentoo Hyprland install helper using package hints from ../gentoo-ddubs

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

# Ensure equery is available for package checks
if ! command -v equery >/dev/null 2>&1; then
  echo "[INFO] Installing app-portage/gentoolkit for equery..."
  sudo emerge -v --ask=n app-portage/gentoolkit
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
>=x11-libs/cairo-1.18.4 X svg
>=dev-cpp/cairomm-1.14.5:0 X
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
>=x11-libs/cairo-1.18.4-r1 -X
# swaync (GTK4) requirements
>=gui-libs/gtk-4.20.3-r2 wayland
>=gui-libs/gtk4-layer-shell-1.1.1-r1 vala introspection
# kitty Wayland build
x11-terms/kitty wayland
# mpv/vlc dependency
>=media-libs/vulkan-loader-1.4.335.0-r1 X
EOF
}
ensure_unmask_hypr_qtutils() {
  echo "[INFO] Unmasking gui-libs/hyprland-qtutils (temporarily masked upstream)"
  local unmask_file="/etc/portage/package.unmask/hyprland-qtutils"
  sudo mkdir -p /etc/portage/package.unmask
  sudo tee "$unmask_file" >/dev/null <<'EOF'
gui-libs/hyprland-qtutils
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
    echo 'VIDEO_CARDS="virgl"' | sudo tee -a "$mc" >/dev/null
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
  local label="$1"
  shift
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
  install_pkg app-misc/cmatrix

  copy_file "${DDUBS_ROOT}/system/etc/init.d/ly" "/etc/init.d/ly" 755
  copy_file "${DDUBS_ROOT}/system/etc/ly/config.ini" "/etc/ly/config.ini" 644
  copy_file "${DDUBS_ROOT}/system/etc/ly/wsetup.sh" "/etc/ly/wsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/ly/xsetup.sh" "/etc/ly/xsetup.sh" 755
  copy_file "${DDUBS_ROOT}/system/etc/pam.d/ly" "/etc/pam.d/ly" 644

  # Also ship hyprlock PAM config from the repo, if present
  copy_file "${DDUBS_ROOT}/system/etc/pam.d/hyprlock" "/etc/pam.d/hyprlock" 644

  # Force matrix animation and enable big clock
  if [[ -f /etc/ly/config.ini ]]; then
    sudo sed -i -e 's/^animation *=.*/animation = matrix/' \
      -e 's/^bigclock *=.*/bigclock = true/' /etc/ly/config.ini
  fi

  sudo rc-update add ly default || true
  sudo rc-service ly restart || true
}

configure_gtk_dark_theme() {
  echo "[INFO] Setting GTK to prefer dark theme for current user"
  mkdir -p "${HOME}/.config/gtk-3.0" "${HOME}/.config/gtk-4.0"
  cat > "${HOME}/.config/gtk-3.0/settings.ini" << 'EOF'
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
  gui-apps/nwg-look
  gui-apps/wlr-randr
  gui-apps/wl-clipboard
  gui-apps/matugen
  app-misc/app2unit
  app-misc/ranger
  gui-libs/hyprland-qtutils
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
  media-video/vlc
  sys-apps/flatpak
  media-libs/mesa
  x11-libs/libdrm
  media-video/pipewire
  media-video/pipewire-pulse
  media-video/wireplumber
  media-libs/alsa-lib
  media-sound/alsa-utils
  media-sound/pavucontrol
  media-sound/pamixer
  media-sound/playerctl
  media-sound/pwvucontrol
  media-libs/libcanberra
  sys-auth/rtkit
  net-wireless/bluez
  net-wireless/bluez-utils
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
    -h|--help)
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
ensure_unmask_hypr_qtutils
ensure_video_cards
ensure_gentoo_rsync_repo
install_list "Hyprland stack" "${HYPR_PACKAGES[@]}"
install_list "Fonts" "${FONTS[@]}"

configure_ly
configure_gtk_dark_theme

echo "[DONE] Hyprland environment packages and ly login manager ready."
