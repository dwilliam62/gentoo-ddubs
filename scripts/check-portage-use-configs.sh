#!/usr/bin/env bash
set -euo pipefail

# Compare repo snapshot of /etc/portage/package.use against the live system.
# This is read-only: it only reports drift, it does not modify anything.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
snapshot_dir="$repo_root/system/etc/portage/package.use"

if [ ! -d "$snapshot_dir" ]; then
  echo "Snapshot directory not found: $snapshot_dir" >&2
  exit 1
fi

live_base="/etc/portage/package.use"

if [ ! -d "$live_base" ]; then
  echo "Live package.use directory not found: $live_base" >&2
  exit 1
fi

status=0

printf 'Checking USE config drift between repo snapshot and live system...\n\n'

# For each file in the snapshot, compare to live system by basename.
while IFS= read -r -d '' snap_file; do
  rel_name="${snap_file#$snapshot_dir/}"
  live_file="$live_base/$rel_name"

  echo "=== $rel_name ==="

  if [ ! -e "$live_file" ]; then
    echo "MISSING on host: $live_file"
    echo "(present in snapshot, absent on system)" 
    echo
    status=1
    continue
  fi

  if diff -q "$snap_file" "$live_file" >/dev/null 2>&1; then
    echo "OK: live matches snapshot"
    echo
  else
    echo "DRIFT: live differs from snapshot"
    echo "Snapshot: $snap_file"
    echo "Live:     $live_file"
    echo "--- unified diff (snapshot vs live) ---"
    diff -u "$snap_file" "$live_file" || true
    echo
    status=1
  fi

done < <(find "$snapshot_dir" -maxdepth 1 -type f -print0)

exit "$status"
