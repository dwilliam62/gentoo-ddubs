#!/usr/bin/env bash
set -euo pipefail

# fix-variety.sh
# Diagnostic summary from the working VM:
# - Symptom: `variety` and `lxappearance` crashed with a GTK abort, including:
#   "Unable to load image-loading module ... libpixbufloader_svg.so ... cannot open shared object file"
# - What analysis found:
#   1) gdk-pixbuf loader cache and runtime loader state were inconsistent.
#   2) SVG pixbuf support state was broken enough to trigger a hard GTK abort.
#   3) WebP/AVIF wallpaper files were skipped due to missing pixbuf loaders.
# - What fixed the hard crash:
#   1) Reinstall `x11-libs/gdk-pixbuf` and `gnome-base/librsvg`.
#   2) Refresh gdk-pixbuf, MIME, and icon caches.
#   3) Install WebP/AVIF loader support:
#      - `gui-libs/gdk-pixbuf-loader-webp`
#      - `media-libs/libavif` with `USE=gdk-pixbuf`
# - Notes:
#   - Optional warnings may still appear (e.g. Variety Slideshow not installed,
#     libayatana deprecation warnings). Those were non-fatal.

log() {
  printf '[fix-variety] %s\n' "$*"
}

warn() {
  printf '[fix-variety] WARN: %s\n' "$*" >&2
}

die() {
  printf '[fix-variety] ERROR: %s\n' "$*" >&2
  exit 1
}

need_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    return
  fi
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  fi
  die "must run as root (or with sudo available)"
}

require_cmds() {
  local missing=()
  local c
  for c in emerge gdk-pixbuf-query-loaders; do
    if ! command -v "$c" >/dev/null 2>&1; then
      missing+=("$c")
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    die "required commands not found: ${missing[*]}"
  fi
}

detect_pixbuf_paths() {
  LOADER_DIR="$(pkg-config --variable=gdk_pixbuf_moduledir gdk-pixbuf-2.0 2>/dev/null || true)"
  LOADER_CACHE="$(pkg-config --variable=gdk_pixbuf_cache_file gdk-pixbuf-2.0 2>/dev/null || true)"

  if [[ -z "${LOADER_DIR}" ]]; then
    LOADER_DIR="/usr/lib64/gdk-pixbuf-2.0/2.10.0/loaders"
  fi
  if [[ -z "${LOADER_CACHE}" ]]; then
    LOADER_CACHE="${LOADER_DIR%/loaders}/loaders.cache"
  fi
}

print_loader_diag() {
  local loader

  log "gdk-pixbuf loader dir: ${LOADER_DIR}"
  log "gdk-pixbuf loader cache: ${LOADER_CACHE}"

  if [[ ! -d "${LOADER_DIR}" ]]; then
    warn "loader dir missing: ${LOADER_DIR}"
  fi

  for loader in \
    libpixbufloader_svg.so \
    libpixbufloader-webp.so \
    libpixbufloader-avif.so; do
    if [[ -f "${LOADER_DIR}/${loader}" ]]; then
      log "present: ${loader}"
    else
      warn "missing: ${LOADER_DIR}/${loader}"
    fi
  done

  if [[ -f "${LOADER_CACHE}" ]]; then
    if grep -q 'libpixbufloader_svg\.so' "${LOADER_CACHE}"; then
      log "cache entry found: libpixbufloader_svg.so"
    else
      warn "cache entry missing: libpixbufloader_svg.so"
    fi
    if grep -q 'libpixbufloader-webp\.so' "${LOADER_CACHE}"; then
      log "cache entry found: libpixbufloader-webp.so"
    else
      warn "cache entry missing: libpixbufloader-webp.so"
    fi
    if grep -q 'libpixbufloader-avif\.so' "${LOADER_CACHE}"; then
      log "cache entry found: libpixbufloader-avif.so"
    else
      warn "cache entry missing: libpixbufloader-avif.so"
    fi
  else
    warn "loader cache file missing: ${LOADER_CACHE}"
  fi
}

refresh_caches() {
  log "Refreshing gdk-pixbuf loader cache..."
  gdk-pixbuf-query-loaders --update-cache

  if command -v update-mime-database >/dev/null 2>&1; then
    log "Refreshing MIME cache..."
    update-mime-database /usr/share/mime
  else
    warn "update-mime-database not found; skipping MIME cache refresh"
  fi

  if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    if [[ -d /usr/share/icons/hicolor ]]; then
      log "Refreshing icon cache: /usr/share/icons/hicolor"
      gtk-update-icon-cache -f /usr/share/icons/hicolor
    fi
    if [[ -d /usr/share/icons/a-candy-beauty-icon-theme ]]; then
      log "Refreshing icon cache: /usr/share/icons/a-candy-beauty-icon-theme"
      gtk-update-icon-cache -f /usr/share/icons/a-candy-beauty-icon-theme
    fi
  else
    warn "gtk-update-icon-cache not found; skipping icon cache refresh"
  fi
}

main() {
  need_root "$@"
  require_cmds
  detect_pixbuf_paths

  log "Pre-fix diagnostics:"
  print_loader_diag

  log "Reinstalling core GTK pixbuf/SVG packages..."
  emerge -1v x11-libs/gdk-pixbuf gnome-base/librsvg

  log "Installing WebP and AVIF pixbuf support..."
  USE="gdk-pixbuf" emerge -1v gui-libs/gdk-pixbuf-loader-webp media-libs/libavif

  refresh_caches

  log "Post-fix diagnostics:"
  print_loader_diag

  log "Done. Optional verification:"
  log "  timeout 15s variety"
  log "  timeout 15s lxappearance"
  log "If this still fails, share this script and full output with Warp."
}

main "$@"
