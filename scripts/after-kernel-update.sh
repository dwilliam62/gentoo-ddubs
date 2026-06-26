#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[after-kernel-update] %s\n' "$*"
}

fail() {
  printf '[after-kernel-update] ERROR: %s\n' "$*" >&2
  exit 1
}
prune_kernels_missing_modules() {
  local running_version version
  running_version="$(uname -r)"

  while IFS= read -r kernel_path; do
    version="${kernel_path#/boot/kernel-}"
    [ -n "$version" ] || continue

    if [ "$version" = "$running_version" ]; then
      continue
    fi

    if [ ! -d "/lib/modules/${version}" ]; then
      log "Removing kernel ${version} from /boot (missing /lib/modules/${version})..."
      rm -f "/boot/kernel-${version}" "/boot/initramfs-${version}.img"
    fi
  done < <(find /boot -maxdepth 1 -type f -name 'kernel-*' -printf '%p\n' | sort -V)
}
latest_boot_kernel_version() {
  find /boot -maxdepth 1 -type f -name 'kernel-*' -printf '%f\n' 2>/dev/null \
    | sed 's/^kernel-//' \
    | sort -V \
    | tail -n 1
}

verify_latest_kernel_artifacts() {
  local latest="$1"
  [[ -n "$latest" ]] || fail "No kernel-* images found in /boot after cleanup."

  if [[ ! -f "/boot/kernel-${latest}" ]]; then
    fail "Missing /boot/kernel-${latest}"
  fi
  if [[ ! -f "/boot/initramfs-${latest}.img" ]]; then
    fail "Missing /boot/initramfs-${latest}.img"
  fi
  if [[ ! -d "/lib/modules/${latest}" ]]; then
    fail "Missing /lib/modules/${latest}"
  fi

  if [[ ! -d "/usr/src/linux-${latest}" ]]; then
    log "WARN: Missing /usr/src/linux-${latest}; source symlink cannot be updated automatically."
  fi
}

ensure_linux_symlink_matches_latest() {
  local latest="$1"
  local latest_source="/usr/src/linux-${latest}"
  local current_target

  if [[ ! -d "$latest_source" ]]; then
    return 0
  fi

  current_target="$(readlink /usr/src/linux 2>/dev/null || true)"
  if [[ "$current_target" != "linux-${latest}" && "$current_target" != "/usr/src/linux-${latest}" ]]; then
    ln -sfn "linux-${latest}" /usr/src/linux
    log "Updated /usr/src/linux -> linux-${latest}"
  fi
}

verify_grub_cfg_contains_latest() {
  local latest="$1"
  [[ -f /boot/grub/grub.cfg ]] || fail "Missing /boot/grub/grub.cfg after grub-mkconfig"

  if ! grep -Fq "kernel-${latest}" /boot/grub/grub.cfg; then
    fail "grub.cfg does not reference kernel-${latest}"
  fi
}

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  fail "must be run as root"
fi

if ! command -v grub-mkconfig >/dev/null 2>&1; then
  fail "grub-mkconfig not found in PATH"
fi

if ! command -v eclean-kernel >/dev/null 2>&1; then
  fail "eclean-kernel not found in PATH (install app-admin/eclean-kernel)"
fi
KEEP_KERNELS="${KEEP_KERNELS:-2}"

if ! [[ "$KEEP_KERNELS" =~ ^[0-9]+$ ]] || [[ "$KEEP_KERNELS" -lt 1 ]]; then
  fail "KEEP_KERNELS must be a positive integer (got: $KEEP_KERNELS)"
fi

detect_eclean_layout() {
  local configured_layout
  configured_layout="$(
    awk -F= '
      /^[[:space:]]*layout[[:space:]]*=/ {
        gsub(/[[:space:]]/, "", $2)
        print tolower($2)
        exit
      }
    ' /etc/kernel/install.conf 2>/dev/null || true
  )"

  case "$configured_layout" in
    grub|compat|std)
      printf 'std\n'
      ;;
    bls|blspec)
      printf 'blspec\n'
      ;;
    auto|'')
      printf 'auto\n'
      ;;
    *)
      log "Unknown layout '$configured_layout' in /etc/kernel/install.conf; falling back to auto"
      printf 'auto\n'
      ;;
  esac
}

eclean_layout="$(detect_eclean_layout)"
prune_kernels_missing_modules

log "Pruning old kernels (keeping ${KEEP_KERNELS}, layout=${eclean_layout})..."
eclean-kernel -L "$eclean_layout" -n "$KEEP_KERNELS" -d

latest_kernel="$(latest_boot_kernel_version)"
verify_latest_kernel_artifacts "$latest_kernel"
ensure_linux_symlink_matches_latest "$latest_kernel"

log "Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg
verify_grub_cfg_contains_latest "$latest_kernel"

log "Done. Latest kernel validated: ${latest_kernel}"

