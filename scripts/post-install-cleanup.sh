#!/usr/bin/env bash
set -euo pipefail

# Independent cleanup steps: a failure is recorded and reported in the summary,
# but the remaining steps still run.

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

# 1) Remove all source code tarballs (distfiles)
if have eclean-dist; then
  run_step "Pruning old distfiles (eclean-dist -d)" sudo eclean-dist -d
else
  # Fallback: brute-force wipe if eclean-dist is not available
  run_step "Cleaning distfiles (/var/cache/distfiles)" sudo rm -rf /var/cache/distfiles/*
fi

# 2) Clear the temporary build directories
run_step "Clearing Portage build roots (/var/tmp/portage)" \
  sudo rm -rf /var/tmp/portage/*

# 3) Clean up old binary packages (if you used them)
if have eclean-pkg; then
  run_step "Cleaning old binary packages (eclean-pkg)" sudo eclean-pkg
else
  log_warn "Skip: eclean-pkg not found; skipping binary package cleanup"
fi

# 4) Update the eix database one last time so it's fresh for the snapshot
if have eix-update; then
  run_step "Refreshing eix database" sudo eix-update
else
  log_warn "Skip: eix-update not found; skipping eix refresh"
fi

# 5) Run fstrim (best-effort)
if have fstrim; then
  run_step "Running fstrim on all mounted filesystems" sudo fstrim -av
else
  log_warn "Skip: fstrim not found; skipping SSD/TRIM pass"
fi

# 6) Vacuum systemd journal (if present) to last 7 days
if have journalctl; then
  run_step "Vacuuming systemd journal (7 days)" sudo journalctl --vacuum-time=7d
else
  log_warn "Skip: journalctl not found; skipping journal vacuum"
fi

if run_summary; then
  log_ok "All cleanup steps completed."
else
  log_warn "Completed with ${RUN_FAILURES} failed step(s); see above."
  exit 1
fi
