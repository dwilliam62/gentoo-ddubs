#!/usr/bin/env bash
# Enable the QML USE flag on dev-qt/qt5compat, which gui-apps/quickshell needs.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

KEYWORDS_BASE="/etc/portage/package.use"
USE_ENTRY="dev-qt/qt5compat qml gui"

need_root "$@"

use_file="$(portage_conf_file "$KEYWORDS_BASE" quickshell)"
install -d "$(dirname "$use_file")"
touch "$use_file"

# Idempotent: re-running must not append a duplicate entry.
if grep -qF -- "$USE_ENTRY" "$use_file"; then
  log_info "\"${USE_ENTRY}\" already present in ${use_file}"
else
  printf '%s\n' "$USE_ENTRY" >>"$use_file"
  log_ok "Added \"${USE_ENTRY}\" to ${use_file}"
fi

log_info "Rebuilding dev-qt/qt5compat with the new flags..."
emerge --ask dev-qt/qt5compat || die "dev-qt/qt5compat failed to build."
