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
VIDEO_CARDS_OVERRIDE=""

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
  --include-system-files     Also copy system/etc/fstab and system/etc/locale.gen.
  --keep-clone               Keep clone directory after apply (default).
  --remove-clone             Remove clone directory after apply.
  --dry-run, -n              Show planned actions without writing changes.
  --help, -h                 Show this help.
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
  local flags=()
  local card

  for card in $cards; do
    case "$card" in
      virgl|nvidia|amdgpu|radeonsi|intel|i915)
        flags+=("video_cards_${card}")
        ;;
    esac
  done

  if [[ ${#flags[@]} -eq 0 ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" = "true" ]]; then
    say "Would write ${mesa_file}: media-libs/mesa ${flags[*]}"
    return 0
  fi

  mkdir -p /etc/portage/package.use
  printf 'media-libs/mesa %s\n' "${flags[*]}" >"$mesa_file"
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
    say "Applying optional system snapshot files (fstab/locale.gen)"
    copy_file_with_backup "$src_fstab" "/etc/fstab" "$backup_root"
    copy_file_with_backup "$src_locale" "/etc/locale.gen" "$backup_root"
  fi

  local cards
  cards="$(detect_video_cards)"
  set_makeconf_video_cards "/etc/portage/make.conf" "$cards"
  set_gpu_specific_mesa_flags "$cards"
  say "GPU-aware config applied with VIDEO_CARDS=${cards}"

  if [[ "$KEEP_CLONE" = "false" ]]; then
    run_cmd rm -rf "$CLONE_DIR"
    say "Removed clone directory: ${CLONE_DIR}"
  fi

  say "Done. Backup root: ${backup_root}"
}

main "$@"
