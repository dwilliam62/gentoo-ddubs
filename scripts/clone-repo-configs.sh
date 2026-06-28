#!/usr/bin/env bash
set -euo pipefail

REPO_URL_DEFAULT="https://github.com/dwilliam62/gentoo-ddubs.git"
CLONE_DIR_DEFAULT="/opt/gentoo-ddubs"
BACKUP_ROOT_BASE="/var/backups/gentoo-ddubs-config-clone"

REPO_URL="$REPO_URL_DEFAULT"
CLONE_DIR="$CLONE_DIR_DEFAULT"
DRY_RUN="false"
KEEP_CLONE="true"
INCLUDE_SYSTEM_FILES="false"
INCLUDE_FSTAB="false"
VIDEO_CARDS_OVERRIDE=""
LY_ONLY="false"

say() {
  printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

fail() {
  printf '[ERROR] %s\n' "$*" >&2
  exit 1
}

print_usage() {
  cat <<'EOF'
Usage:
  bash scripts/clone-repo-configs.sh [options]

Options:
  --repo-url <url>           Repository URL to clone.
  --clone-dir <path>         Local clone directory (default: /opt/gentoo-ddubs).
  --video-cards "<cards>"    Override detected VIDEO_CARDS value.
  --include-system-files     Also copy safe system snapshot files (currently locale.gen).
  --include-fstab            Explicitly replace /etc/fstab from snapshot (dangerous).
  --ly-only                  Only install/configure ly, skip clone and config sync.
  --keep-clone               Keep clone directory after apply (default).
  --remove-clone             Remove clone directory after apply.
  --dry-run, -n              Show planned actions without writing changes.
  --help, -h                 Show this help.

Behavior:
  If no login manager is detected, this script installs and enables x11-misc/ly.
  --ly-only forces ly setup without running the full config clone flow.
  --include-system-files does NOT overwrite /etc/fstab unless --include-fstab is set.
EOF
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    exec sudo -E bash "$0" "$@"
  fi
}

run_cmd() {
  if [[ "$DRY_RUN" = "true" ]]; then
    printf '[DRY-RUN] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

backup_target() {
  local target="$1"
  local backup_root="$2"

  if [[ ! -e "$target" && ! -L "$target" ]]; then
    return 0
  fi

  local rel backup_path
  rel="${target#/}"
  backup_path="${backup_root}/${rel}"
  run_cmd mkdir -p "$(dirname "$backup_path")"
  run_cmd cp -a "$target" "$backup_path"
  say "Backed up ${target} -> ${backup_path}"
}

sync_dir_with_backup() {
  local src="$1"
  local dst="$2"
  local backup_root="$3"

  if [[ ! -d "$src" ]]; then
    say "WARN: Missing source directory: $src (skipped)"
    return 0
  fi

  backup_target "$dst" "$backup_root"
  run_cmd mkdir -p "$dst"
  if [[ "$DRY_RUN" = "true" ]]; then
    run_cmd rsync -a --dry-run "$src/" "$dst/"
  else
    run_cmd rsync -a "$src/" "$dst/"
  fi
}

copy_file_with_backup() {
  local src="$1"
  local dst="$2"
  local backup_root="$3"

  if [[ ! -f "$src" ]]; then
    say "WARN: Missing source file: $src (skipped)"
    return 0
  fi

  backup_target "$dst" "$backup_root"
  run_cmd mkdir -p "$(dirname "$dst")"
  run_cmd install -m 644 "$src" "$dst"
}

detect_video_cards() {
  if [[ -n "$VIDEO_CARDS_OVERRIDE" ]]; then
    printf '%s\n' "$VIDEO_CARDS_OVERRIDE"
    return 0
  fi

  local detected=()
  if command -v lspci >/dev/null 2>&1; then
    if lspci | grep -qiE 'virtio|qxl|vmware'; then
      detected+=("virgl")
    fi
    if lspci | grep -qi 'nvidia'; then
      detected+=("nvidia")
    fi
    if lspci | grep -qiE 'amd|ati'; then
      detected+=("amdgpu" "radeonsi")
    fi
    if lspci | grep -qi 'intel'; then
      detected+=("intel" "i915")
    fi
  fi

  if [[ ${#detected[@]} -eq 0 ]]; then
    detected=("virgl")
  fi

  printf '%s\n' "${detected[@]}" | awk 'NF && !seen[$0]++' | paste -sd' ' -
}

set_makeconf_video_cards() {
  local make_conf="$1"
  local cards="$2"

  if [[ "$DRY_RUN" = "true" ]]; then
    say "Would set VIDEO_CARDS=\"$cards\" in ${make_conf}"
    return 0
  fi

  if grep -q '^VIDEO_CARDS=' "$make_conf"; then
    sed -i "s/^VIDEO_CARDS=.*/VIDEO_CARDS=\"${cards}\"/" "$make_conf"
  else
    printf '\nVIDEO_CARDS=\"%s\"\n' "$cards" >>"$make_conf"
  fi
}

set_gpu_specific_mesa_flags() {
  local cards="$1"
  local mesa_file="/etc/portage/package.use/mesa-gpu-cards"
  local libdrm_file="/etc/portage/package.use/libdrm-gpu-cards"
  local needs_amd_libdrm_fix="false"
  local flags=()
  local card

  for card in $cards; do
    case "$card" in
      virgl|nvidia|amdgpu|radeonsi|intel|i915)
        flags+=("video_cards_${card}")
        ;;
    esac
    case "$card" in
      amdgpu|radeonsi) needs_amd_libdrm_fix="true" ;;
    esac
  done

  if [[ ${#flags[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" = "true" ]]; then
    say "Would write ${mesa_file}: media-libs/mesa ${flags[*]}"
    if [[ "$needs_amd_libdrm_fix" = "true" ]]; then
      say "Would write ${libdrm_file}: >=x11-libs/libdrm-2.4.134 video_cards_radeon"
    elif [[ -f "$libdrm_file" ]]; then
      say "Would remove ${libdrm_file} (AMD-specific fix not needed)"
    fi
    return 0
  fi

  mkdir -p /etc/portage/package.use
  printf 'media-libs/mesa %s\n' "${flags[*]}" >"$mesa_file"

  if [[ "$needs_amd_libdrm_fix" = "true" ]]; then
    printf '>=x11-libs/libdrm-2.4.134 video_cards_radeon\n' >"$libdrm_file"
  else
    rm -f "$libdrm_file"
  fi
}

login_manager_atom_installed() {
  local atom="$1"

  if command -v qlist >/dev/null 2>&1; then
    qlist -I "$atom" >/dev/null 2>&1
    return $?
  fi

  if command -v portageq >/dev/null 2>&1; then
    portageq match / "$atom" 2>/dev/null | grep -q '.'
    return $?
  fi

  return 1
}

ensure_ly_package_use_for_init() {
  local ly_use_file="/etc/portage/package.use/ly-login-manager"
  local ly_flags="x11-misc/ly -X"

  if command -v systemctl >/dev/null 2>&1; then
    ly_flags="x11-misc/ly -X systemd"
  fi

  if [[ "$DRY_RUN" = "true" ]]; then
    say "Would write ${ly_use_file}: ${ly_flags}"
    return 0
  fi

  mkdir -p /etc/portage/package.use
  printf '%s\n' "$ly_flags" >"$ly_use_file"
}

detect_ly_systemd_unit() {
  local units
  local ly_tty="${LY_TTY:-tty2}"
  units="$(systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}')"
  if printf '%s\n' "$units" | grep -qx 'ly.service'; then
    printf 'ly.service\n'
    return 0
  fi
  if printf '%s\n' "$units" | grep -qx 'ly@.service'; then
    printf 'ly@%s.service\n' "$ly_tty"
    return 0
  fi
  if printf '%s\n' "$units" | grep -qx 'display-manager.service'; then
    printf 'display-manager.service\n'
    return 0
  fi
  return 1
}

enable_ly_systemd_service() {
  local unit target_unit ly_tty="${LY_TTY:-tty2}"
  run_cmd systemctl daemon-reload

  if unit="$(detect_ly_systemd_unit)"; then
    run_cmd systemctl enable "$unit"
    say "Enabled ${unit}."
    return 0
  fi

  if [[ -f /usr/lib/systemd/system/ly.service ]]; then
    target_unit="/usr/lib/systemd/system/ly.service"
  elif [[ -f /lib/systemd/system/ly.service ]]; then
    target_unit="/lib/systemd/system/ly.service"
  elif [[ -f /usr/lib/systemd/system/ly@.service || -f /lib/systemd/system/ly@.service ]]; then
    run_cmd systemctl enable "ly@${ly_tty}.service"
    say "Enabled ly@${ly_tty}.service."
    return 0
  else
    say "WARN: ly installed but no systemd unit file found."
    return 1
  fi

  run_cmd mkdir -p /etc/systemd/system
  run_cmd ln -sfn "$target_unit" /etc/systemd/system/display-manager.service
  run_cmd systemctl daemon-reload
  run_cmd systemctl enable display-manager.service
  say "Enabled display-manager.service (linked to ly.service)."
}

any_login_manager_detected() {
  local atom
  local known_login_managers=(
    "x11-misc/ly"
    "gnome-base/gdm"
    "x11-misc/sddm"
    "x11-misc/lightdm"
    "lxde-base/lxdm"
    "x11-apps/xdm"
  )

  for atom in "${known_login_managers[@]}"; do
    if login_manager_atom_installed "$atom"; then
      say "Detected installed login manager package: ${atom}"
      return 0
    fi
  done

  if command -v systemctl >/dev/null 2>&1; then
    if systemctl list-unit-files --type=service --no-legend 2>/dev/null | awk '{print $1}' | grep -Eq '^(display-manager|ly|ly@|gdm|sddm|lightdm|lxdm|xdm)(@.*)?\.service$'; then
      say "Detected login manager service unit on system."
      return 0
    fi
  fi

  return 1
}
ensure_required_repositories() {
  local repo
  local required_repos=(guru hyproverlay)
  local localrepo_dir="/var/db/repos/localrepo"
  local localrepo_name_file="${localrepo_dir}/profiles/repo_name"
  local localrepo_layout_file="${localrepo_dir}/metadata/layout.conf"
  local localrepo_conf_file="/etc/portage/repos.conf/localrepo.conf"

  if [[ "$DRY_RUN" = "true" ]]; then
    say "Would ensure required overlays and localrepo skeleton exist."
    return 0
  fi

  run_cmd mkdir -p "${localrepo_dir}/profiles" "${localrepo_dir}/metadata"
  if [[ ! -f "$localrepo_name_file" ]]; then
    printf '%s\n' localrepo >"$localrepo_name_file"
  fi
  if [[ ! -f "$localrepo_layout_file" ]]; then
    cat >"$localrepo_layout_file" <<'EOF'
masters = gentoo
EOF
  fi
  if [[ ! -f "$localrepo_conf_file" ]]; then
    run_cmd mkdir -p /etc/portage/repos.conf
    cat >"$localrepo_conf_file" <<'EOF'
[localrepo]
location = /var/db/repos/localrepo
masters = gentoo
auto-sync = no
EOF
  fi

  if command -v emaint >/dev/null 2>&1; then
    for repo in "${required_repos[@]}"; do
      local repo_dir="/var/db/repos/${repo}"
      if grep -Rqs "^\[$repo\]" /etc/portage/repos.conf; then
        if [[ -d "$repo_dir" && ! -d "${repo_dir}/.git" ]]; then
          if find "$repo_dir" -mindepth 1 -maxdepth 1 ! \( -name profiles -o -name metadata \) | grep -q .; then
            say "WARN: ${repo_dir} is non-git and contains unexpected files; leaving as-is before sync."
          else
            run_cmd rm -rf "$repo_dir"
          fi
        fi
        say "Syncing repository ${repo}..."
        if [[ "$DRY_RUN" = "true" ]]; then
          run_cmd emaint sync -r "$repo"
        else
          if ! emaint sync -r "$repo"; then
            say "WARN: Failed to sync ${repo}; continuing."
          fi
        fi
      else
        say "WARN: Repository ${repo} not configured in /etc/portage/repos.conf; skipping sync."
      fi
    done
  else
    say "WARN: emaint not available; skipping overlay sync."
  fi
}

ensure_ly_if_no_login_manager() {
  if login_manager_atom_installed "x11-misc/ly"; then
    ensure_ly_installed_and_enabled
    return 0
  fi
  if any_login_manager_detected; then
    say "Existing login manager detected; skipping ly installation."
    return 0
  fi
  say "No login manager detected; installing ly..."
  ensure_ly_installed_and_enabled
}

ensure_ly_installed_and_enabled() {
  ensure_required_repositories
  ensure_ly_package_use_for_init
  if login_manager_atom_installed "x11-misc/ly"; then
    say "ly package already installed; ensuring service configuration."
  else
    say "Installing ly..."
    run_cmd emerge -v --ask=n --autounmask-write --autounmask-continue --binpkg-respect-use=y x11-misc/ly app-misc/cmatrix
  fi

  if command -v systemctl >/dev/null 2>&1; then
    if ! enable_ly_systemd_service; then
      say "Rebuilding ly with current USE flags and retrying service enable..."
      run_cmd emerge -v --ask=n --autounmask-write --autounmask-continue --binpkg-respect-use=y --oneshot x11-misc/ly
      enable_ly_systemd_service || say "WARN: Could not enable ly via systemd after rebuild."
    fi
  elif command -v rc-update >/dev/null 2>&1 && [[ -x /etc/init.d/ly ]]; then
    run_cmd rc-update add ly default
    say "Enabled ly in OpenRC default runlevel."
  else
    say "WARN: Neither systemd nor OpenRC service tooling found; ly installed but not enabled."
  fi
}

clone_or_update_repo() {
  if [[ -d "${CLONE_DIR}/.git" ]]; then
    say "Updating existing clone at ${CLONE_DIR}"
    run_cmd git -C "$CLONE_DIR" pull --ff-only
  else
    say "Cloning repository to ${CLONE_DIR}"
    run_cmd mkdir -p "$(dirname "$CLONE_DIR")"
    run_cmd git clone --depth 1 "$REPO_URL" "$CLONE_DIR"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --repo-url)
        [[ $# -gt 1 ]] || fail "--repo-url requires a value"
        REPO_URL="$2"
        shift 2
        ;;
      --clone-dir)
        [[ $# -gt 1 ]] || fail "--clone-dir requires a value"
        CLONE_DIR="$2"
        shift 2
        ;;
      --video-cards)
        [[ $# -gt 1 ]] || fail "--video-cards requires a value"
        VIDEO_CARDS_OVERRIDE="$2"
        shift 2
        ;;
      --include-system-files)
        INCLUDE_SYSTEM_FILES="true"
        shift
        ;;
      --include-fstab)
        INCLUDE_FSTAB="true"
        INCLUDE_SYSTEM_FILES="true"
        shift
        ;;
      --ly-only)
        LY_ONLY="true"
        shift
        ;;
      --keep-clone)
        KEEP_CLONE="true"
        shift
        ;;
      --remove-clone)
        KEEP_CLONE="false"
        shift
        ;;
      --dry-run|-n)
        DRY_RUN="true"
        shift
        ;;
      --help|-h)
        print_usage
        exit 0
        ;;
      *)
        fail "Unknown option: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  need_root "$@"

  if [[ "$LY_ONLY" = "true" ]]; then
    say "Running in ly-only mode..."
    ensure_ly_installed_and_enabled
    say "Done (ly-only mode)."
    return 0
  fi

  command -v git >/dev/null 2>&1 || fail "git is required"
  command -v rsync >/dev/null 2>&1 || fail "rsync is required"

  local backup_root
  backup_root="${BACKUP_ROOT_BASE}/$(date +%Y%m%d-%H%M%S)"
  run_cmd mkdir -p "$backup_root"

  clone_or_update_repo

  local src_portage src_world src_fstab src_locale
  src_portage="${CLONE_DIR}/system/etc/portage"
  src_world="${CLONE_DIR}/system/var/lib/portage/world"
  src_fstab="${CLONE_DIR}/system/etc/fstab"
  src_locale="${CLONE_DIR}/system/etc/locale.gen"

  [[ -d "$src_portage" ]] || fail "Missing ${src_portage}. Is this the expected repository?"

  say "Applying repository Portage snapshot"
  sync_dir_with_backup "$src_portage" "/etc/portage" "$backup_root"
  copy_file_with_backup "$src_world" "/var/lib/portage/world" "$backup_root"

  if [[ "$INCLUDE_SYSTEM_FILES" = "true" ]]; then
    say "Applying optional system snapshot files (locale.gen)"
    copy_file_with_backup "$src_locale" "/etc/locale.gen" "$backup_root"
    if [[ "$INCLUDE_FSTAB" = "true" ]]; then
      say "Applying fstab snapshot because --include-fstab was explicitly requested"
      copy_file_with_backup "$src_fstab" "/etc/fstab" "$backup_root"
    else
      say "Skipping /etc/fstab snapshot (use --include-fstab to apply it explicitly)"
    fi
  fi

  local cards
  cards="$(detect_video_cards)"
  set_makeconf_video_cards "/etc/portage/make.conf" "$cards"
  set_gpu_specific_mesa_flags "$cards"
  say "GPU-aware config applied with VIDEO_CARDS=${cards}"
  ensure_required_repositories

  ensure_ly_if_no_login_manager

  if [[ "$KEEP_CLONE" = "false" ]]; then
    run_cmd rm -rf "$CLONE_DIR"
    say "Removed clone directory: ${CLONE_DIR}"
  fi

  say "Done. Backup root: ${backup_root}"
}

main "$@"
