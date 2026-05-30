#!/usr/bin/env bash
set -euo pipefail

# Gentoo system updater
# - Syncs Portage tree (emerge --sync)
# - Evaluates pending upgrades and writes a markdown summary to precheck-<DATE>.md
# - Performs update of @world (deep, newuse) only when explicitly initiated
# - Optionally --dry-run to preview without changes
# - Writes a post-update markdown report: Post-Update-<DATE>-Report.md
#
# Usage:
#   bash scripts/update.sh [--eval | --dry-run | --apply] [--no-sync] [--use-binpkgs] [--auto-yes] [--skip-quickshell] [--help]
#
# Modes (choose one):
#   --eval        Only evaluate and write precheck-<DATE>.md. No changes are made.
#   --dry-run     Preview update actions (pretend). Writes precheck-<DATE>.md. No changes are made.
#   --apply       Perform the actual update (requires root; will prompt unless --auto-yes).
#
# Options:
#   --no-sync         Do not run emerge --sync first.
#   --use-binpkgs     Try to use binary packages from PORTAGE_BINHOST and allow USE-mismatch binpkg fallback.
#   --auto-yes        Proceed with updates without interactive prompt (omit --ask).
#   --skip-quickshell Exclude gui-apps/quickshell from update/pretend.
#   --help            Show this help and exit.
#
# Notes:
# - Running with no arguments shows this help and exits; updates are never implicit.
# - Post-Update-<DATE>-Report.md is only generated after a successful --apply run.
# - Set KEEP_KERNELS=<N> to control how many kernels are retained during post-update pruning (default: 2).

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
log_dir="$HOME/Documents"
now_ts="$(date +%Y%m%d-%H%M%S)"
precheck_md="$log_dir/precheck-${now_ts}.md"
post_md="$log_dir/Post-Update-${now_ts}-Report.md"
OXWM_REPO_URL="https://github.com/tonybanters/oxwm"
OXWM_DIR="/opt/oxwm"

say() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

oxwm_build_user() {
  if [ -d "$OXWM_DIR" ]; then
    stat -c %U "$OXWM_DIR" 2>/dev/null || echo "${SUDO_USER:-$USER}"
  else
    echo "${SUDO_USER:-$USER}"
  fi
}

collect_fatal_pretend_errors() {
  local input_file="$1"
  local output_file="$2"
  awk '
    /^ \* ERROR:/ {
      print
      next
    }
    /^!!!/ {
      if ($0 ~ /The following binary packages have been ignored due to non matching USE/) {
        next
      }
      print
    }
  ' "$input_file" >"$output_file"
}



ensure_hyproverlay_repo() {
  if ! command -v eselect >/dev/null 2>&1; then
    return
  fi

  if ! eselect repository list >/dev/null 2>&1; then
    say "Installing app-eselect/eselect-repository..."
    emerge -n app-eselect/eselect-repository || {
      say "WARN: Failed to install app-eselect/eselect-repository; cannot manage hyproverlay automatically."
      return
    }
  fi

  if eselect repository list 2>/dev/null | awk '/\*/ {print $2}' | grep -qx 'hyproverlay'; then
    return
  fi

  say "Enabling hyproverlay repository for Hyprland packages..."
  if ! eselect repository enable hyproverlay >/dev/null 2>&1; then
    say "WARN: Failed to enable hyproverlay; Hyprland packages may remain masked."
  fi
}

build_oxwm() {
  local build_user
  build_user="$(oxwm_build_user)"
  say "Building OXWM (zig build -Doptimize=ReleaseFast)..."
  sudo -u "$build_user" env PATH="$PATH" bash -c "cd \"$OXWM_DIR\" && zig build -Doptimize=ReleaseFast"
  if [ -f "${OXWM_DIR}/zig-out/bin/oxwm" ]; then
    install -Dm755 "${OXWM_DIR}/zig-out/bin/oxwm" /usr/local/bin/oxwm
    say "Installed /usr/local/bin/oxwm"
  else
    say "WARN: OXWM build finished but binary not found at zig-out/bin/oxwm"
  fi
}

update_oxwm_repo() {
  local build_user
  build_user="$(oxwm_build_user)"
  if [ -d "${OXWM_DIR}/.git" ]; then
    say "Checking OXWM repo for updates..."
    local before after
    before=$(sudo -u "$build_user" git -C "$OXWM_DIR" rev-parse HEAD)
    sudo -u "$build_user" git -C "$OXWM_DIR" pull --ff-only
    after=$(sudo -u "$build_user" git -C "$OXWM_DIR" rev-parse HEAD)
    if [ "$before" != "$after" ]; then
      say "OXWM updated; rebuilding..."
      build_oxwm
    else
      say "OXWM already up to date."
    fi
  else
    say "OXWM repo not found. Cloning ${OXWM_REPO_URL}..."
    git clone "$OXWM_REPO_URL" "$OXWM_DIR"
    chown -R "$build_user":"$build_user" "$OXWM_DIR"
    build_oxwm
  fi
}

print_usage() {
  cat <<'EOF'
Usage:
  bash scripts/update.sh [--eval | --dry-run | --apply] [--no-sync] [--use-binpkgs] [--auto-yes] [--skip-quickshell] [--help]

Modes (choose one):
  --eval        Only evaluate and write precheck-<DATE>.md. No changes are made.
  --dry-run     Preview update actions (pretend). Writes precheck-<DATE>.md. No changes are made.
  --apply       Perform the actual update (requires root; will prompt unless --auto-yes).

Options:
  --no-sync         Do not run emerge --sync first.
  --use-binpkgs     Try to use binary packages from PORTAGE_BINHOST and allow USE-mismatch binpkg fallback.
  --auto-yes        Proceed with updates without interactive prompt (omit --ask).
  --skip-quickshell Exclude gui-apps/quickshell from update/pretend.
  --help            Show this help and exit.

Examples:
  bash scripts/update.sh --eval
  bash scripts/update.sh --dry-run --no-sync
  bash scripts/update.sh --apply --use-binpkgs --auto-yes
  bash scripts/update.sh --apply --skip-quickshell
EOF
}

need_root() {
  # Escalate when applying changes or when syncing in --eval/--dry-run modes
  local need_sudo=false
  if [ "${APPLY:-false}" = "true" ]; then
    need_sudo=true
  elif [ "${NO_SYNC:-false}" = "false" ] && ([ "${EVAL_ONLY:-false}" = "true" ] || [ "${DRY_RUN:-false}" = "true" ]); then
    need_sudo=true
  fi
  
  if [ "$need_sudo" = "true" ]; then
    [ "${EUID:-$(id -u)}" -ne 0 ] || return 0
    exec sudo -E env DRY_RUN="${DRY_RUN:-false}" EVAL_ONLY="${EVAL_ONLY:-false}" NO_SYNC="${NO_SYNC:-false}" USE_BINPKGS="${USE_BINPKGS:-false}" AUTO_YES="${AUTO_YES:-false}" APPLY="${APPLY:-false}" SKIP_QUICKSHELL="${SKIP_QUICKSHELL:-false}" bash "$0" "$@"
  fi
}

# Parse args
DRY_RUN="false"
EVAL_ONLY="false"
APPLY="false"
NO_SYNC="false"
USE_BINPKGS="false"
AUTO_YES="false"
SKIP_QUICKSHELL="false"
args=()
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN="true" ;;
    --eval) EVAL_ONLY="true" ;;
    --apply) APPLY="true" ;;
    --no-sync) NO_SYNC="true" ;;
    --use-binpkgs) USE_BINPKGS="true" ;;
    --auto-yes) AUTO_YES="true" ;;
    --skip-quickshell) SKIP_QUICKSHELL="true" ;;
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
EMERGE_PRETEND=(-p -v -u -D --newuse --with-bdeps=y --ask=n --color=n @world)
EMERGE_UPDATE=(-v -u -D --newuse --with-bdeps=y @world)
[ "$USE_BINPKGS" = "true" ] && EMERGE_PRETEND+=(--getbinpkg --binpkg-respect-use=n) && EMERGE_UPDATE+=(--getbinpkg --binpkg-respect-use=n)
[ "$SKIP_QUICKSHELL" = "true" ] && EMERGE_PRETEND+=(--exclude=gui-apps/quickshell) && EMERGE_UPDATE+=(--exclude=gui-apps/quickshell)
[ "$AUTO_YES" = "true" ] || EMERGE_UPDATE=(--ask "${EMERGE_UPDATE[@]}")

# Ensure repo root exists
mkdir -p "$log_dir"

maybe_disable_unsupported_overlays() {
  # Best-effort guard against known-broken overlays that ship unsupported EAPIs.
  # Currently handles: wayland-desktop (broken gui-desq EAPI=7 ebuilds).
  if ! command -v eselect >/dev/null 2>&1; then
    return
  fi

  if eselect repository list 2>/dev/null | awk '/\*/ {print $2}' | grep -qx 'wayland-desktop'; then
    say "Detected enabled overlay 'wayland-desktop'; attempting to disable to avoid EAPI 7 sync failures..."
    if eselect repository disable wayland-desktop >/dev/null 2>&1; then
      say "Disabled overlay 'wayland-desktop'."
    else
      say "WARN: Failed to disable overlay 'wayland-desktop'; sync may still fail."
    fi
  fi
}

# Sync Portage unless disabled
maybe_sync() {
  if [ "$NO_SYNC" = "true" ]; then
    say "Skipping repository sync (per --no-sync)"
    return
  fi

  maybe_disable_unsupported_overlays
  ensure_hyproverlay_repo
  
  if command -v emaint >/dev/null 2>&1; then
    say "Syncing all repos (emaint sync -a)..."
    emaint sync -a || true
  else
    say "Syncing Portage tree (emerge --sync)..."
    emerge --sync
  fi
}

# Update eix cache if available
maybe_update_eix() {
  if command -v eix-update >/dev/null 2>&1; then
    say "Refreshing eix cache (eix-update)..."
    local tmp tmp2
    tmp="$(mktemp)"
    tmp2="$(mktemp)"
    eix-update >"$tmp" 2>&1 || true
    if grep -q "EAPI 7 not supported" "$tmp"; then
      eix-update >"$tmp2" 2>&1 || true
      cat "$tmp2"
    else
      cat "$tmp"
    fi
    rm -f "$tmp" "$tmp2"
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
latest_boot_kernel_version() {
  find /boot -maxdepth 1 -type f -name 'kernel-*' -printf '%f\n' 2>/dev/null \
    | sed -e 's/^kernel-//' \
    | sort -V \
    | tail -n 1
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
    echo "## Kernel Status"
    current_k=$(uname -r)
    latest_k="$(latest_boot_kernel_version)"
    if [ -n "$latest_k" ] && [ "$current_k" != "$latest_k" ]; then
      echo "⚠️ Reboot required: Running $current_k, but $latest_k is installed."
    fi
    if [ -n "$latest_k" ] && [ ! -d "/lib/modules/${latest_k}" ]; then
      echo "⚠️ Missing module tree: /lib/modules/${latest_k}"
    fi
    if [ -n "$latest_k" ] && [ ! -d "/usr/src/linux-${latest_k}" ]; then
      echo "⚠️ Missing source tree: /usr/src/linux-${latest_k}"
    fi

    echo
    echo "## Remaining Updates"
    echo
    echo '```text'
    if [ "$USE_BINPKGS" = "true" ]; then
      emerge -p -v -u -D --newuse --with-bdeps=y --color=n --getbinpkg --binpkg-respect-use=n @world || true
    else
      emerge -p -v -u -D --newuse --with-bdeps=y --color=n @world || true
    fi
    echo '```'
  } | tee "$post_md"

  say "Wrote post-update report: $post_md"
}

maybe_fix_linux_symlink() {
  local latest_source current_target
  latest_source="$(
    find /usr/src -maxdepth 1 -mindepth 1 -type d -name 'linux-*' -printf '%f\n' 2>/dev/null \
      | sort -V \
      | tail -n 1
  )"
  [ -n "$latest_source" ] || return

  current_target="$(readlink /usr/src/linux 2>/dev/null || true)"
  if [ ! -L /usr/src/linux ] || [ ! -e /usr/src/linux ] || [ "$current_target" != "$latest_source" ]; then
    ln -sfn "$latest_source" /usr/src/linux
    say "Updated /usr/src/linux -> ${latest_source}"
  fi
}
maybe_refresh_grub_for_new_kernel() {
  # Always prune old kernels and refresh GRUB after successful updates.
  local latest_kernel keep_kernels
  latest_kernel="$(latest_boot_kernel_version)"
  keep_kernels="${KEEP_KERNELS:-2}"
  [ -n "$latest_kernel" ] || return

  if [ ! -d "/lib/modules/${latest_kernel}" ]; then
    say "WARN: Missing /lib/modules/${latest_kernel}; reinstall the matching gentoo-kernel-bin package."
  fi
  if [ ! -d "/usr/src/linux-${latest_kernel}" ]; then
    say "WARN: Missing /usr/src/linux-${latest_kernel}; /usr/src/linux may be stale."
  fi

  say "Pruning old kernels (keeping ${keep_kernels}) and regenerating GRUB..."
  KEEP_KERNELS="$keep_kernels" bash "${repo_root}/scripts/after-kernel-update.sh" || {
    say "WARN: after-kernel-update.sh failed; please run it manually."
  }
}

main() {
  # Ensure we have root when needed (apply mode or sync in eval/dry-run)
  need_root update "$@"

  # Sync if requested/default (only when a mode was selected)
  maybe_sync
  maybe_update_eix
  if [ "$SKIP_QUICKSHELL" = "true" ]; then
    say "Skipping gui-apps/quickshell (per --skip-quickshell)."
  fi

  say "Evaluating pending updates (pretend)..."
  if ! emerge "${EMERGE_PRETEND[@]}" >"$precheck_md.tmp" 2>&1; then
    # Only treat as fatal when actual errors are present (not just warnings/autounmask).
    if collect_fatal_pretend_errors "$precheck_md.tmp" "$precheck_md.fatal.tmp" && [ -s "$precheck_md.fatal.tmp" ]; then
      say "emerge pretend reported errors; see $precheck_md.tmp"
      say "Error summary (from pretend output):"
      head -n 40 "$precheck_md.fatal.tmp"
      rm -f "$precheck_md.fatal.tmp"
      exit 1
    fi
    rm -f "$precheck_md.fatal.tmp"
    say "emerge pretend returned non-zero, but no fatal errors detected; continuing."
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

  update_oxwm_repo

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
    say "Checking for preserved-rebuilds..."
    emerge @preserved-rebuild --quiet || true
    say "Running depclean (safe, asks by default)"
    emerge --ask --depclean || true
  fi
  if command -v eclean-dist >/dev/null 2>&1; then
    say "Cleaning old distfiles (eclean-dist -d)"
    eclean-dist -d || true
  fi

  # Post report
  write_post_update_report
  maybe_fix_linux_symlink
  maybe_refresh_grub_for_new_kernel
  say "Done."
}

main "$@"
