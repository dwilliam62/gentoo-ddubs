#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[after-kernel-update] %s\n' "$*"
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

log "Regenerating GRUB config..."
grub-mkconfig -o /boot/grub/grub.cfg

log "Pruning old kernels (keeping 2)..."
eclean-kernel -n 2 -d

log "Done."

