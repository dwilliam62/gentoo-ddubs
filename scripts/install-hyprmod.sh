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
# Usage:
#   install-hyprmod.sh [--check-only]
#
#   --check-only  Report the edgets repository and keyword state, and preview
#                 the hyprmod merge without changing anything.
#

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

KEYWORDS_BASE="/etc/portage/package.accept_keywords"
KEYWORD_FILE_NAME="edgets"

print_usage() {
  cat <<'EOF'
Usage: install-hyprmod.sh [--check-only]

  --check-only  Report the edgets repository and keyword state, and preview
                the hyprmod merge without changing anything.
  -h, --help    Show this help and exit.

With no arguments the full installation runs.
EOF
}

edgets_repo_path() {
  portageq get_repo_path / edgets 2>/dev/null || true
}

edgets_enabled() {
  local repo_path
  repo_path="$(edgets_repo_path)"
  [ -n "$repo_path" ]
}

edgets_synced() {
  local repo_path
  repo_path="$(edgets_repo_path)"
  [ -n "$repo_path" ] && [ -d "${repo_path}/metadata" ]
}

keyword_file_path() {
  if [ -d "$KEYWORDS_BASE" ]; then
    printf '%s/%s\n' "$KEYWORDS_BASE" "$KEYWORD_FILE_NAME"
  elif [ -e "$KEYWORDS_BASE" ]; then
    printf '%s\n' "$KEYWORDS_BASE"
  else
    printf '%s/%s\n' "$KEYWORDS_BASE" "$KEYWORD_FILE_NAME"
  fi
}

keyword_pattern() {
  printf '^[[:space:]]*[*]/[*]::edgets[[:space:]]+~%s([[:space:]]|$)\n' "$TARGET_ARCH"
}

setup_edgets_repository() {
  log_info "Setting up edgets repository..."

  # eselect-repository ships as an eselect module; probe the module, and make
  # sure the install actually produced a usable eselect afterwards.
  if ! have eselect || ! eselect repository list >/dev/null 2>&1; then
    log_info "eselect-repository not usable. Installing app-eselect/eselect-repository..."
    # --oneshot: overlay tooling, not something to select into @world.
    # --ask needs an answer on stdin, so skip it on non-interactive runs.
    if [ -t 0 ]; then
      if ! emerge --ask --oneshot --noreplace app-eselect/eselect-repository; then
        log_err "Failed to install eselect-repository"
        return 1
      fi
    elif ! emerge --oneshot --noreplace app-eselect/eselect-repository; then
      log_err "Failed to install eselect-repository"
      return 1
    fi
    if ! eselect repository list >/dev/null 2>&1; then
      log_err "eselect repository is still unavailable; re-emerge app-eselect/eselect-repository."
      return 1
    fi
  fi

  if edgets_enabled; then
    log_ok "edgets repository is already enabled."
  else
    log_info "Enabling edgets repository..."
    if ! eselect repository enable edgets; then
      log_err "Could not enable the edgets repository."
      return 1
    fi
    if ! edgets_enabled; then
      log_err "edgets was enabled but is not present in repos.conf."
      return 1
    fi
  fi

  log_info "Syncing edgets repository..."
  if have emaint; then
    if ! emaint sync -r edgets; then
      log_err "Syncing edgets failed; hyprmod cannot be installed from the overlay."
      return 1
    fi
  else
    log_warn "emaint not found; falling back to a full emerge --sync."
    if ! emerge --sync; then
      log_err "emerge --sync failed."
      return 1
    fi
  fi

  if ! edgets_synced; then
    log_err "edgets metadata is missing after sync; run 'emaint sync -r edgets' and retry."
    return 1
  fi

  log_ok "edgets repository is ready."
}

setup_package_keywords() {
  log_info "Configuring package keywords for edgets..."

  # Prefer the directory layout. If the path already exists as a single file,
  # portage_conf_file returns that file and the entry is appended to it.
  if [ ! -e "$KEYWORDS_BASE" ]; then
    install -d "$KEYWORDS_BASE"
  fi

  local keywords_file
  keywords_file="$(portage_conf_file "$KEYWORDS_BASE" "$KEYWORD_FILE_NAME")"

  if [ -f "$keywords_file" ] && grep -qE "$(keyword_pattern)" "$keywords_file"; then
    log_ok "edgets keyword entry already exists in ${keywords_file}"
    return 0
  fi

  log_info "Adding '${KEYWORDS_ENTRY}' to ${keywords_file}..."
  printf '%s\n' "$KEYWORDS_ENTRY" >>"$keywords_file"
  log_ok "Keywords configured successfully."
}

install_hyprmod() {
  log_info "Installing hyprmod from edgets repository..."

  # --ask needs an answer on stdin; skip it on non-interactive runs.
  if [ -t 0 ]; then
    if ! emerge -av gui-apps/hyprmod; then
      log_err "hyprmod installation failed or was cancelled."
      return 1
    fi
  elif ! emerge -v gui-apps/hyprmod; then
    log_err "hyprmod installation failed."
    return 1
  fi

  if ! have hyprmod; then
    log_err "emerge finished but no hyprmod executable is in PATH."
    return 1
  fi

  log_ok "hyprmod installed successfully."
}

run_check() {
  step "Check: edgets repository"
  if edgets_enabled; then
    log_ok "edgets is enabled at $(edgets_repo_path)"
    if edgets_synced; then
      log_ok "edgets metadata is present."
    else
      log_warn "edgets is enabled but not synced; run 'emaint sync -r edgets'."
    fi
  else
    log_warn "edgets is not enabled; the full run would enable and sync it."
  fi

  step "Check: package.accept_keywords"
  local keywords_file
  keywords_file="$(keyword_file_path)"
  if [ -f "$keywords_file" ] && grep -qE "$(keyword_pattern)" "$keywords_file"; then
    log_ok "'${KEYWORDS_ENTRY}' is present in ${keywords_file}"
  else
    log_info "Would add '${KEYWORDS_ENTRY}' to ${keywords_file}"
    if [ ! -w "$(dirname "$keywords_file")" ] && [ ! -w "$keywords_file" ]; then
      log_warn "Writing needs root; the full run re-execs through sudo."
    fi
  fi

  step "Check: hyprmod merge preview"
  if edgets_enabled && edgets_synced; then
    emerge -p -v gui-apps/hyprmod ||
      log_warn "Preview failed; the overlay metadata may be stale."
  else
    log_warn "Skipping the preview until the edgets repository is enabled and synced."
  fi

  log_ok "Check-only complete; no changes were made."
}

main() {
  local check_only=false

  if [ "$#" -gt 1 ]; then
    log_err "expected at most one argument (try --help)"
    return 1
  fi

  case "${1:-}" in
    -h | --help)
      print_usage
      return 0
      ;;
    --check-only) check_only=true ;;
    "") ;;
    *)
      log_err "unknown argument: $1 (try --help)"
      return 1
      ;;
  esac

  if ! have emerge; then
    log_err "emerge not found; this script is for Gentoo only."
    return 1
  fi

  TARGET_ARCH="$(portageq envvar ARCH 2>/dev/null || true)"
  if [ -z "$TARGET_ARCH" ]; then
    log_err "Could not determine ARCH with portageq."
    return 1
  fi
  KEYWORDS_ENTRY="*/*::edgets ~${TARGET_ARCH}"

  if [ "$check_only" = true ]; then
    run_check
    return 0
  fi

  need_root "$@"

  log_info "Starting hyprmod installation for Gentoo..."

  setup_edgets_repository || return 1
  setup_package_keywords || return 1
  install_hyprmod || return 1

  log_ok "Installation complete! Launch hyprmod from your application menu or with: hyprmod"
}

main "$@"
