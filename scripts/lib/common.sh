#!/usr/bin/env bash
# ==============================================================================
# scripts/lib/common.sh — shared helpers for the gentoo-ddubs scripts.
#
# Usage, from a script that lives in scripts/:
#
#   SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
#   . "${SCRIPT_DIR}/lib/common.sh" || {
#     printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
#     exit 1
#   }
#
# Everything here is safe to source from a script running
# `set -euo pipefail`, and all output is plain ASCII-free of control
# characters when stdout is not a terminal or NO_COLOR is set.
# ==============================================================================

# Guard against double-sourcing (a script may source this and another helper).
if [ "${_DD_COMMON_LOADED:-}" = "1" ]; then
  # Sourced: return. Executed directly: exit cleanly.
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi
_DD_COMMON_LOADED=1

# ----------------------------------------------------------------------------
# Colours and icons
# ----------------------------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_CYAN=$'\033[36m'
  C_WHITE=$'\033[1;37m'
else
  C_RESET='' C_BOLD='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW=''
  C_BLUE='' C_CYAN='' C_WHITE=''
fi

# Long names kept for scripts that were written against the old inline blocks.
# They are public API consumed by the scripts that source this file, which a
# single-file shellcheck run cannot see.
# shellcheck disable=SC2034
BOLD="$C_BOLD" DIM="$C_DIM" RESET="$C_RESET" CYAN="$C_CYAN"
# shellcheck disable=SC2034
GREEN="$C_GREEN" YELLOW="$C_YELLOW" RED="$C_RED" WHITE="$C_WHITE"

ICON_OK='✔'
ICON_INFO='ℹ'
ICON_WARN='⚠'
ICON_ERR='✖'

# ----------------------------------------------------------------------------
# Output
# ----------------------------------------------------------------------------

# Timestamped progress line, matching the "[HH:MM:SS] msg" format the
# updater/installer scripts have always printed.
say() {
  printf '%s %s[%s]%s %s\n' "$ICON_INFO" "$C_DIM" "$(date +%H:%M:%S)" "$C_RESET" "$*"
}

log_info() { printf '%s %s\n' "${C_BLUE}${ICON_INFO}${C_RESET}" "$*"; }
log_ok() { printf '%s %s\n' "${C_GREEN}${ICON_OK}${C_RESET}" "$*"; }
log_warn() { printf '%s %s\n' "${C_YELLOW}${ICON_WARN}${C_RESET}" "$*" >&2; }
log_err() { printf '%s %s\n' "${C_RED}${ICON_ERR}${C_RESET}" "$*" >&2; }

die() {
  log_err "$*"
  exit 1
}

# Section heading, e.g. step "Step 3: Rebuilding gui-wm/hyprland".
step() {
  printf '\n%s%s%s %s%s\n' "$C_CYAN" "$C_BOLD" "==>" "$*" "$C_RESET"
}

# ----------------------------------------------------------------------------
# Step runner: records failures instead of aborting the run
# ----------------------------------------------------------------------------
RUN_STEPS=0
RUN_FAILURES=0
RUN_STEP_NAMES=()
RUN_FAILED_NAMES=()

run_step() {
  local label="$1"
  shift
  RUN_STEPS=$((RUN_STEPS + 1))
  RUN_STEP_NAMES+=("$label")
  say "Starting ${label} ..."
  if "$@"; then
    log_ok "Done ${label}"
  else
    log_err "Failed ${label} (continuing)"
    RUN_FAILURES=$((RUN_FAILURES + 1))
    RUN_FAILED_NAMES+=("$label")
  fi
  # Always succeed: the caller runs with `set -e`, and recording the failure is
  # the whole point of the runner.
  return 0
}

# Prints the run summary and returns non-zero when a step failed.
run_summary() {
  local name
  printf '\n%s%s Summary %s\n' "$C_BOLD" "$C_BLUE" "$C_RESET"
  say "Steps run: ${RUN_STEPS}"
  say "Failures:  ${RUN_FAILURES}"
  if [ "${#RUN_FAILED_NAMES[@]}" -gt 0 ]; then
    for name in "${RUN_FAILED_NAMES[@]}"; do
      printf '  %s%s%s %s\n' "$C_RED" "$ICON_ERR" "$C_RESET" "$name"
    done
    return 1
  fi
  return 0
}

# ----------------------------------------------------------------------------
# Command and privilege helpers
# ----------------------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

require_cmd() {
  local missing=() c
  for c in "$@"; do
    have "$c" || missing+=("$c")
  done
  if [ "${#missing[@]}" -gt 0 ]; then
    die "missing required command(s): ${missing[*]}"
  fi
}

# Re-exec under sudo when not root, forwarding the original arguments.
need_root() {
  if [ "${EUID:-$(id -u)}" -eq 0 ]; then
    return 0
  fi
  if have sudo; then
    exec sudo -E bash "$0" "$@"
  fi
  die "must run as root (or with sudo available)"
}

# For flows that must not silently re-exec (remote/SSH or interactive ones).
require_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    die "must run as root"
  fi
}

# ----------------------------------------------------------------------------
# Portage helpers
# ----------------------------------------------------------------------------
# Path of a Portage config entry, handling both layouts: a directory of
# snippets (package.mask/foo) and a single file (package.mask).
portage_conf_file() {
  local base="$1" name="$2"
  if [ -d "$base" ]; then
    printf '%s/%s\n' "$base" "$name"
  else
    printf '%s\n' "$base"
  fi
}

pkg_installed() {
  local atom="$1"
  if have qlist; then
    qlist -I "$atom" >/dev/null 2>&1 && return 0
  fi
  if have portageq; then
    portageq match / "$atom" 2>/dev/null | grep -q . && return 0
  fi
  return 1
}

# version_ge ACTUAL REQUIRED -> true when ACTUAL >= REQUIRED (sort -V semantics).
version_ge() {
  local actual="$1" required="$2"
  if [ -z "$actual" ] || [ -z "$required" ]; then
    return 1
  fi
  [ "$(printf '%s\n%s\n' "$required" "$actual" | sort -V | head -n 1)" = "$required" ]
}

# ----------------------------------------------------------------------------
# Portage config files
# ----------------------------------------------------------------------------

# Backups are kept outside /etc/portage on purpose: Portage reads every regular
# file inside a package.* directory, so a "foo.bak-<stamp>" file left next to
# the original would silently become live configuration. Override the location
# with PORTAGE_BACKUP_DIR.
portage_backup_file() {
  local path="$1" dir stamp dest
  [ -e "$path" ] || return 0
  dir="${PORTAGE_BACKUP_DIR:-/root/portage-backups}"
  stamp=$(date +%Y%m%d-%H%M%S)
  install -d -m 0700 "$dir"
  dest="${dir}/$(basename -- "$(dirname -- "$path")")-$(basename -- "$path").bak-${stamp}"
  cp -a "$path" "$dest"
  log_warn "Backed up ${path} -> ${dest}"
}

# Replace a managed Portage config file from stdin. Skips the write (and the
# backup) when the existing contents already match.
portage_write_file() {
  local path="$1" content
  content=$(cat)
  if [ -f "$path" ] && [ "$(cat "$path")" = "$content" ]; then
    log_info "${path} is already up to date; leaving it untouched."
    return 0
  fi
  portage_backup_file "$path"
  printf '%s\n' "$content" > "$path"
}
