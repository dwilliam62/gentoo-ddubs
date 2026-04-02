#!/usr/bin/env bash
# Gentoo Hyprland install helper using package hints from ../gentoo-ddubs
# Also now installs OxWM

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"
# Repo root (one level above scripts/)
DDUBS_ROOT="$(realpath "${SCRIPT_DIR}/..")"
OXWM_REPO_URL="https://github.com/tonybanters/oxwm"
OXWM_DIR="/opt/oxwm"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[$1] is required but not found. Exiting." >&2
    exit 1
  fi
}
ensure_nix_with_flakes() {
  local nix_conf="/etc/nix/nix.conf"
  local nix_features="extra-experimental-features = nix-command flakes"

  if ! command -v nix >/dev/null 2>&1; then
    echo "[INFO] Installing Nix (daemon) ..."
    local url="${NIX_INSTALL_URL:-https://nixos.org/nix/install}"
    local flags="${NIX_INSTALL_FLAGS:---daemon --yes}"
    if curl -fsSL "$url" | sudo sh -s -- $flags; then
      echo "[INFO] Nix installed. Enabling flakes..."
      sudo mkdir -p /etc/nix
      if ! sudo grep -q "^extra-experimental-features" "$nix_conf" 2>/dev/null; then
        echo "$nix_features" | sudo tee -a "$nix_conf" >/dev/null
      fi
      echo "[WARN] Nix requires a new shell. Please restart your shell and re-run this script."
      exit 0
    else
      echo "[ERROR] Nix install failed."
      exit 1
    fi
  fi

  # Ensure flakes enabled if nix already installed
  sudo mkdir -p /etc/nix
  if ! sudo grep -q "^extra-experimental-features" "$nix_conf" 2>/dev/null; then
    echo "$nix_features" | sudo tee -a "$nix_conf" >/dev/null
  fi
}
ensure_hyproverlay_repo() {
  echo "[INFO] Ensuring hyproverlay repository is enabled"

  if ! command -v eselect >/dev/null 2>&1; then
    echo "[WARN] eselect not found; cannot manage overlays automatically."
    return 0
  fi

  if ! eselect repository list >/dev/null 2>&1; then
    echo "[INFO] Installing app-eselect/eselect-repository..."
    sudo emerge -v --ask=n app-eselect/eselect-repository
  fi

  if eselect repository list 2>/dev/null | awk '/\*/ {print $2}' | grep -qx "hyproverlay"; then
    echo "[OK] hyproverlay is already enabled."
    return 0
  fi

  if eselect repository list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "hyproverlay"; then
    echo "[INFO] Enabling existing hyproverlay entry..."
    sudo eselect repository enable hyproverlay
  else
    echo "[INFO] Adding and enabling hyproverlay..."
    sudo eselect repository enable hyproverlay
  fi
}

require_cmd sudo
require_cmd emerge
require_cmd curl
ensure_nix_with_flakes

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
#   - dev-cpp/cairomm-1.14.5 (Change USE: +X)
>=x11-libs/cairo-1.18.4-r1 X aqua svg
dev-cpp/cairomm X
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
media-video/pipewire pulseaudio sound-server extra alsa-pipewire
media-libs/libcanberra alsa pulseaudio
>=media-libs/libpulse-17.0 X glib
# gdk-pixbuf JPEG loaders (for rofi/thumbnailing)
x11-libs/gdk-pixbuf jpeg
xfce-base/tumbler jpeg
# swaync (GTK4) requirements
>=gui-libs/gtk-4.20.3-r2 wayland
>=gui-libs/gtk4-layer-shell-1.1.1-r1 vala introspection
# legacy GTK3 layer-shell helper
gui-libs/gtk-layer-shell introspection
# kitty Wayland build
x11-terms/kitty wayland
# ly display manager should enumerate X sessions
x11-misc/ly X
# mpv/vlc dependency
>=media-libs/vulkan-loader-1.4.335.0-r1 X
EOF
}
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

install_oxwm_from_source() {
  echo "[INFO] Ensuring OXWM is installed from source (${OXWM_REPO_URL})"
  require_cmd git
  require_cmd zig

  local build_user="${SUDO_USER:-$USER}"

  if [[ -d "${OXWM_DIR}/.git" ]]; then
    echo "[INFO] Updating existing OXWM repo in ${OXWM_DIR}..."
    sudo -u "$build_user" git -C "$OXWM_DIR" pull --ff-only
  elif [[ -e "${OXWM_DIR}" ]]; then
    echo "[ERROR] ${OXWM_DIR} exists but is not a git repository. Please remove or fix it." >&2
    return 1
  else
    echo "[INFO] Cloning OXWM into ${OXWM_DIR}..."
    sudo git clone "$OXWM_REPO_URL" "$OXWM_DIR"
    sudo chown -R "$build_user":"$build_user" "$OXWM_DIR"
  fi

  echo "[INFO] Building OXWM (zig build -Doptimize=ReleaseFast)..."
  sudo -u "$build_user" env PATH="$PATH" bash -c "cd \"$OXWM_DIR\" && zig build -Doptimize=ReleaseFast"

  if [[ -f "${OXWM_DIR}/zig-out/bin/oxwm" ]]; then
    sudo install -Dm755 "${OXWM_DIR}/zig-out/bin/oxwm" /usr/local/bin/oxwm
    echo "[OK] Installed /usr/local/bin/oxwm"
  else
    echo "[WARN] OXWM build completed but binary not found at zig-out/bin/oxwm" >&2
  fi
}

deploy_oxwm_dotfiles() {
  echo "[INFO] Deploying OxWM, picom, and dunst configs from repo dotfiles"
  local src="${DDUBS_ROOT}/dotfiles/home/.config"
  local dst="${HOME}/.config"

  mkdir -p "${dst}"
  for dir in oxwm picom dunst; do
    if [[ -d "${src}/${dir}" ]]; then
      mkdir -p "${dst}/${dir}"
      rsync -a "${src}/${dir}/" "${dst}/${dir}/"
      echo "[OK] Synced ${dir} config to ${dst}/${dir}"
    else
      echo "[WARN] Missing ${src}/${dir} (skipped)"
    fi
  done
}

configure_oxwm_session() {
  echo "[INFO] Installing OxWM XSession desktop entry"
  copy_file "${DDUBS_ROOT}/system/usr/share/xsessions/oxwm.desktop" "/usr/share/xsessions/oxwm.desktop" 644
  copy_file "${DDUBS_ROOT}/system/usr/local/bin/oxwm-session" "/usr/local/bin/oxwm-session" 755
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
  copy_file "${DDUBS_ROOT}/system/etc/ly/save.ini" "/etc/ly/save.ini" 644
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

configure_pipewire() {
  echo "[INFO] Enabling PipeWire + WirePlumber (systemd user units)"

  # Ensure current user is in required audio/video/pipewire groups
  local grp
  for grp in audio video pipewire; do
    if id -nG "${USER}" | grep -qw "$grp"; then
      echo "[OK] User ${USER} already in group $grp"
    else
      if sudo gpasswd -a "${USER}" "$grp"; then
        echo "[INFO] Added ${USER} to group $grp"
      else
        echo "[WARN] Failed to add ${USER} to group $grp (group may not exist?)"
      fi
    fi
  done

  if command -v loginctl >/dev/null 2>&1; then
    echo "[INFO] Enabling systemd user lingering for ${USER} (for user services at boot)"
    sudo loginctl enable-linger "${USER}" ||
      echo "[WARN] Failed to enable linger for ${USER}; PipeWire user services will start only after login."
  fi

  if command -v systemctl >/dev/null 2>&1; then
    echo "[INFO] Enabling PipeWire user units for ${USER}"
    if ! systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service; then
      echo "[WARN] Could not enable PipeWire user units (no user systemd session yet?)."
      echo "[WARN] After first login, run manually as ${USER}:"
      echo "       systemctl --user enable --now pipewire.socket pipewire-pulse.socket wireplumber.service"
    fi
  else
    echo "[WARN] systemctl not found; skipping PipeWire user-unit enable step."
  fi
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

ensure_pamixer_cxx17_fix() {
  echo "[INFO] Ensuring C++17 fix for media-sound/pamixer (Portage env)"

  # Create the directory if it doesn't exist
  sudo mkdir -p /etc/portage/env

  # Write the flag to a dedicated environment file (idempotent overwrite)
  sudo tee /etc/portage/env/cxx17-fix >/dev/null <<'EOF'
CXXFLAGS="${CXXFLAGS} -std=c++17"
EOF

  # Create the package.env directory if needed
  sudo mkdir -p /etc/portage/package.env

  # Link pamixer to the fix, but avoid duplicating the line on re-runs
  local pamixer_env="/etc/portage/package.env/pamixer"
  if [[ -f "${pamixer_env}" ]] && grep -q 'media-sound/pamixer' "${pamixer_env}"; then
    echo "[INFO] pamixer package.env entry already present; leaving as-is."
  else
    echo "media-sound/pamixer cxx17-fix" | sudo tee -a "${pamixer_env}" >/dev/null
  fi
}

ensure_pipewire_use_fix() {
  echo "[INFO] Ensuring PipeWire/libpulse USE flags via package.use files"

  sudo mkdir -p /etc/portage/package.use

  local pipewire_use="/etc/portage/package.use/pipewire"
  local libpulse_use="/etc/portage/package.use/libpulse"

  if [[ -f "${pipewire_use}" ]] && grep -q 'media-video/pipewire' "${pipewire_use}"; then
    echo "[OK] media-video/pipewire USE flags already present in ${pipewire_use}"
  else
    echo 'media-video/pipewire sound-server extra alsa-pipewire' | sudo tee -a "${pipewire_use}" >/dev/null
  fi

  if [[ -f "${libpulse_use}" ]] && grep -q 'media-libs/libpulse' "${libpulse_use}"; then
    echo "[OK] media-libs/libpulse USE flags already present in ${libpulse_use}"
  else
    echo 'media-libs/libpulse glib' | sudo tee -a "${libpulse_use}" >/dev/null
  fi
}
ensure_gdk_pixbuf_loaders_cache() {
  if command -v gdk-pixbuf-query-loaders >/dev/null 2>&1; then
    echo "[INFO] Updating gdk-pixbuf loaders cache"
    if ! sudo gdk-pixbuf-query-loaders --update-cache; then
      echo "[WARN] Failed to update gdk-pixbuf loaders cache; run manually if needed."
    fi
  else
    echo "[WARN] gdk-pixbuf-query-loaders not found; skipping loaders cache update."
  fi
}
ensure_kernel_postinst_efi_update() {
  echo "[INFO] Ensuring kernel postinst hook updates EFI boot files"

  # Create the directory if it doesn't exist
  sudo mkdir -p /etc/kernel/postinst.d

  # Create the automation script (idempotent overwrite)
  sudo tee /etc/kernel/postinst.d/99-efi-update.sh >/dev/null <<'EOF'
#!/bin/sh
set -eu

KVER="${1:-}"
if [ -z "$KVER" ]; then
  echo "Usage: $0 <kernel-version>" >&2
  exit 1
fi

VMLINUX="/boot/kernel-${KVER}"
INITRAMFS="/boot/initramfs-${KVER}.img"
EFI_DIR="/boot/efi"

if [ ! -d "$EFI_DIR" ]; then
  echo "EFI directory not found: $EFI_DIR (is it mounted?)" >&2
  exit 1
fi

if [ ! -f "$VMLINUX" ] || [ ! -f "$INITRAMFS" ]; then
  echo "Missing kernel/initramfs for ${KVER} in /boot" >&2
  exit 1
fi

cp "$VMLINUX" "$EFI_DIR/vmlinuz.efi"
cp "$INITRAMFS" "$EFI_DIR/initramfs.img"
echo "EFI Boot files updated to $KVER"
EOF

  # Make it executable
  sudo chmod +x /etc/kernel/postinst.d/99-efi-update.sh
}

configure_shell_runtime_exports() {
  echo "[INFO] Ensuring XDG_RUNTIME_DIR and PULSE_SERVER exports in user shell rc files"

  local rc
  for rc in "${HOME}/.bashrc" "${HOME}/.zshrc"; do
    if [[ -f "$rc" ]]; then
      if grep -q 'Hyprland audio runtime exports (added by gentoo-install-hyprland.sh)' "$rc"; then
        echo "[OK] Runtime exports already present in $rc"
      else
        {
          echo ''
          echo '# Hyprland audio runtime exports (added by gentoo-install-hyprland.sh)'
          echo 'export XDG_RUNTIME_DIR="/run/user/$(id -u)"'
          echo 'export PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"'
        } >>"$rc"
        echo "[OK] Added runtime exports to $rc"
      fi
    else
      echo "[INFO] Shell rc file not found: $rc (skipping)"
    fi
  done
}

configure_flatpak_flathub() {
  echo "[INFO] Ensuring Flathub (stable) Flatpak remote is configured for user ${USER}"

  if ! command -v flatpak >/dev/null 2>&1; then
    echo "[WARN] flatpak command not found; skipping Flatpak remote configuration."
    return 0
  fi

  # Only configure the main Flathub repo (no beta/testing remotes)
  if flatpak --user remote-list 2>/dev/null | awk '{print $1}' | grep -qx "flathub"; then
    echo "[OK] Flathub Flatpak remote already present for user ${USER}"
  else
    if flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
      echo "[OK] Added Flathub Flatpak remote (user scope)."
    else
      echo "[WARN] Failed to add Flathub Flatpak remote; you may need to configure it manually."
    fi
  fi
}

HYPR_PACKAGES=(
  app-crypt/gcr
  # app-misc/app2unit   # need find source for this
  app-misc/fastfetch
  app-misc/ranger
  app-misc/tmux
  app-misc/nwg-look
  app-misc/yazi
  app-shells/starship
  app-shells/zoxide
  dev-lang/python
  dev-libs/libdbusmenu
  dev-libs/newt
  gui-apps/awww
  gui-apps/clipman
  gui-apps/grim
  gui-apps/quickshell
  gui-apps/hypridle::hyproverlay
  gui-apps/hyprlock::hyproverlay
  gui-apps/hyprpaper::hyproverlay
  gui-apps/nwg-drawer
  gui-apps/nwg-displays
  gui-apps/hyprshot::hyproverlay
  gui-apps/slurp
  gui-apps/swappy
  gui-apps/swaync
  gui-apps/uwsm
  gui-apps/waybar
  gui-apps/wlogout
  gui-apps/wofi
  gui-apps/wlr-randr
  gui-apps/wl-clipboard
  gui-apps/waypaper
  gui-libs/hyprcursor::hyproverlay
  gui-libs/xdg-desktop-portal-hyprland::hyproverlay
  gui-libs/hyprland-qt-support::hyproverlay
  gui-libs/hyprland-qtutils
  gui-wm/hyprland::hyproverlay
  media-sound/cava
  media-video/pipewire
  media-video/wireplumber
  media-libs/alsa-lib
  media-libs/libshumate
  media-libs/mesa
  media-sound/alsa-utils
  media-sound/pavucontrol
  media-sound/pamixer # C++17 env fix applied via ensure_pamixer_cxx17_fix
  media-sound/playerctl
  media-sound/pavucontrol
  media-libs/libcanberra
  media-video/mpv
  #  media-video/vlc  # Causes build failures not essential
  net-wireless/bluez
  net-wireless/bluez-tools
  net-misc/networkmanager
  sys-apps/bat
  sys-kernel/installkernel
  sys-fs/ncdu
  sys-apps/eza
  sys-auth/rtkit
  sys-apps/flatpak
  www-client/google-chrome
  x11-misc/matugen
  x11-misc/dmenu
  x11-misc/rofi
  x11-misc/wallust
  x11-misc/xdg-user-dirs
  x11-terms/alacritty
  x11-terms/kitty
  x11-libs/libdrm
  xfce-base/thunar
  xfce-base/tumbler
  xfce-base/xfce4-panel
  xfce-base/libxfce4windowing
  xfce-base/libxfce4ui
  xfce-base/exo
)

KERNEL_MAINT_PACKAGES=(
  app-admin/eclean-kernel
  dev-python/zstandard
)

OXWM_PACKAGES=(
  dev-util/pkgconf
  media-gfx/feh
  media-gfx/flameshot
  media-gfx/maim
  media-libs/fontconfig
  media-libs/freetype
  x11-apps/xrandr
  x11-apps/xrdb
  x11-apps/xset
  x11-apps/xsetroot
  x11-libs/libX11
  x11-libs/libXft
  x11-misc/arandr
  x11-misc/dunst
  x11-misc/nitrogen
  x11-misc/picom
  gnome-extra/polkit-gnome
  x11-misc/xclip
  x11-misc/xdotool
  x11-misc/xwallpaper
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
ensure_video_cards
ensure_gentoo_rsync_repo
ensure_hyproverlay_repo
ensure_pamixer_cxx17_fix
ensure_pipewire_use_fix
ensure_kernel_postinst_efi_update
prebuild_problematic_binaries
install_if_missing dev-lang/zig
install_list "Hyprland stack" "${HYPR_PACKAGES[@]}"
install_list "Kernel maintenance" "${KERNEL_MAINT_PACKAGES[@]}"
ensure_gdk_pixbuf_loaders_cache
install_list "OxWM X11 extras" "${OXWM_PACKAGES[@]}"
configure_shell_runtime_exports

install_list "Fonts" "${FONTS[@]}"

configure_ly
configure_pipewire
configure_flatpak_flathub
configure_gtk_dark_theme
install_oxwm_from_source
configure_oxwm_session
deploy_oxwm_dotfiles

echo "[DONE] Hyprland environment packages, ly login manager, and PipeWire audio stack ready."
