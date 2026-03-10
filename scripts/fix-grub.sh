#!/usr/bin/env bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
GRUB_CFG="/boot/grub/grub.cfg"
LOG_FILE="/var/log/fix-grub.log"
[[ -w "$(dirname "$LOG_FILE")" ]] || LOG_FILE="/tmp/fix-grub.log"
SUDO=""

USE_COLOR=0
if [[ -t 1 ]]; then
  USE_COLOR=1
fi

color() {
  local code="$1"
  shift
  if [[ "$USE_COLOR" -eq 1 ]]; then
    printf "\033[%sm%s\033[0m" "$code" "$*"
  else
    printf "%s" "$*"
  fi
}

log() {
  local level="$1"
  shift
  local ts
  local level_colored="$level"
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  case "$level" in
    INFO) level_colored="$(color "32" "$level")" ;;
    WARN) level_colored="$(color "33" "$level")" ;;
    ERROR) level_colored="$(color "31" "$level")" ;;
    *) level_colored="$level" ;;
  esac
  printf "%s [%s] %s\n" "$ts" "$level_colored" "$*" | tee -a "$LOG_FILE"
}

die() {
  log "ERROR" "$*"
  exit 1
}

ensure_privileges() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    SUDO=""
    return 0
  fi
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
    return 0
  fi
  die "This script requires root privileges (sudo not found)."
}

usage() {
  cat <<'EOF'
Usage: fix-grub.sh [options]

Default action: regenerate GRUB config and show menu entries.

Options:
  --check         List installed kernels and check if latest is set as default.
  --info          Print GRUB menu entries in a formatted table.
  --trim          Remove older kernels; keeps newest and one previous.
  --set-default X Set GRUB default by index, version, or exact title.
  --env           Show GRUB environment (grub-editenv list).
  --yes           Assume yes for prompts (used with --trim).
  --dry-run       Show what would change without doing it (used with --trim).
  --backup        Always back up grub.cfg before regenerating (default).
  --no-backup     Skip grub.cfg backup when regenerating.
  -h, --help      Show this help.

Notes:
  - This script expects kernels in /boot named kernel-<version> or vmlinuz-<version>.
  - initramfs files are expected as initramfs-<version>.img or initrd-<version>.img.
EOF
}

BACKUP=1
DO_REGEN=1
DO_CHECK=0
DO_INFO=0
DO_TRIM=0
DO_SET_DEFAULT=0
SET_DEFAULT_VAL=""
DO_ENV=0
ASSUME_YES=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      DO_CHECK=1
      DO_REGEN=0
      ;;
    --info)
      DO_INFO=1
      DO_REGEN=0
      ;;
    --trim)
      DO_TRIM=1
      DO_REGEN=0
      ;;
    --set-default)
      DO_SET_DEFAULT=1
      DO_REGEN=0
      shift
      [[ $# -gt 0 ]] || die "--set-default requires a value"
      SET_DEFAULT_VAL="$1"
      ;;
    --env)
      DO_ENV=1
      DO_REGEN=0
      ;;
    --yes)
      ASSUME_YES=1
      ;;
    --dry-run)
      DRY_RUN=1
      ;;
    --backup)
      BACKUP=1
      ;;
    --no-backup)
      BACKUP=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

list_kernels() {
  ensure_privileges
  local kernels=()
  while IFS= read -r -d '' f; do
    [[ -n "$f" ]] && kernels+=("$f")
  done < <($SUDO find /boot -maxdepth 1 -type f \( -name 'kernel-*' -o -name 'vmlinuz-*' \) -print0 2>/dev/null || true)
  printf "%s\n" "${kernels[@]}" | sed '/^$/d'
}

list_kernel_versions() {
  ensure_privileges
  $SUDO find /boot -maxdepth 1 -type f \( -name 'kernel-*' -o -name 'vmlinuz-*' \) -printf '%f\n' 2>/dev/null \
    | sed -e 's/^kernel-//' -e 's/^vmlinuz-//' \
    | sed '/^$/d' \
    | sort -V
}

kernel_version_from_path() {
  local base
  base="$(basename "$1")"
  base="${base#kernel-}"
  base="${base#vmlinuz-}"
  printf "%s" "$base"
}


latest_two_versions() {
  local versions
  versions="$(list_kernel_versions)"
  local latest prev
  latest="$(printf "%s\n" "$versions" | tail -n 1)"
  prev="$(printf "%s\n" "$versions" | tail -n 2 | head -n 1)"
  printf "%s\n%s\n" "$latest" "$prev"
}

get_default_kernel_from_grubcfg() {
  ensure_privileges
  [[ -f "$GRUB_CFG" ]] || return 1
  $SUDO awk '
    $1=="menuentry" {in_menu=1}
    in_menu && ($1=="linux" || $1=="linuxefi") {print $2; exit}
  ' "$GRUB_CFG"
}

print_kernel_table() {
  ensure_privileges
  local running latest default_kernel default_ver
  running="$(uname -r)"
  default_kernel="$(get_default_kernel_from_grubcfg || true)"
  default_ver=""
  if [[ -n "$default_kernel" ]]; then
    default_ver="$(kernel_version_from_path "$default_kernel")"
  fi

  local versions
  versions="$(list_kernel_versions)"
  if [[ -z "$versions" ]]; then
    log "WARN" "No kernels found in /boot."
    return 0
  fi
  latest="$(printf "%s\n" "$versions" | tail -n 1)"

  printf "%-3s %-24s %-12s %-12s %-12s\n" "Idx" "Version" "Latest" "Running" "Default"
  local idx=0
  while IFS= read -r v; do
    idx=$((idx + 1))
    printf "%-3s %-24s %-12s %-12s %-12s\n" \
      "$idx" \
      "$v" \
      "$([[ "$v" == "$latest" ]] && echo "yes" || echo "no")" \
      "$([[ "$v" == "$running" ]] && echo "yes" || echo "no")" \
      "$([[ -n "$default_ver" && "$v" == "$default_ver" ]] && echo "yes" || echo "no")"
  done <<< "$versions"

  if [[ "$running" != "$latest" ]]; then
    log "WARN" "Running kernel ($running) is not the latest installed ($latest)."
  else
    log "INFO" "Running kernel is the latest installed."
  fi

  if [[ -n "$default_ver" && "$default_ver" != "$latest" ]]; then
    log "WARN" "GRUB default ($default_ver) is not the latest installed ($latest)."
  elif [[ -n "$default_ver" ]]; then
    log "INFO" "GRUB default appears to be the latest installed."
  else
    log "WARN" "Could not determine GRUB default kernel from $GRUB_CFG."
  fi
}

print_grub_info_table() {
  ensure_privileges
  [[ -f "$GRUB_CFG" ]] || die "Missing $GRUB_CFG"
  printf "%-4s %-40s %-30s %-30s\n" "Idx" "Title" "Kernel" "Initrd"
  $SUDO awk -v max=40 '
    $1=="menuentry" {
      idx++; in_menu=1;
      title=$0;
      sub(/^menuentry '\''/, "", title);
      sub(/'\''.*$/, "", title);
      kernel=""; initrd="";
    }
    in_menu && ($1=="linux" || $1=="linuxefi") {kernel=$2}
    in_menu && ($1=="initrd" || $1=="initrdefi") {initrd=$2}
    in_menu && $1=="}" {
      if (length(title) > max) {title=substr(title,1,max-3) "..."}
      printf "%-4s %-40s %-30s %-30s\n", idx, title, kernel, initrd;
      in_menu=0;
    }
  ' "$GRUB_CFG"
}

grub_entries_raw() {
  ensure_privileges
  [[ -f "$GRUB_CFG" ]] || die "Missing $GRUB_CFG"
  $SUDO awk '
    $1=="menuentry" {
      idx++; in_menu=1;
      title=$0;
      sub(/^menuentry '\''/, "", title);
      sub(/'\''.*$/, "", title);
      kernel=""; initrd="";
    }
    in_menu && ($1=="linux" || $1=="linuxefi") {kernel=$2}
    in_menu && ($1=="initrd" || $1=="initrdefi") {initrd=$2}
    in_menu && $1=="}" {
      printf "%s|%s|%s|%s\n", idx, title, kernel, initrd;
      in_menu=0;
    }
  ' "$GRUB_CFG"
}

set_grub_default() {
  ensure_privileges
  local val="$1"
  local idx="" title="" kernel="" initrd="" match_count=0
  local entries
  entries="$(grub_entries_raw)"

  if [[ "$val" =~ ^[0-9]+$ ]]; then
    idx="$val"
  else
    while IFS='|' read -r e_idx e_title e_kernel e_initrd; do
      if [[ "$e_title" == "$val" ]]; then
        idx="$e_idx"
        title="$e_title"
        kernel="$e_kernel"
        initrd="$e_initrd"
        match_count=$((match_count + 1))
      elif [[ -n "$e_kernel" ]]; then
        local v
        v="$(kernel_version_from_path "$e_kernel")"
        if [[ "$v" == "$val" ]]; then
          idx="$e_idx"
          title="$e_title"
          kernel="$e_kernel"
          initrd="$e_initrd"
          match_count=$((match_count + 1))
        fi
      fi
    done <<< "$entries"
  fi

  if [[ -z "$idx" ]]; then
    die "Could not find GRUB entry for: $val"
  fi
  if [[ "$match_count" -gt 1 ]]; then
    log "WARN" "Multiple matches found for '$val'; using first match (index $idx)."
  fi

  log "INFO" "Setting GRUB default to index $idx${title:+ ($title)}"
  $SUDO grub-set-default "$idx"
  if command -v grub-editenv >/dev/null 2>&1; then
    log "INFO" "GRUB environment:"
    $SUDO grub-editenv list || true
  fi
}

show_grub_env() {
  ensure_privileges
  if command -v grub-editenv >/dev/null 2>&1; then
    $SUDO grub-editenv list
  else
    die "grub-editenv not found"
  fi
}

regen_grub() {
  ensure_privileges
  log "INFO" "Regenerating GRUB config."
  if [[ "$BACKUP" -eq 1 && -f "$GRUB_CFG" ]]; then
    local bak="$GRUB_CFG.bak-$(date '+%Y%m%d%H%M%S')"
    log "INFO" "Backing up $GRUB_CFG to $bak"
    $SUDO cp -a "$GRUB_CFG" "$bak"
  fi
  $SUDO grub-mkconfig -o "$GRUB_CFG"
  log "INFO" "GRUB config updated."
  $SUDO grep -n "menuentry" -n "$GRUB_CFG" || true
  print_kernel_table
}

trim_kernels() {
  ensure_privileges
  local versions latest prev keep remove
  versions="$(list_kernel_versions)"
  if [[ -z "$versions" ]]; then
    log "WARN" "No kernels found in /boot."
    return 0
  fi
  read -r latest prev < <(latest_two_versions)

  keep=()
  [[ -n "$latest" ]] && keep+=("$latest")
  [[ -n "$prev" && "$prev" != "$latest" ]] && keep+=("$prev")

  remove=()
  while IFS= read -r v; do
    if [[ ! " ${keep[*]} " =~ " ${v} " ]]; then
      remove+=("$v")
    fi
  done <<< "$versions"

  if [[ "${#remove[@]}" -eq 0 ]]; then
    log "INFO" "No kernels to trim. Only newest and one previous are present."
    return 0
  fi

  log "INFO" "Will keep: ${keep[*]}"
  log "WARN" "Will remove: ${remove[*]}"

  if [[ "$ASSUME_YES" -ne 1 ]]; then
    read -r -p "Proceed with removal? [y/N] " ans
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] || {
      log "INFO" "Trim cancelled."
      return 0
    }
  fi

  for v in "${remove[@]}"; do
    local k1="/boot/kernel-$v"
    local k2="/boot/vmlinuz-$v"
    local i1="/boot/initramfs-$v.img"
    local i2="/boot/initrd-$v.img"

    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "INFO" "DRY RUN: would remove $k1 $k2 $i1 $i2"
      continue
    fi

    $SUDO rm -f "$k1" "$k2" "$i1" "$i2"
    log "INFO" "Removed kernel artifacts for $v"
  done
}

if [[ "$DO_CHECK" -eq 1 ]]; then
  print_kernel_table
  exit 0
fi

if [[ "$DO_INFO" -eq 1 ]]; then
  print_grub_info_table
  exit 0
fi

if [[ "$DO_TRIM" -eq 1 ]]; then
  trim_kernels
  exit 0
fi
if [[ "$DO_ENV" -eq 1 ]]; then
  show_grub_env
  exit 0
fi

if [[ "$DO_SET_DEFAULT" -eq 1 ]]; then
  set_grub_default "$SET_DEFAULT_VAL"
  exit 0
fi

regen_grub

if [[ "$(list_kernel_versions | wc -l | tr -d ' ')" -gt 2 ]]; then
  log "INFO" "More than two kernels detected. You can trim older ones with: $SCRIPT_NAME --trim"
fi
