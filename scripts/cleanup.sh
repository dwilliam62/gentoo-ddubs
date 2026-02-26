#!/usr/bin/env bash
set -euo pipefail

# Gentoo post-update cleanup
# - Syncs GURU repo (if available)
# - Refreshes eix database
# - Runs standard maintenance: preserved-rebuild, revdep-rebuild, depclean, eclean-*
# - Finishes with fstrim -av

OK="[✔]"
INFO="[i]"
WARN="[!]"
ERR="[✖]"

say() {
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

sync_guru_repo() {
  if ! command -v emaint >/dev/null 2>&1; then
    say "$WARN" "Skip" "emaint not found; cannot sync GURU"
    return 0
  fi

  if emaint sync -l 2>/dev/null | awk '{print $1}' | grep -qx 'guru'; then
    run_step "Syncing GURU repo (emaint sync -r guru)" sudo emaint sync -r guru
  else
    say "$WARN" "Skip" "GURU repo not configured; skipping"
  fi
}

refresh_eix() {
  if command -v eix-update >/dev/null 2>&1; then
    run_step "Refreshing eix database" sudo eix-update
  else
    say "$WARN" "Skip" "eix-update not found; skipping"
  fi
}

main() {
  sync_guru_repo
  refresh_eix

  if command -v emerge >/dev/null 2>&1; then
    run_step "Rebuilding preserved libs" sudo emerge @preserved-rebuild --quiet
    run_step "Cleaning depclean (asks by default)" sudo emerge --ask --depclean
  else
    say "$WARN" "Skip" "emerge not found; skipping preserved-rebuild/depclean"
  fi

  if command -v revdep-rebuild >/dev/null 2>&1; then
    run_step "Running revdep-rebuild" sudo revdep-rebuild -v
  else
    say "$WARN" "Skip" "revdep-rebuild not found; skipping"
  fi

  if command -v emaint >/dev/null 2>&1; then
    run_step "emaint --fix cleanresume" sudo emaint --fix cleanresume
  fi

  if command -v eclean-dist >/dev/null 2>&1; then
    run_step "Cleaning old distfiles (eclean-dist -d)" sudo eclean-dist -d
  else
    say "$WARN" "Skip" "eclean-dist not found; skipping"
  fi

  if command -v eclean-pkg >/dev/null 2>&1; then
    run_step "Cleaning old binary packages (eclean-pkg)" sudo eclean-pkg
  else
    say "$WARN" "Skip" "eclean-pkg not found; skipping"
  fi

  if command -v fstrim >/dev/null 2>&1; then
    run_step "Running fstrim on all mounted filesystems" sudo fstrim -av
  else
    say "$WARN" "Skip" "fstrim not found; skipping"
  fi
}

main "$@"
