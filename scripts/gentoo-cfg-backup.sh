#!/usr/bin/env bash
# Tarball the Gentoo config that matters for a reinstall.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

# Under sudo, `whoami` is root; back up the invoking user's home instead.
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-$HOME}"
ARCHIVE="gentoo_backup_$(date +%F).tar.bz2"

need_root "$@"
require_cmd tar

paths=(/etc/portage /etc/locale.gen /etc/hosts /etc/fstab)
if [ -d "${TARGET_HOME}/.config" ]; then
  paths+=("${TARGET_HOME}/.config")
else
  log_warn "Skipping ${TARGET_HOME}/.config (not found)"
fi

log_info "Archiving ${#paths[@]} paths for user ${TARGET_USER}..."
tar -cvpjf "$ARCHIVE" "${paths[@]}" || die "tar failed; archive may be incomplete."

# Hand the archive back to the invoking user instead of leaving it root-owned.
if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
  chown "$SUDO_USER": "$ARCHIVE" 2>/dev/null || true
fi

log_ok "Wrote ${ARCHIVE} ($(du -h "$ARCHIVE" | cut -f1))"
