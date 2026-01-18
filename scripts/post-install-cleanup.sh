#!/usr/bin/env bash
set -euo pipefail

# Simple icons for nicer output (no extra deps)
OK="[✔]"
INFO="[i]"
WARN="[!]"
ERR="[✖]"

say() {
  # Timestamped log line
  printf "%s %s %s\n" "$2" "$(date +%H:%M:%S)" "$3"
}

run_step() {
  local label="$1"; shift
  say "$INFO" "Starting" "$label ..."
  if "$@"; then
    say "$OK" "Done" "$label"
  else
    say "$ERR" "Failed" "$label (continuing)"
    return 1
  fi
}

# 1) Remove all source code tarballs (distfiles)
if command -v eclean-dist >/dev/null 2>&1; then
  run_step "Pruning old distfiles (eclean-dist -d)" sudo eclean-dist -d
else
  # Fallback: brute-force wipe if eclean-dist is not available
  run_step "Cleaning distfiles (/var/cache/distfiles)" sudo rm -rf /var/cache/distfiles/*
fi

# 2) Clear the temporary build directories
run_step "Clearing Portage build roots (/var/tmp/portage)" \
  sudo rm -rf /var/tmp/portage/*

# 3) Clean up old binary packages (if you used them)
if command -v eclean-pkg >/dev/null 2>&1; then
  run_step "Cleaning old binary packages (eclean-pkg)" sudo eclean-pkg
else
  say "$WARN" "Skip" "eclean-pkg not found; skipping binary package cleanup"
fi

# 4) Update the eix database one last time so it's fresh for the snapshot
if command -v eix-update >/dev/null 2>&1; then
  run_step "Refreshing eix database" sudo eix-update
else
  say "$WARN" "Skip" "eix-update not found; skipping eix refresh"
fi

# 5) Run fstrim (best-effort)
if command -v fstrim >/dev/null 2>&1; then
  run_step "Running fstrim on all mounted filesystems" sudo fstrim -av
else
  say "$WARN" "Skip" "fstrim not found; skipping SSD/TRIM pass"
fi

# 6) Vacuum systemd journal (if present) to last 7 days
if command -v journalctl >/dev/null 2>&1; then
  run_step "Vacuuming systemd journal (7 days)" sudo journalctl --vacuum-time=7d
else
  say "$WARN" "Skip" "journalctl not found; skipping journal vacuum"
fi
