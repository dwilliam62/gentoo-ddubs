#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_OXWM_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | awk -F: '{print $6}' || true)"
if [[ -z "${TARGET_HOME}" ]]; then
  TARGET_HOME="${HOME}"
fi

OXWM_REPO_URL="${OXWM_REPO_URL:-https://github.com/tonybanters/oxwm}"
OXWM_SOURCE_DIR="${OXWM_SOURCE_DIR:-${TARGET_HOME}/src/oxwm}"
OXWM_CONFIG_DIR="${OXWM_CONFIG_DIR:-${TARGET_HOME}/.config/oxwm}"
OXWM_DESKTOP_DIR="${OXWM_DESKTOP_DIR:-/usr/share/xsessions}"
OXWM_APPLICATIONS_DIR="${OXWM_APPLICATIONS_DIR:-/usr/share/applications}"

ZIG_REQUIRED_VERSION="${ZIG_REQUIRED_VERSION:-0.16.0}"
ZIG_INSTALL_ROOT="${ZIG_INSTALL_ROOT:-/opt/zig}"
ZIG_TOOLCHAIN_DIR="${ZIG_INSTALL_ROOT}/${ZIG_REQUIRED_VERSION}"
ZIG_TOOLCHAIN_BIN="${ZIG_TOOLCHAIN_DIR}/zig"
ZIG_COMPAT_SYMLINK="${ZIG_COMPAT_SYMLINK:-/usr/local/bin/zig-${ZIG_REQUIRED_VERSION}}"

UPDATE_ONLY=false
SKIP_DEPS=false

log() {
  printf '[oxwm-install] %s\n' "$*"
}

warn() {
  printf '[oxwm-install] WARN: %s\n' "$*" >&2
}

die() {
  printf '[oxwm-install] ERROR: %s\n' "$*" >&2
  exit 1
}

print_help() {
  cat <<'EOF'
Usage:
  bash oxwm/scripts/install.sh [--update-only] [--skip-deps]

Options:
  --update-only  Fail if source directory does not already exist.
  --skip-deps    Skip package-manager dependency installation.
  --help         Show this help.

Environment overrides:
  OXWM_REPO_URL, OXWM_SOURCE_DIR, OXWM_CONFIG_DIR, OXWM_DESKTOP_DIR, OXWM_APPLICATIONS_DIR
  ZIG_REQUIRED_VERSION, ZIG_INSTALL_ROOT, ZIG_COMPAT_SYMLINK, ZIG_LOCAL_TARBALL
EOF
}

for arg in "$@"; do
  case "${arg}" in
    --update-only) UPDATE_ONLY=true ;;
    --skip-deps) SKIP_DEPS=true ;;
    --help|-h)
      print_help
      exit 0
      ;;
    *)
      die "Unknown argument: ${arg}"
      ;;
  esac
done

run_privileged() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    command -v sudo >/dev/null 2>&1 || die "sudo is required for privileged actions"
    sudo "$@"
  fi
}

run_as_target_user() {
  if [[ "${EUID}" -eq 0 && -n "${SUDO_USER:-}" ]]; then
    sudo -u "${TARGET_USER}" "$@"
  else
    "$@"
  fi
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

detect_pkg_manager() {
  if command -v emerge >/dev/null 2>&1; then
    printf '%s\n' "emerge"
    return
  fi
  if command -v apt-get >/dev/null 2>&1; then
    printf '%s\n' "apt-get"
    return
  fi
  if command -v dnf >/dev/null 2>&1; then
    printf '%s\n' "dnf"
    return
  fi
  if command -v pacman >/dev/null 2>&1; then
    printf '%s\n' "pacman"
    return
  fi
  if command -v zypper >/dev/null 2>&1; then
    printf '%s\n' "zypper"
    return
  fi
  printf '%s\n' "unknown"
}

ensure_x11_dependencies() {
  local pm
  pm="$(detect_pkg_manager)"
  case "${pm}" in
    emerge)
      log "Ensuring OxWM X11 dependencies via emerge"
      run_privileged emerge -n \
        x11-libs/libX11 \
        x11-libs/libXinerama \
        x11-libs/libXft \
        media-libs/fontconfig \
        media-libs/freetype \
        x11-apps/xrandr
      ;;
    apt-get)
      log "Ensuring OxWM X11 dependencies via apt-get"
      run_privileged apt-get update
      run_privileged apt-get install -y --no-install-recommends \
        libx11-dev \
        libxinerama-dev \
        libxft-dev \
        libfontconfig1-dev \
        libfreetype6-dev \
        x11-xserver-utils
      ;;
    dnf)
      log "Ensuring OxWM X11 dependencies via dnf"
      run_privileged dnf install -y \
        libX11-devel \
        libXinerama-devel \
        libXft-devel \
        fontconfig-devel \
        freetype-devel \
        xrandr
      ;;
    pacman)
      log "Ensuring OxWM X11 dependencies via pacman"
      run_privileged pacman --noconfirm --needed -S \
        libx11 \
        libxinerama \
        libxft \
        fontconfig \
        freetype2 \
        xorg-xrandr
      ;;
    zypper)
      log "Ensuring OxWM X11 dependencies via zypper"
      run_privileged zypper --non-interactive install \
        libX11-devel \
        libXinerama-devel \
        libXft-devel \
        fontconfig-devel \
        freetype2-devel \
        xrandr
      ;;
    *)
      warn "Unknown package manager; skipping automatic X11 dependency install"
      ;;
  esac
}

zig_download_triplet() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "${os}" in
    linux) ;;
    *)
      die "Unsupported OS for automatic Zig install: ${os}"
      ;;
  esac

  case "${arch}" in
    x86_64|amd64) arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    riscv64) arch="riscv64" ;;
    *)
      die "Unsupported architecture for automatic Zig install: ${arch}"
      ;;
  esac

  printf '%s-%s\n' "${arch}" "${os}"
}
zig_archive_name() {
  printf 'zig-%s-%s.tar.xz\n' "$(zig_download_triplet)" "${ZIG_REQUIRED_VERSION}"
}
zig_download_url() {
  printf 'https://ziglang.org/download/%s/%s\n' "${ZIG_REQUIRED_VERSION}" "$(zig_archive_name)"
}
zig_local_archive_path() {
  printf '%s/%s\n' "${LOCAL_OXWM_DIR}" "$(zig_archive_name)"
}

install_zig_toolchain() {
  local archive_path local_cache_path archive_source url tmp_dir extracted_dir top_dir download_tmp
  local_cache_path="$(zig_local_archive_path)"
  archive_path="${ZIG_LOCAL_TARBALL:-${local_cache_path}}"
  url="$(zig_download_url)"
  tmp_dir="$(mktemp -d)"

  if [[ -f "${archive_path}" ]]; then
    archive_source="${archive_path}"
    log "Installing Zig ${ZIG_REQUIRED_VERSION} from local tarball ${archive_source}"
  else
    require_cmd curl
    warn "Local Zig tarball not found at ${archive_path}; downloading fallback from ${url}"
    download_tmp="${tmp_dir}/$(zig_archive_name)"
    if ! curl -fsSL "${url}" -o "${download_tmp}"; then
      die "Failed to download Zig from ${url}"
    fi
    archive_source="${download_tmp}"

    if mkdir -p "$(dirname -- "${local_cache_path}")" && cp -f "${archive_source}" "${local_cache_path}"; then
      log "Cached downloaded Zig tarball at ${local_cache_path}"
    else
      warn "Unable to cache downloaded Zig tarball at ${local_cache_path}"
    fi
  fi

  top_dir="$(tar -tf "${archive_source}" | head -n 1 | cut -d/ -f1 || true)"
  tar -xf "${archive_source}" -C "${tmp_dir}"

  extracted_dir="${tmp_dir}/${top_dir}"
  if [[ ! -x "${extracted_dir}/zig" ]]; then
    extracted_dir="$(find "${tmp_dir}" -mindepth 1 -maxdepth 1 -type d -name "zig-*${ZIG_REQUIRED_VERSION}*" | head -n 1 || true)"
  fi
  [[ -n "${extracted_dir}" && -x "${extracted_dir}/zig" ]] || die "Zig archive ${archive_source} is missing expected zig binary"

  run_privileged mkdir -p "${ZIG_INSTALL_ROOT}"
  run_privileged rm -rf "${ZIG_TOOLCHAIN_DIR}"
  run_privileged mv "${extracted_dir}" "${ZIG_TOOLCHAIN_DIR}"
  run_privileged ln -sfn "${ZIG_TOOLCHAIN_BIN}" "${ZIG_COMPAT_SYMLINK}"

  rm -rf "${tmp_dir}"
}

ensure_zig_toolchain() {
  if command -v zig >/dev/null 2>&1; then
    local system_zig_version
    system_zig_version="$(zig version || true)"
    if [[ "${system_zig_version}" == "${ZIG_REQUIRED_VERSION}" ]]; then
      ZIG_BIN="$(command -v zig)"
      log "Using system zig (${ZIG_BIN}) version ${system_zig_version}"
      return
    fi
    warn "System zig version is ${system_zig_version}; OxWM build will use ${ZIG_REQUIRED_VERSION}"
  fi

  if [[ -x "${ZIG_TOOLCHAIN_BIN}" ]]; then
    local local_zig_version
    local_zig_version="$("${ZIG_TOOLCHAIN_BIN}" version || true)"
    if [[ "${local_zig_version}" == "${ZIG_REQUIRED_VERSION}" ]]; then
      ZIG_BIN="${ZIG_TOOLCHAIN_BIN}"
      log "Using local Zig toolchain ${ZIG_BIN}"
      return
    fi
  fi

  install_zig_toolchain
  ZIG_BIN="${ZIG_TOOLCHAIN_BIN}"
}

sync_oxwm_source() {
  if [[ -d "${OXWM_SOURCE_DIR}/.git" ]]; then
    log "Updating existing OxWM source at ${OXWM_SOURCE_DIR}"
    run_as_target_user git -C "${OXWM_SOURCE_DIR}" fetch --all --tags
    run_as_target_user git -C "${OXWM_SOURCE_DIR}" pull --ff-only
    return
  fi

  if [[ "${UPDATE_ONLY}" == true ]]; then
    die "--update-only set but ${OXWM_SOURCE_DIR} is not an OxWM git repo"
  fi

  if [[ -e "${OXWM_SOURCE_DIR}" ]]; then
    die "${OXWM_SOURCE_DIR} exists but is not an OxWM git repository"
  fi

  log "Cloning OxWM source from ${OXWM_REPO_URL} into ${OXWM_SOURCE_DIR}"
  run_as_target_user mkdir -p "$(dirname -- "${OXWM_SOURCE_DIR}")"
  run_as_target_user git clone "${OXWM_REPO_URL}" "${OXWM_SOURCE_DIR}"
}

build_oxwm() {
  local built_bin
  log "Building OxWM with zig ${ZIG_REQUIRED_VERSION}"
  run_as_target_user env OXWM_SOURCE_DIR="${OXWM_SOURCE_DIR}" ZIG_BIN="${ZIG_BIN}" bash -c 'cd "${OXWM_SOURCE_DIR}" && "${ZIG_BIN}" build -Doptimize=ReleaseFast'

  built_bin="${OXWM_SOURCE_DIR}/zig-out/bin/oxwm"
  [[ -x "${built_bin}" ]] || die "Expected built binary missing at ${built_bin}"

  run_privileged install -Dm755 "${built_bin}" /usr/local/bin/oxwm
  log "Installed /usr/local/bin/oxwm"
}

deploy_local_files() {
  [[ -f "${LOCAL_OXWM_DIR}/config.lua" ]] || die "Missing ${LOCAL_OXWM_DIR}/config.lua"
  [[ -f "${LOCAL_OXWM_DIR}/oxwm.lua" ]] || die "Missing ${LOCAL_OXWM_DIR}/oxwm.lua"
  [[ -f "${LOCAL_OXWM_DIR}/oxwm-session" ]] || die "Missing ${LOCAL_OXWM_DIR}/oxwm-session"
  [[ -f "${LOCAL_OXWM_DIR}/oxwm-parser" ]] || die "Missing ${LOCAL_OXWM_DIR}/oxwm-parser"
  [[ -f "${LOCAL_OXWM_DIR}/oxwm.desktop" ]] || die "Missing ${LOCAL_OXWM_DIR}/oxwm.desktop"

  run_as_target_user install -Dm644 "${LOCAL_OXWM_DIR}/config.lua" "${OXWM_CONFIG_DIR}/config.lua"
  run_as_target_user install -Dm644 "${LOCAL_OXWM_DIR}/oxwm.lua" "${OXWM_CONFIG_DIR}/oxwm.lua"
  run_privileged install -Dm755 "${LOCAL_OXWM_DIR}/oxwm-session" /usr/local/bin/oxwm-session
  run_privileged install -Dm755 "${LOCAL_OXWM_DIR}/oxwm-parser" /usr/local/bin/oxwm-parser
  run_privileged install -Dm644 "${LOCAL_OXWM_DIR}/oxwm.desktop" "${OXWM_DESKTOP_DIR}/oxwm.desktop"
  if [[ "${OXWM_APPLICATIONS_DIR}" != "${OXWM_DESKTOP_DIR}" ]]; then
    run_privileged install -Dm644 "${LOCAL_OXWM_DIR}/oxwm.desktop" "${OXWM_APPLICATIONS_DIR}/oxwm.desktop"
  fi

  log "Installed config files to ${OXWM_CONFIG_DIR}"
  log "Installed helper scripts to /usr/local/bin"
  log "Installed session desktop file to ${OXWM_DESKTOP_DIR}/oxwm.desktop"
  if [[ "${OXWM_APPLICATIONS_DIR}" != "${OXWM_DESKTOP_DIR}" ]]; then
    log "Installed application desktop file to ${OXWM_APPLICATIONS_DIR}/oxwm.desktop"
  fi
}

main() {
  require_cmd git
  require_cmd tar

  if [[ "${SKIP_DEPS}" == false ]]; then
    ensure_x11_dependencies
  else
    log "Skipping dependency installation (--skip-deps)"
  fi

  ensure_zig_toolchain
  sync_oxwm_source
  build_oxwm
  deploy_local_files

  log "Done."
}

main
