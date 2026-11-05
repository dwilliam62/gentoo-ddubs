#!/usr/bin/env bash
set -euo pipefail

# Gentoo post-update cleanup
# - Syncs GURU repo (if available)
# - Refreshes eix database
# - Runs standard maintenance: preserved-rebuild, revdep-rebuild, depclean, eclean-*
# - Finishes with fstrim -av

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

# When already running as root sudo may be absent (or useless); call tools directly.
if [ "${EUID:-$(id -u)}" -eq 0 ]; then
  sudo() { "$@"; }
fi

sync_guru_repo() {
  if ! have emaint; then
    log_warn "emaint not found; cannot sync GURU"
    return 0
  fi

  if emaint sync -l 2>/dev/null | awk '{print $1}' | grep -qx 'guru'; then
    run_step "Syncing GURU repo (emaint sync -r guru)" sudo emaint sync -r guru
  else
    log_warn "GURU repo not configured; skipping"
  fi
}

refresh_eix() {
  if have eix-update; then
    run_step "Refreshing eix database" sudo eix-update
  else
    log_warn "eix-update not found; skipping"
  fi
}

main() {
  local start_ts end_ts elapsed elapsed_hms
  start_ts=$(date +%s)
  sync_guru_repo
  refresh_eix

  if have emerge; then
    run_step "Rebuilding preserved libs" sudo emerge @preserved-rebuild --quiet
    run_step "Cleaning depclean (asks by default)" sudo emerge --ask --depclean
  else
    log_warn "emerge not found; skipping preserved-rebuild/depclean"
  fi

  if have revdep-rebuild; then
    run_step "Running revdep-rebuild" sudo revdep-rebuild -v
  else
    log_warn "revdep-rebuild not found; skipping"
  fi

  if have emaint; then
    run_step "emaint --fix cleanresume" sudo emaint --fix cleanresume
  fi

  if have eclean-dist; then
    run_step "Cleaning old distfiles (eclean-dist -d)" sudo eclean-dist -d
  else
    log_warn "eclean-dist not found; skipping"
  fi

  if have eclean-pkg; then
    run_step "Cleaning old binary packages (eclean-pkg)" sudo eclean-pkg
  else
    log_warn "eclean-pkg not found; skipping"
  fi

  if have fstrim; then
    run_step "Running fstrim on all mounted filesystems" sudo fstrim -av
  else
    log_warn "fstrim not found; skipping"
  fi

  end_ts=$(date +%s)
  elapsed=$((end_ts - start_ts))
  elapsed_hms=$(printf "%02d:%02d:%02d" $((elapsed / 3600)) $(((elapsed % 3600) / 60)) $((elapsed % 60)))

  log_info "Elapsed: ${elapsed_hms}"
  # Returns non-zero when a step failed, so callers and cron can react.
  run_summary
}

main "$@"
