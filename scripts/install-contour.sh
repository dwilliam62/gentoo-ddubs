#!/usr/bin/env bash
# ==============================================================================
# Script: install-contour.sh
# Description: Installs gui-apps/contour on Gentoo Linux with all necessary
#              overlay configurations, dependency masks, and USE flags.
# Usage:
#   bash install-contour.sh [--check-only]
#
#   --check-only  Write the Portage configuration, report Qt USE-flag
#                 overrides, and preview the emerge plan with --pretend.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

print_usage() {
  cat <<'EOF'
Usage: install-contour.sh [--check-only]

  --check-only  Write the Portage configuration, report Qt USE-flag
                overrides, and preview the emerge plan with --pretend.
  --help        Show this help and exit.
EOF
}

CHECK_ONLY=false
for arg in "$@"; do
  case "$arg" in
    --check-only) CHECK_ONLY=true ;;
    -h|--help) print_usage; exit 0 ;;
    *) die "Unknown argument: $arg (try --help)" ;;
  esac
done

need_root "$@"

# The three Portage config files below are managed by this script through
# portage_write_file() from scripts/lib/common.sh: it backs the previous
# contents up outside /etc/portage and skips the write when nothing changed
# (docs/fix-contour-plan.md, "What the script does not handle" row 8).

# Warn when a managed file already holds entries the fresh contents drop.
# Host-specific additions belong in a separate snippet so a rerun cannot erase
# them (qtbase[vulkan] for an installed gui-apps/quickshell, for example).
warn_drift_from_managed() {
  local path="$1" content="$2" line extra=()
  [ -f "$path" ] || return 0
  while IFS= read -r line; do
    line=${line%%#*}
    line=$(printf '%s\n' "$line" | tr -s '[:space:]' ' ' | sed -e 's/^ //' -e 's/ $//')
    [ -n "$line" ] || continue
    printf '%s\n' "$content" | grep -qxF -- "$line" || extra+=("$line")
  done <"$path"
  if [ "${#extra[@]}" -eq 0 ]; then
    return 0
  fi
  log_warn "Existing ${path} has entries this script does not write:"
  printf '    %s\n' "${extra[@]}" >&2
  log_warn "Keep host-specific entries in a separate file (for example ${path}-extra); a rerun would drop them here."
}

if [ "$CHECK_ONLY" = false ]; then
  step "Step 1: Ensuring eselect-repository is installed..."
  # eselect-repository is an eselect module, not a standalone binary, so probe the
  # module through eselect itself instead of looking for a command of that name.
  if ! have eselect || ! eselect repository list >/dev/null 2>&1; then
    # --oneshot: this is a tool the script needs, not something the user asked
    # to select into @world (docs/fix-contour-plan.md, row 9).
    emerge --oneshot --noreplace app-eselect/eselect-repository ||
      die "Failed to install app-eselect/eselect-repository."
  fi

  step "Step 2: Enabling and syncing the 'guru' overlay..."
  eselect repository enable guru ||
    log_warn "Could not enable the guru overlay; it may already be configured."
  if have emaint; then
    emaint sync -r guru || log_warn "Syncing guru failed; continuing with existing metadata."
  else
    log_warn "emaint not found; skipping guru sync."
  fi
else
  say "Check-only: skipping Steps 1-2 (overlay setup)."
fi

step "Step 3: Configuring package.accept_keywords for Contour and GURU dependencies..."
mkdir -p /etc/portage/package.accept_keywords
keywords_file=/etc/portage/package.accept_keywords/contour
keywords_content=$(cat << 'EOF'
gui-apps/contour ~amd64
media-libs/libunicode ~amd64
dev-cpp/boxed-cpp ~amd64
dev-cpp/reflection-cpp ~amd64
EOF
)
warn_drift_from_managed "$keywords_file" "$keywords_content"
printf '%s\n' "$keywords_content" | portage_write_file "$keywords_file"

step "Step 4: Masking libunicode >= 0.8.0 (fixes Contour 0.6.1 'breakable' build error)..."
mask_dir="/etc/portage/package.mask"
mkdir -p "$mask_dir"
mask_file="${mask_dir}/libunicode"
mask_content=$(cat << 'EOF'
# Contour 0.6.1 is incompatible with libunicode-0.8.0+ due to grapheme_segmenter API change
>=media-libs/libunicode-0.8.0
EOF
)
warn_drift_from_managed "$mask_file" "$mask_content"
printf '%s\n' "$mask_content" | portage_write_file "$mask_file"

step "Step 5: Configuring USE flags for Qt and Contour dependencies..."
mkdir -p /etc/portage/package.use
use_file=/etc/portage/package.use/contour
use_content=$(cat << 'EOF'
# Contour's ebuild requires qtbase[opengl] and links the C++ Qt6::Multimedia API.
# qtdeclarative and qtmultimedia carry "opengl=" USE dependencies on qtbase, so
# they must match. Contour uses no Multimedia/Qt5Compat QML modules, so those
# flags (and qtquick3d, which qtmultimedia[qml] would pull in) are omitted.
# Rendering is OpenGL; Vulkan is not added here (global USE still applies).
# qml and vulkan are not negated on purpose:
#  - /etc/portage/package.use/qtmultimedia and .../quickshell enable qml;
#    quickshell uses Qt5Compat QML, so forcing -qml would break it.
#  - gui-apps/quickshell hard-requires qtbase[vulkan] in its ebuild (it has no
#    vulkan USE flag), so qtbase cannot be rebuilt with -vulkan while it is
#    installed.
# zlib[minizip] is required by the installed virtual/minizip package.
dev-qt/qtbase opengl
dev-qt/qtdeclarative opengl
dev-qt/qtmultimedia opengl
sys-libs/zlib minizip
EOF
)
warn_drift_from_managed "$use_file" "$use_content"
printf '%s\n' "$use_content" | portage_write_file "$use_file"

# Report flags that other Portage configuration forces back on. This file
# deliberately omits qml and vulkan, but global USE or other package.use
# entries can still enable them for the Qt stack.
qt_use_warned=false
for qt_flag in qml vulkan; do
  if have portageq && portageq envvar USE 2>/dev/null | tr ' ' '\n' | grep -qx "$qt_flag"; then
    log_warn "Global USE enables '${qt_flag}'; Qt packages will still be built with it."
    qt_use_warned=true
  fi
done

qt_use_overrides=""
if [ -d /etc/portage/package.use ]; then
  qt_use_overrides=$(
    grep -RHnE 'dev-qt/(qtbase|qtdeclarative|qtmultimedia|qtquick3d|qt5compat|qttools|qt3d)(:[0-9]+)?[[:space:]]' /etc/portage/package.use 2>/dev/null |
      grep -v '/contour:' | sed 's/#.*//' |
      grep -E '(^|[[:space:]])(qml|vulkan)([[:space:]]|$)' || true
  )
elif [ -f /etc/portage/package.use ]; then
  qt_use_overrides=$(
    grep -HnE 'dev-qt/(qtbase|qtdeclarative|qtmultimedia|qtquick3d|qt5compat|qttools|qt3d)(:[0-9]+)?[[:space:]]' /etc/portage/package.use 2>/dev/null |
      sed 's/#.*//' |
      grep -E '(^|[[:space:]])(qml|vulkan)([[:space:]]|$)' || true
  )
fi
if [ -n "$qt_use_overrides" ]; then
  log_warn "Other package.use files enable qml/vulkan for the Qt stack:"
  printf '%s\n' "$qt_use_overrides" | sed 's/^/    /' >&2
  qt_use_warned=true
fi

if [ "$qt_use_warned" = true ] && have equery; then
  log_info "Effective flags on the affected Qt packages:"
  for qt_pkg in dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia; do
    qt_pkg_flags=$(equery -q uses "$qt_pkg" 2>/dev/null | grep -E '^[+-](qml|vulkan|opengl)$' | tr '\n' ' ' | sed 's/[[:space:]]*$//' || true)
    if [ -n "$qt_pkg_flags" ]; then
      log_info "  ${qt_pkg}: ${qt_pkg_flags}"
    fi
  done
fi

if [ "$CHECK_ONLY" = true ]; then
  step "Preview: rebuilding the Qt dependencies (emerge --pretend)..."
  emerge -p -v --changed-use --noreplace --oneshot --binpkg-respect-use=y \
    dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qt5compat ||
    log_warn "Preview failed; the guru overlay may need to be enabled and synced."

  step "Preview: gui-apps/contour (emerge --pretend)..."
  emerge -p -v --binpkg-respect-use=y gui-apps/contour ||
    log_warn "Preview failed; the guru overlay may need to be enabled and synced."

  log_ok "Check-only complete; no packages were merged."
  exit 0
fi

step "Step 6: Updating Qt dependencies with new USE flags..."
# A binpkg cache/binhost may hold Qt builds with different USE flags. Respect
# them silently (they are unusable for this config anyway) instead of letting
# Portage print its "binary packages have been ignored" warning block.
# --oneshot keeps these dependencies out of @world: Contour is the only
# package this script intends to select.
emerge --changed-use --noreplace --oneshot --binpkg-respect-use=y \
  dev-qt/qtbase dev-qt/qtdeclarative dev-qt/qtmultimedia dev-qt/qt5compat ||
  die "Failed to rebuild the Qt dependencies with the new USE flags."

step "Step 7: Emerging gui-apps/contour..."
if [ -t 0 ]; then
  emerge -av --binpkg-respect-use=y gui-apps/contour || die "gui-apps/contour failed to build."
else
  emerge -v --binpkg-respect-use=y gui-apps/contour || die "gui-apps/contour failed to build."
fi

log_ok "Installation complete! You can now launch Contour with: contour"
