#!/usr/bin/env bash
# Mask games-util/hid-nintendo from the GURU overlay and provide the dummy
# linux-mod eclass it pulls in, so unrelated emerges are not blocked by it.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

GURU_REPO="/var/db/repos/guru"
ECLASS_DIR="${GURU_REPO}/eclass"
DUMMY_ECLASS="${ECLASS_DIR}/linux-mod.eclass"
MASK_BASE="/etc/portage/package.mask"
MASK_ATOM="games-util/hid-nintendo"
PROFILE_MASK_DIR="/etc/portage/profile"
PROFILE_MASK="${PROFILE_MASK_DIR}/package.mask"

need_root "$@"

printf '%s\n' "=== Gentoo GURU mask & fix automation ==="

if [ ! -d "$GURU_REPO" ]; then
  log_warn "GURU repo not found at ${GURU_REPO}; enable it first with 'eselect repository enable guru'."
fi

log_info "Ensuring directory exists: ${ECLASS_DIR}"
install -d "$ECLASS_DIR"

log_info "Creating dummy linux-mod.eclass inside GURU..."
cat >"$DUMMY_ECLASS" <<'EOF'
# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Dummy eclass to satisfy broken GURU overlay imports
EOF
log_ok "Wrote ${DUMMY_ECLASS}"

# /etc/portage/package.mask may be a single file or a directory of snippets.
mask_file="$(portage_conf_file "$MASK_BASE" hid-nintendo)"
install -d "$(dirname "$mask_file")"

if grep -qF -- "$MASK_ATOM" "$mask_file" 2>/dev/null; then
  log_ok "Mask already present in ${mask_file}"
else
  {
    echo "# Mask hid-nintendo: it requires linux-mod.eclass and Nintendo controllers are unused here"
    echo "${MASK_ATOM}::guru"
  } >>"$mask_file"
  log_ok "Added ${MASK_ATOM} mask to ${mask_file}"
fi

install -d "$PROFILE_MASK_DIR"
if grep -qF -- "$MASK_ATOM" "$PROFILE_MASK" 2>/dev/null; then
  log_ok "Profile mask already present in ${PROFILE_MASK}"
else
  printf '%s\n' "$MASK_ATOM" >>"$PROFILE_MASK"
  log_ok "Added ${MASK_ATOM} to ${PROFILE_MASK}"
fi

log_info "Regenerating GURU repository cache..."
if have egencache; then
  egencache --repo=guru --update ||
    log_warn "egencache failed; run 'emaint sync -r guru' and re-run this script."
else
  log_warn "egencache not found (install app-portage/portage-utils); skipping cache refresh."
fi

log_ok "Done. You can now safely run your emerge commands."
