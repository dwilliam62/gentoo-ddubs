#!/usr/bin/env bash
set -euo pipefail

# Script: sync-gentoo-cfg.sh
# Purpose: Capture current Gentoo system configuration for migration/restoration
# Usage: bash scripts/sync-gentoo-cfg.sh [OPTIONS]
#
# OPTIONS:
#   -h, --help       Show this help message
#   -q, --quiet      Suppress verbose rsync output
#   -d, --dry-run    Show what would be synced without making changes

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}
SYSTEM_DIR="${REPO_ROOT}/system"
LOG_DIR="${REPO_ROOT}/.sync-logs"
LOG_FILE="${LOG_DIR}/sync-$(date +%s).log"
VERBOSE=true
DRY_RUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      grep '^#' "$0" | sed 's/^# //; s/^#!//' | head -20
      exit 0
      ;;
    -q|--quiet)
      VERBOSE=false
      shift
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Utility functions
log_msg() {
  local msg="$1"
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $msg" | tee -a "$LOG_FILE"
}

log_error() {
  local msg="$1"
  echo "[ERROR] $msg" | tee -a "$LOG_FILE" >&2
}

rsync_cmd() {
  local src="$1"
  local dst="$2"
  local opts=("-av" "--mkpath")
  
  [[ "$VERBOSE" == true ]] || opts+=("--quiet")
  [[ "$DRY_RUN" == true ]] && opts+=("--dry-run")
  
  # tee keeps the redirect owned by the caller while sudo only runs rsync;
  # pipefail (set at the top) preserves rsync's exit status.
  if sudo rsync "${opts[@]}" "$src" "$dst" 2>&1 | tee -a "$LOG_FILE" >/dev/null; then
    log_msg "✓ Synced: $src"
  else
    log_error "✗ Failed to sync: $src"
    return 1
  fi
}

# Ensure log directory exists
mkdir -p "$LOG_DIR"
log_msg "Starting Gentoo config sync..."
log_msg "Repository root: $REPO_ROOT"
log_msg "System snapshot dir: $SYSTEM_DIR"

if [[ "$DRY_RUN" == true ]]; then
  log_msg "[DRY-RUN MODE - No changes will be made]"
fi

# Check if we can write to the target
if ! [[ -w "$SYSTEM_DIR" ]]; then
  log_error "System directory not writable: $SYSTEM_DIR"
  exit 1
fi

# Sync Portage configuration
log_msg ""
log_msg ">>> Syncing /etc/portage..."
rsync_cmd /etc/portage/ "${SYSTEM_DIR}/etc/portage/" || true

# Sync Portage database (world, installed packages, etc.)
log_msg ""
log_msg ">>> Syncing /var/lib/portage..."
rsync_cmd /var/lib/portage/ "${SYSTEM_DIR}/var/lib/portage/" || true

# Sync system config files (fstab, locale, hosts, etc.)
log_msg ""
log_msg ">>> Syncing system configuration (/etc)..."
SYS_CONFIGS=(
  "/etc/fstab"
  "/etc/locale.gen"
  "/etc/locale.conf"
  "/etc/hostname"
  "/etc/hosts"
  "/etc/resolv.conf"
  "/etc/profile"
  "/etc/environment"
)
for cfg in "${SYS_CONFIGS[@]}"; do
  if [[ -e "$cfg" ]]; then
    rsync_cmd "$cfg" "${SYSTEM_DIR}${cfg}" || true
  fi
done

# Sync kernel config
log_msg ""
log_msg ">>> Syncing kernel configuration..."
# A glob inside [[ -f ]] is not expanded, so test it with compgen first.
if compgen -G "/boot/config-*" >/dev/null; then
  for boot_cfg in /boot/config-*; do
    rsync_cmd "$boot_cfg" "${SYSTEM_DIR}/boot/" || true
  done
fi
if [[ -f /usr/src/linux/.config ]]; then
  rsync_cmd /usr/src/linux/.config "${SYSTEM_DIR}/usr/src/linux/.config" || true
fi

# Sync modprobe and module configs
log_msg ""
log_msg ">>> Syncing module configuration..."
if [[ -d /etc/modprobe.d ]]; then
  rsync_cmd /etc/modprobe.d/ "${SYSTEM_DIR}/etc/modprobe.d/" || true
fi

# Sync systemd configs
log_msg ""
log_msg ">>> Syncing systemd configuration..."
if [[ -d /etc/systemd ]]; then
  rsync_cmd /etc/systemd/ "${SYSTEM_DIR}/etc/systemd/" || true
fi

# Export system metadata
log_msg ""
log_msg ">>> Exporting system metadata..."
mkdir -p "${REPO_ROOT}/docs"

# `emerge-info` is not a command; the information lives behind `emerge --info`.
if command -v emerge &>/dev/null; then
  sudo emerge --info 2>&1 | tee "${REPO_ROOT}/docs/emerge-info.txt" >/dev/null
  log_msg "✓ Exported emerge-info.txt"
fi

if command -v eselect &>/dev/null; then
  sudo eselect profile show 2>&1 | tee "${REPO_ROOT}/docs/eselect-profile.txt" >/dev/null
  log_msg "✓ Exported eselect-profile.txt"
fi

uname -a > "${REPO_ROOT}/docs/uname.txt"
log_msg "✓ Exported uname.txt"

if [[ -f /etc/os-release ]]; then
  cp /etc/os-release "${REPO_ROOT}/docs/os-release.txt"
  log_msg "✓ Exported os-release.txt"
fi

# Summary
log_msg ""
log_msg "========================================"
if [[ "$DRY_RUN" == true ]]; then
  log_msg "Sync complete (dry-run - no changes made)"
else
  log_msg "Sync complete! Configuration captured."
fi
log_msg "Log file: $LOG_FILE"
log_msg "========================================"

