#!/usr/bin/env bash
# Installer for waybar-weather across non-NixOS Linux distros.
# - Compiles from source and installs binary to /usr/bin/waybar-weather
# - Requires Go >= 1.25 and git
# - On Arch, you may prefer: yay -S weather-waybar
# - NixOS is intentionally not supported here; use a separate script.

set -Eeuo pipefail

MIN_GO_MAJOR=1
MIN_GO_MINOR=25
REPO_URL="https://github.com/wneessen/waybar-weather.git"
APP_NAME="waybar-weather"
INSTALL_PATH="/usr/bin/${APP_NAME}"

log() { echo "[${APP_NAME}] $*"; }
warn() { echo "[${APP_NAME}] WARN: $*" >&2; }
die() { echo "[${APP_NAME}] ERROR: $*" >&2; exit 1; }

need_cmd() { command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"; }

require_root_or_sudo() {
  if [[ $EUID -eq 0 ]]; then
    SUDO=""
  else
    need_cmd sudo
    SUDO="sudo"
  fi
}

check_nixos() {
  if [[ -r /etc/os-release ]] && grep -qi '^ID=nixos' /etc/os-release; then
    die "NixOS detected. Please use a dedicated NixOS script for installing ${APP_NAME}."
  fi
}

check_go_version() {
  need_cmd go
  local raw token v major minor

  # Prefer a stable machine-parseable source if available
  token=$(go env GOVERSION 2>/dev/null || true)

  if [[ -n "$token" ]]; then
    # e.g. token="go1.25.5"
    v=${token#go}
  else
    raw=$(go version 2>/dev/null || true)
    [[ -n "$raw" ]] || die "Unable to determine Go version"
    # Extract the first occurrence of go<major>.<minor> ignoring any distro suffixes
    token=$(printf '%s' "$raw" | grep -oE 'go[0-9]+\.[0-9]+' | head -n1 || true)
    [[ -n "$token" ]] || die "Unrecognized Go version output: $raw"
    v=${token#go}
  fi

  major=${v%%.*}
  minor=${v#*.}; minor=${minor%%.*}

  [[ $major =~ ^[0-9]+$ && $minor =~ ^[0-9]+$ ]] || die "Unrecognized Go version fields: major=$major minor=$minor (from $v)"

  if (( major > MIN_GO_MAJOR || (major == MIN_GO_MAJOR && minor >= MIN_GO_MINOR) )); then
    return 0
  else
    die "Go ${MIN_GO_MAJOR}.${MIN_GO_MINOR}+ required, found ${major}.${minor} (${raw:-$token})"
  fi
}

maybe_note_arch() {
  if [[ -r /etc/os-release ]] && grep -qi '^ID=arch' /etc/os-release && command -v yay >/dev/null 2>&1; then
    warn "Arch Linux detected. You can install via: yay -S weather-waybar. Proceeding to build from source."
  fi
}

main() {
  check_nixos
  need_cmd git
  check_go_version
  maybe_note_arch
  require_root_or_sudo

  local tmp
  tmp=$(mktemp -d)
  trap 'rm -rf "${tmp}"' EXIT

  log "Cloning ${REPO_URL}"
  git clone --depth 1 "${REPO_URL}" "${tmp}/${APP_NAME}" >/dev/null 2>&1 || die "git clone failed"

  cd "${tmp}/${APP_NAME}"

  log "Downloading and verifying Go modules"
  go mod download >/dev/null 2>&1 || die "go mod download failed"
  go mod verify >/dev/null 2>&1 || die "go mod verify failed"

  log "Building ${APP_NAME}"
  GOFLAGS="${GOFLAGS:-}" CGO_ENABLED=0 go build -trimpath -ldflags "-s -w" -o "${APP_NAME}" ./cmd/${APP_NAME} || die "go build failed"

  log "Installing to ${INSTALL_PATH}"
  ${SUDO} install -D -m 0755 "${APP_NAME}" "${INSTALL_PATH}" || die "install failed"

  if "${INSTALL_PATH}" -h >/dev/null 2>&1; then
    log "Installed ${APP_NAME} to ${INSTALL_PATH}"
  else
    warn "${APP_NAME} installed, but a basic self-check did not run."
  fi
}

main "$@"
