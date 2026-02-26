#!/usr/bin/env bash
set -euo pipefail

# Gentoo post-update cleanup
# - Syncs GURU repo (if available)
# - Refreshes eix database
# - Runs standard maintenance: preserved-rebuild, revdep-rebuild, depclean, eclean-*
# - Finishes with fstrim -av

if [ -t 1 ]; then
  C_RESET=$'\033[0m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_RED=$'\033[31m'
  C_BLUE=$'\033[34m'
  C_GRAY=$'\033[90m'
else
  C_RESET=''
  C_GREEN=''
  C_YELLOW=''
  C_RED=''
  C_BLUE=''
  C_GRAY=''
fi

OK="${C_GREEN}✔${C_RESET}"
INFO="${C_BLUE}ℹ${C_RESET}"
WARN="${C_YELLOW}⚠${C_RESET}"
ERR="${C_RED}✖${C_RESET}"
STEPS=0
FAILURES=0
STEPS_RUN=()
STEPS_FAILED=()

say() {
  printf "%s %s%s%s %s\n" "$1" "${C_GRAY}" "$(date +%H:%M:%S)" "${C_RESET}" "$2"
}

run_step() {
  local label="$1"; shift
  say "$INFO" "Starting ${label} ..."
  STEPS=$((STEPS + 1))
  STEPS_RUN+=("$label")
  if "$@"; then
    say "$OK" "Done ${label}"
  else
    say "$ERR" "Failed ${label} (continuing)"
    FAILURES=$((FAILURES + 1))
    STEPS_FAILED+=("$label")
    return 1
  fi
}

sync_guru_repo() {
  if ! command -v emaint >/dev/null 2>&1; then
    say "$WARN" "emaint not found; cannot sync GURU"
    return 0
  fi

  if emaint sync -l 2>/dev/null | awk '{print $1}' | grep -qx 'guru'; then
    run_step "Syncing GURU repo (emaint sync -r guru)" sudo emaint sync -r guru
  else
    say "$WARN" "GURU repo not configured; skipping"
  fi
}

refresh_eix() {
  if command -v eix-update >/dev/null 2>&1; then
    run_step "Refreshing eix database" sudo eix-update
  else
    say "$WARN" "eix-update not found; skipping"
  fi
}

main() {
  local start_ts end_ts elapsed elapsed_hms
  start_ts=$(date +%s)
  sync_guru_repo
  refresh_eix

  if command -v emerge >/dev/null 2>&1; then
    run_step "Rebuilding preserved libs" sudo emerge @preserved-rebuild --quiet
    run_step "Cleaning depclean (asks by default)" sudo emerge --ask --depclean
  else
    say "$WARN" "emerge not found; skipping preserved-rebuild/depclean"
  fi

  if command -v revdep-rebuild >/dev/null 2>&1; then
    run_step "Running revdep-rebuild" sudo revdep-rebuild -v
  else
    say "$WARN" "revdep-rebuild not found; skipping"
  fi

  if command -v emaint >/dev/null 2>&1; then
    run_step "emaint --fix cleanresume" sudo emaint --fix cleanresume
  fi

  if command -v eclean-dist >/dev/null 2>&1; then
    run_step "Cleaning old distfiles (eclean-dist -d)" sudo eclean-dist -d
  else
    say "$WARN" "eclean-dist not found; skipping"
  fi

  if command -v eclean-pkg >/dev/null 2>&1; then
    run_step "Cleaning old binary packages (eclean-pkg)" sudo eclean-pkg
  else
    say "$WARN" "eclean-pkg not found; skipping"
  fi

  if command -v fstrim >/dev/null 2>&1; then
    run_step "Running fstrim on all mounted filesystems" sudo fstrim -av
  else
    say "$WARN" "fstrim not found; skipping"
  fi

  end_ts=$(date +%s)
  elapsed=$((end_ts - start_ts))
  elapsed_hms=$(printf "%02d:%02d:%02d" $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60)))

  echo
  say "${C_BLUE}★${C_RESET}" "Summary"
  say "$INFO" "Steps run: ${STEPS}"
  say "$INFO" "Failures: ${FAILURES}"
  say "$INFO" "Elapsed: ${elapsed_hms}"
  if [ "${#STEPS_RUN[@]}" -gt 0 ]; then
    say "$INFO" "Steps attempted:"
    for s in "${STEPS_RUN[@]}"; do
      printf "  %b %s\n" "$OK" "$s"
    done
  fi
  if [ "${#STEPS_FAILED[@]}" -gt 0 ]; then
    say "$WARN" "Steps failed:"
    for s in "${STEPS_FAILED[@]}"; do
      printf "  %b %s\n" "$ERR" "$s"
    done
  fi
}

main "$@"
