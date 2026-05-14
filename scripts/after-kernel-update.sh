#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[after-kernel-update] %s\n' "$*"
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

fail() {
  printf '[after-kernel-update] ERROR: %s\n' "$*" >&2
  exit 1
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

log "Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg

log "Done."

