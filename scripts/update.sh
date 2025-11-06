#!/usr/bin/env bash
set -euo pipefail

# Gentoo system updater
# - Syncs Portage tree (emerge --sync)
# - Evaluates pending upgrades and writes a markdown summary to precheck.md
# - Performs update of @world (deep, newuse) only when explicitly initiated
# - Optionally --dry-run to preview without changes
# - Writes a post-update markdown report: Post-Update-<DATE>-Report.md
#
# Usage:
#   bash scripts/update.sh [--eval | --dry-run | --apply] [--no-sync] [--auto-yes] [--help]
#
# Modes (choose one):
#   --eval        Only evaluate and write precheck.md. No changes are made.
#   --dry-run     Preview update actions (pretend). Writes precheck.md. No changes are made.
#   --apply       Perform the actual update (requires root; will prompt unless --auto-yes).
#
# Options:
#   --no-sync     Do not run emerge --sync first.
#   --auto-yes    Proceed with updates without interactive prompt (omit --ask).
#   --help        Show this help and exit.
#
# Notes:
# - Running with no arguments shows this help and exits; updates are never implicit.
# - Post-Update-<DATE>-Report.md is only generated after a successful --apply run.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
log_dir="$repo_root"
precheck_md="$log_dir/precheck.md"
now_ts="$(date +%Y%m%d-%H%M%S)"
post_md="$log_dir/Post-Update-${now_ts}-Report.md"

say() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

print_usage() {
  cat <<'EOF'
Usage:
  bash scripts/update.sh [--eval | --dry-run | --apply] [--no-sync] [--auto-yes] [--help]

Modes (choose one):
  --eval        Only evaluate and write precheck.md. No changes are made.
  --dry-run     Preview update actions (pretend). Writes precheck.md. No changes are made.
  --apply       Perform the actual update (requires root; will prompt unless --auto-yes).

Options:
  --no-sync     Do not run emerge --sync first.
  --auto-yes    Proceed with updates without interactive prompt (omit --ask).
  --help        Show this help and exit.

Examples:
  bash scripts/update.sh --eval
  bash scripts/update.sh --dry-run --no-sync
  bash scripts/update.sh --apply --auto-yes
EOF
}

need_root() {
  # Only escalate when actually applying changes
  if [ "${APPLY:-false}" = "true" ]; then
    [ "${EUID:-$(id -u)}" -ne 0 ] || return 0
    exec sudo -E env DRY_RUN="${DRY_RUN:-false}" EVAL_ONLY="${EVAL_ONLY:-false}" NO_SYNC="${NO_SYNC:-false}" AUTO_YES="${AUTO_YES:-false}" APPLY="${APPLY:-false}" bash "$0" "$@"
  fi
}

# Parse args
DRY_RUN="false"
EVAL_ONLY="false"
APPLY="false"
NO_SYNC="false"
AUTO_YES="false"
args=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN="true" ;;
    --eval) EVAL_ONLY="true" ;;
    --apply) APPLY="true" ;;
    --no-sync) NO_SYNC="true" ;;
    --auto-yes) AUTO_YES="true" ;;
    --help|-h) print_usage; exit 0 ;;
    *) args+=("$a") ;;
  esac
done

# If no mode was selected, show help and exit (do nothing by default)
if [ "$DRY_RUN" = "false" ] && [ "$EVAL_ONLY" = "false" ] && [ "$APPLY" = "false" ]; then
  print_usage
  exit 2
fi

# Common emerge flags
EMERGE_PRETEND=(-p -v -u -D --newuse --with-bdeps=y --color=n @world)
EMERGE_UPDATE=(-v -u -D --newuse --with-bdeps=y @world)
[ "$AUTO_YES" = "true" ] || EMERGE_UPDATE=(--ask "${EMERGE_UPDATE[@]}")

# Ensure repo root exists
mkdir -p "$log_dir"

# Sync Portage unless disabled
maybe_sync() {
  if [ "$NO_SYNC" = "true" ]; then
    say "Skipping emerge --sync (per --no-sync)"
  else
    say "Syncing Portage tree (emerge --sync)..."
    emerge --sync
  fi
}

# Parse pretend output into a markdown summary
# Input: stdin = output of `emerge -pvuDU --with-bdeps=y @world` (no color)
# Output: writes markdown to precheck_md and also echoes to stdout
summarize_pretend_to_md() {
  local tmp pret
  tmp="$(mktemp)"
  cat >"$tmp"

  # Extract package lines
  mapfile -t lines < <(grep -E '^\[ebuild' "$tmp" || true)
  local count="${#lines[@]}"

  {
    echo "# Gentoo Update Precheck"
    echo
    date -u "+%F %T UTC" | sed 's/^/Generated: /'
    echo
    if [ "$count" -eq 0 ]; then
      echo "No updates available. System appears up-to-date."
    else
      echo "Pending packages: $count"
      echo
      echo "| Package | Current | New | Flags |"
      echo "|---|---:|---:|---|"
      for line in "${lines[@]}"; do
        # New atom + versions
        atom=$(printf "%s" "$line" | sed -E 's/^\[ebuild[^]]*\] *([^ ]+).*/\1/')
        atom_stripped=$(printf "%s" "$atom" | sed -E 's/:.*$//')
        pkg_name=$(printf "%s" "$atom_stripped" | sed -E 's/-[0-9].*$//')
        new_ver=$(printf "%s" "$atom_stripped" | sed -E 's/^.*-([0-9].*)$/\1/')
        old_ver=$(printf "%s" "$line" | sed -nE 's/.*\[([0-9][^]]*)\].*/\1/p')
        # Flags: N/U/R etc from the bracket header
        flags=$(printf "%s" "$line" | sed -E 's/^\[ebuild *([^]]*)\].*/\1/' | tr -s ' ')
        [ -n "$old_ver" ] || old_ver="—"
        echo "| $pkg_name | $old_ver | $new_ver | $flags |"
      done
    fi

    echo
    echo "## Raw emerge pretend output"
    echo
    echo '```text'
    cat "$tmp"
    echo '```'
  } | tee "$precheck_md"

  rm -f "$tmp"
}

# Generate post-update report using the last precheck as the list of upgrades
write_post_update_report() {
  local pre_file="$precheck_md"
  {
    echo "# Gentoo Post-Update Report"
    date -u "+%F %T UTC" | sed 's/^/Completed: /'
    echo
    echo "## Summary"
    # Count lines in precheck table (skip header + separator)
    local upgraded=0
    if grep -q '^\| ' "$pre_file" 2>/dev/null; then
      upgraded=$(grep -E '^\| ' "$pre_file" | tail -n +3 | wc -l | tr -d ' ')
    fi
    echo "- Packages upgraded: $upgraded"

    echo
    echo "## Upgraded Packages"
    if [ "$upgraded" -gt 0 ]; then
      echo
      echo "| Package | From | To |"
      echo "|---|---:|---:|"
      # Reuse the precheck table rows
      grep -E '^\| ' "$pre_file" | tail -n +3 | awk -F'|' '{gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4); if($2!=""){print "| "$2" | "$3" | "$4" |"}}'
    else
      echo "No package upgrades were planned (system was up-to-date)."
    fi

    echo
    echo "## Remaining Updates"
    echo
    echo '```text'
    emerge -p -v -u -D --newuse --with-bdeps=y --color=n @world || true
    echo '```'
  } | tee "$post_md"

  say "Wrote post-update report: $post_md"
}

main() {
  # For actual updates, ensure we have root
  if [ "$APPLY" = "true" ]; then
    need_root update "$@"
  fi

  # Sync if requested/default (only when a mode was selected)
  maybe_sync

  say "Evaluating pending updates (pretend)..."
  if ! emerge "${EMERGE_PRETEND[@]}" >"$precheck_md.tmp" 2>&1; then
    say "emerge pretend reported errors; see $precheck_md.tmp"
    exit 1
  fi
  summarize_pretend_to_md <"$precheck_md.tmp" > /dev/null
  rm -f "$precheck_md.tmp"
  say "Wrote precheck: $precheck_md"

  if [ "$EVAL_ONLY" = "true" ]; then
    say "Eval-only mode complete."
    exit 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    say "Dry-run requested; no changes applied."
    exit 0
  fi

  if [ "$APPLY" != "true" ]; then
    # Should not reach here due to earlier guard, but be safe
    say "No apply requested; exiting."
    exit 0
  fi

  # Perform the update
  say "Performing system update (emerge ${EMERGE_UPDATE[*]})..."
  if ! emerge "${EMERGE_UPDATE[@]}"; then
    say "Update failed. No post-update report generated."
    exit 1
  fi

  # Optional maintenance (best-effort)
  if command -v etc-update >/dev/null 2>&1; then
    say "Config file updates may be pending. Consider running: etc-update or dispatch-conf"
  fi
  if command -v emaint >/dev/null 2>&1; then
    say "Running emaint --fix cleanresume (best-effort)"
    emaint --fix cleanresume || true
  fi
  if command -v revdep-rebuild >/dev/null 2>&1; then
    say "Running revdep-rebuild (best-effort)"
    revdep-rebuild -v || true
  fi
  if command -v emerge >/dev/null 2>&1; then
    say "Running depclean (safe, asks by default)"
    emerge --ask --depclean || true
  fi

  # Post report
  write_post_update_report
  say "Done."
}

main "$@"
