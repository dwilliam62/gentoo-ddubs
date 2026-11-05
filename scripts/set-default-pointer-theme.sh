#!/usr/bin/env bash
# Point Xcursor's fallback theme at Adwaita, without clobbering an existing
# /usr/share/icons/default/index.theme.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

THEME_DIR="/usr/share/icons/default"
THEME_FILE="${THEME_DIR}/index.theme"

need_root "$@"
install -d "$THEME_DIR"

if [ -f "$THEME_FILE" ] && grep -qx 'Inherits=Adwaita' "$THEME_FILE"; then
  log_ok "${THEME_FILE} already inherits Adwaita; nothing to do."
  exit 0
fi

if [ -f "$THEME_FILE" ]; then
  backup="${THEME_FILE}.bak-$(date +%Y%m%d%H%M%S)"
  cp -a "$THEME_FILE" "$backup"
  log_info "Backed up ${THEME_FILE} -> ${backup}"
fi

printf '[Icon Theme]\nInherits=Adwaita\n' >"$THEME_FILE"
log_ok "Wrote ${THEME_FILE} (Inherits=Adwaita)"
