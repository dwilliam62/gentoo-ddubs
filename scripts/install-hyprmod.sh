#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Gentoo hyprmod installer with edgets repo setup
#

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

KEYWORDS_BASE="/etc/portage/package.accept_keywords"
KEYWORDS_ENTRY="*/*::edgets ~amd64"

setup_edgets_repository() {
  log_info "Setting up edgets repository..."

  # eselect-repository ships as an eselect module; probe the module, and make
  # sure the install actually produced a usable eselect afterwards.
  if ! have eselect || ! eselect repository list >/dev/null 2>&1; then
    log_info "eselect-repository not usable. Installing app-eselect/eselect-repository..."
    if ! sudo emerge --ask app-eselect/eselect-repository; then
      log_err "Failed to install eselect-repository"
      return 1
    fi
    if ! have eselect; then
      log_err "eselect is still unavailable after installation."
      return 1
    fi
  fi

  log_info "Enabling edgets repository..."
  if ! sudo eselect repository enable edgets; then
    log_warn "Could not enable the edgets repository; it may already be configured."
  fi

  log_info "Syncing portage tree..."
  if have emaint; then
    if ! sudo emaint sync -r edgets; then
      log_warn "Syncing edgets failed; continuing with the existing metadata."
    fi
  elif ! sudo emerge --sync; then
    log_warn "emerge --sync failed; continuing with the existing tree."
  fi

  log_ok "Edgets repository setup complete."
}

setup_package_keywords() {
  log_info "Configuring package keywords for edgets..."

  local keywords_file
  keywords_file="$(portage_conf_file "$KEYWORDS_BASE" edgets)"
  install -d "$(dirname "$keywords_file")"

  if [ -f "$keywords_file" ] && grep -qF -- "$KEYWORDS_ENTRY" "$keywords_file"; then
    log_ok "edgets keyword entry already exists in ${keywords_file}"
    return 0
  fi

  log_info "Adding edgets keyword entry to ${keywords_file}..."
  printf '%s\n' "$KEYWORDS_ENTRY" | sudo tee -a "$keywords_file" >/dev/null
  log_ok "Keywords configured successfully."
}

install_hyprmod() {
  log_info "Installing hyprmod from edgets repository... (confirm with 'y' if asked)"

  if ! sudo emerge -a hyprmod; then
    log_err "hyprmod installation failed"
    return 1
  fi

  log_ok "hyprmod installed successfully."
}

print_usage() {
  cat <<'EOF'
Usage: install-hyprmod.sh [--help|-h]

Enable the edgets overlay, accept its keywords, and install hyprmod.
With no arguments the full installation runs.
EOF
}

main() {
  case "${1:-}" in
    -h | --help)
      print_usage
      return 0
      ;;
    "") ;;
    *)
      log_err "unknown argument: $1 (try --help)"
      return 1
      ;;
  esac

  log_info "Starting hyprmod installation for Gentoo..."

  if ! have emerge; then
    log_err "emerge not found; this script is for Gentoo only."
    return 1
  fi

  setup_edgets_repository || return 1
  setup_package_keywords || return 1
  install_hyprmod || return 1

  log_ok "Installation complete!"
}

main "$@"
