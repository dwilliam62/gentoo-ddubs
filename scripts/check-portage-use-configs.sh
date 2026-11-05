#!/usr/bin/env bash
set -euo pipefail

# Compare repo snapshot of /etc/portage/package.use against the live system.
# This is read-only: it only reports drift, it does not modify anything.

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
snapshot_dir="$repo_root/system/etc/portage/package.use"

OK="${C_GREEN}${ICON_OK}${C_RESET}"
DRIFT="${C_YELLOW}${ICON_WARN}${C_RESET}"
MISSING="${C_RED}${ICON_ERR}${C_RESET}"

if [ ! -d "$snapshot_dir" ]; then
  printf '%s Snapshot directory not found: %s\n' "$MISSING" "$snapshot_dir" >&2
  exit 1
fi

live_base="/etc/portage/package.use"

if [ ! -d "$live_base" ]; then
  printf '%s Live package.use directory not found: %s\n' "$MISSING" "$live_base" >&2
  exit 1
fi

status=0

printf '%s\n\n' "Checking USE config drift between repo snapshot and live system..."

# For each file in the snapshot, compare to live system by basename.
while IFS= read -r -d '' snap_file; do
  rel_name="${snap_file#"$snapshot_dir"/}"
  live_file="$live_base/$rel_name"

  printf '%s\n' "${C_BOLD}=== $rel_name ===${C_RESET}"

  if [ ! -e "$live_file" ]; then
    printf '%s MISSING on host: %s\n' "$MISSING" "$live_file"
    printf '%s\n\n' "(present in snapshot, absent on system)"
    status=1
    continue
  fi

  if diff -q "$snap_file" "$live_file" >/dev/null 2>&1; then
    printf '%s live matches snapshot\n\n' "$OK"
  else
    printf '%s DRIFT: live differs from snapshot\n' "$DRIFT"
    printf 'Snapshot: %s\n' "$snap_file"
    printf 'Live:     %s\n' "$live_file"
    printf '%s\n' "--- unified diff (snapshot vs live) ---"
    diff -u "$snap_file" "$live_file" || true
    printf '\n'
    status=1
  fi

done < <(find "$snapshot_dir" -maxdepth 1 -type f -print0)

if [ "$status" -eq 0 ]; then
  printf '%s No drift detected.\n' "$OK"
else
  printf '%s Drift or missing files detected.\n' "$DRIFT"
fi

exit "$status"
