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
#   bash scripts/update.sh [--eval | --dry-run | --apply | --haskell-only] [--no-sync] [--use-binpkgs] [--auto-yes] [--skip-quickshell] [--help]
#
# Modes (choose one):
#   --eval         Only evaluate and write precheck-<DATE>.md. No changes are made.
#   --dry-run      Preview update actions (pretend). Writes precheck-<DATE>.md. No changes are made.
#   --apply        Perform the actual update (requires root; will prompt unless --auto-yes).
#   --just-oxwm    Update and rebuild OxWM only.
#   --haskell-only Rebuild the installed dev-haskell packages with haskell-updater and exit.
#                  Extra atoms are passed through to haskell-updater/emerge.
#
# Options:
#   --no-sync         Do not run emerge --sync first.
#   --use-binpkgs     Try to fetch binary packages from PORTAGE_BINHOST (USE-mismatch fallback is always enabled).
#   --auto-yes        Proceed with updates without interactive prompt (omit --ask).
#   --skip-quickshell Exclude gui-apps/quickshell from update/pretend.
#   --help            Show this help and exit.
#
# Notes:
# - Running with no arguments shows this help and exits; updates are never implicit.
# - Post-Update-<DATE>-Report.md is written after every --apply run; when packages
#   failed to merge it lists them under "Failed Packages".
# - Set KEEP_KERNELS=<N> to control how many kernels are retained during post-update pruning (default: 2).
# - If a dev-haskell package fails in src_configure asking for 'haskell-updater'
#   (GHC/library ABI breakage, which Portage sub-slots cannot track), the apply
#   step runs 'haskell-updater --all' and retries the update once.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
log_dir="$HOME/Documents"
now_ts="$(date +%Y%m%d-%H%M%S)"
precheck_md="$log_dir/precheck-${now_ts}.md"
post_md="$log_dir/Post-Update-${now_ts}-Report.md"
OXWM_REPO_URL="https://github.com/tonybanters/oxwm"
OXWM_DIR="/opt/oxwm"

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

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
    # --oneshot: overlay tooling, not something to select into @world.
    emerge -n --oneshot app-eselect/eselect-repository || {
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
  local zig_bin="/opt/zig/0.16.0/zig"
  if [[ ! -x "$zig_bin" ]]; then
    zig_bin="$(command -v zig || true)"
  fi
  if [[ -z "$zig_bin" ]]; then
    say "WARN: zig not found; skipping OXWM build."
    return 0
  fi
  sudo -u "$build_user" env PATH="$PATH" ZIG_BIN="$zig_bin" bash -c 'cd "$1" && "$ZIG_BIN" build -Doptimize=ReleaseFast' _ "$OXWM_DIR"
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
  bash scripts/update.sh [--eval | --dry-run | --apply | --haskell-only] [--no-sync] [--use-binpkgs] [--auto-yes] [--skip-quickshell] [--help]

Modes (choose one):
  --eval         Only evaluate and write precheck-<DATE>.md. No changes are made.
  --dry-run      Preview update actions (pretend). Writes precheck-<DATE>.md. No changes are made.
  --apply        Perform the actual update (requires root; will prompt unless --auto-yes).
  --haskell-only Rebuild the installed Haskell (dev-haskell/*) packages and exit (no sync).
                 Extra atoms are passed through to haskell-updater, e.g.
                 bash scripts/update.sh --haskell-only dev-haskell/tls

Options:
  --no-sync         Do not run emerge --sync first.
  --use-binpkgs     Try to fetch binary packages from PORTAGE_BINHOST (USE-mismatch fallback is always enabled).
  --auto-yes        Proceed with updates without interactive prompt (omit --ask).
  --skip-quickshell Exclude gui-apps/quickshell from update/pretend.
  --help            Show this help and exit.

Examples:
  bash scripts/update.sh --eval
  bash scripts/update.sh --dry-run --no-sync
  bash scripts/update.sh --apply --use-binpkgs --auto-yes
  bash scripts/update.sh --apply --skip-quickshell
  bash scripts/update.sh --just-oxwm
  bash scripts/update.sh --haskell-only
  bash scripts/update.sh --haskell-only dev-haskell/tls
EOF
}

escalate_if_needed() {
  # Script-specific policy: escalate only when applying changes or when a sync
  # will run in --eval/--dry-run mode.
  local need_sudo=false
  if [ "${JUST_OXWM:-false}" = "true" ]; then
    need_sudo=true
  elif [ "${HASKELL_ONLY:-false}" = "true" ]; then
    need_sudo=true
  elif [ "${APPLY:-false}" = "true" ]; then
    need_sudo=true
  elif [ "${NO_SYNC:-false}" = "false" ] && ([ "${EVAL_ONLY:-false}" = "true" ] || [ "${DRY_RUN:-false}" = "true" ]); then
    need_sudo=true
  fi
  
  if [ "$need_sudo" = "true" ]; then
    [ "${EUID:-$(id -u)}" -ne 0 ] || return 0
    exec sudo -E env \
      DRY_RUN="${DRY_RUN:-false}" EVAL_ONLY="${EVAL_ONLY:-false}" JUST_OXWM="${JUST_OXWM:-false}" \
      NO_SYNC="${NO_SYNC:-false}" USE_BINPKGS="${USE_BINPKGS:-false}" AUTO_YES="${AUTO_YES:-false}" \
      APPLY="${APPLY:-false}" SKIP_QUICKSHELL="${SKIP_QUICKSHELL:-false}" HASKELL_ONLY="${HASKELL_ONLY:-false}" \
      bash "$0" "$@"
  fi
}

# Parse args
DRY_RUN="false"
EVAL_ONLY="false"
APPLY="false"
JUST_OXWM="false"
HASKELL_ONLY="false"
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
    --just-oxwm) JUST_OXWM="true" ;;
    --haskell-only) HASKELL_ONLY="true" ;;
    --no-sync) NO_SYNC="true" ;;
    --use-binpkgs) USE_BINPKGS="true" ;;
    --auto-yes) AUTO_YES="true" ;;
    --skip-quickshell) SKIP_QUICKSHELL="true" ;;
    --help|-h) print_usage; exit 0 ;;
    *) args+=("$a") ;;
  esac
done
# If no mode was selected, show help and exit (do nothing by default)
if [ "$DRY_RUN" = "false" ] && [ "$EVAL_ONLY" = "false" ] && [ "$APPLY" = "false" ] && [ "$JUST_OXWM" = "false" ] && [ "$HASKELL_ONLY" = "false" ]; then
  print_usage
  exit 2
fi
if [ "${#args[@]}" -gt 0 ] && [ "$HASKELL_ONLY" != "true" ]; then
  say "WARN: ignoring extra arguments (only --haskell-only forwards them): ${args[*]}"
fi

# Common emerge flags
EMERGE_PRETEND=(-p -v -u -D --newuse --with-bdeps=y --ask=n --color=n --binpkg-respect-use=n @world)
# --keep-going: one failing ebuild (typically a dev-haskell package left with a
# stale ABI hash) must not stall the merge of the other pending packages.
EMERGE_UPDATE=(-v -u -D --newuse --with-bdeps=y --binpkg-respect-use=n --keep-going @world)
[ "$USE_BINPKGS" = "true" ] && EMERGE_PRETEND+=(--getbinpkg) && EMERGE_UPDATE+=(--getbinpkg)
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
    emaint sync -a || say "WARN: emaint sync reported errors; continuing with the existing tree."
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
  local tmp
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

# Atoms that --keep-going left unmerged, from either the per-package
# '>>> Failed to emerge' lines or the trailing failure summary block.
failed_packages_from_log() {
  local log="$1"
  {
    sed -n 's/^>>> Failed to emerge \([^,]*\),.*/\1/p' "$log"
    sed -n 's/^ \*  *(\([^:,[:space:]]*\):.*/\1/p' "$log"
  } | sort -u
}

# Generate post-update report using the last precheck as the list of upgrades.
# Pass the file of failed atoms to record a partial run.
write_post_update_report() {
  local pre_file="$precheck_md" failures_file="${1:-}" failed_count=0
  {
    echo "# Gentoo Post-Update Report"
    date -u "+%F %T UTC" | sed 's/^/Completed: /'
    echo
    echo "## Summary"
    # Count lines in precheck table (skip header + separator)
    local upgraded=0
    if grep -q '^| ' "$pre_file" 2>/dev/null; then
      # The first matching line is the table header; every later line is a package.
      upgraded=$(grep -E '^\| ' "$pre_file" | tail -n +2 | wc -l | tr -d ' ')
    fi
    echo "- Packages upgraded: $upgraded"
    if [ -n "$failures_file" ] && [ -s "$failures_file" ]; then
      failed_count=$(wc -l <"$failures_file" | tr -d ' ')
      echo "- Status: incomplete — $failed_count package(s) failed to merge"
    else
      echo "- Status: complete"
    fi

    echo
    echo "## Upgraded Packages"
    if [ "$upgraded" -gt 0 ]; then
      echo
      echo "| Package | From | To |"
      echo "|---|---:|---:|"
      # Reuse the precheck table rows (skip the header line)
      grep -E '^\| ' "$pre_file" | tail -n +2 | awk -F'|' '{gsub(/^ +| +$/, "", $2); gsub(/^ +| +$/, "", $3); gsub(/^ +| +$/, "", $4); if($2!=""){print "| "$2" | "$3" | "$4" |"}}'
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

    if [ "$failed_count" -gt 0 ]; then
      echo
      echo "## Failed Packages"
      echo
      echo "These packages did not merge; the rest of the update completed:"
      echo
      sed 's/^/- /' "$failures_file"
    fi

    echo
    echo "## Remaining Updates"
    echo
    echo '```text'
    if [ "$USE_BINPKGS" = "true" ]; then
      emerge -p -v -u -D --newuse --with-bdeps=y --color=n --binpkg-respect-use=n --getbinpkg @world || true
    else
      emerge -p -v -u -D --newuse --with-bdeps=y --color=n --binpkg-respect-use=n @world || true
    fi
    echo '```'
  } | tee "$post_md"

  say "Wrote post-update report: $post_md"
}

# Haskell (dev-haskell/*) packages carry an ABI hash that Portage sub-slots do
# not track, so a GHC or library upgrade leaves installed packages with broken
# dependencies and every Haskell ebuild dies in src_configure with:
#   //==-- Please, run 'haskell-updater' to fix broken packages --==//
haskell_breakage_requested() {
  grep -q "Please, run 'haskell-updater'" "$1"
}

# True when the installed Haskell packages already fail their own dependency
# check, which every dev-haskell build repeats before configuring.
haskell_installed_packages_broken() {
  command -v ghc-pkg >/dev/null 2>&1 || return 1
  ! ghc-pkg check --simple-output >/dev/null 2>&1
}

# Precheck-time warning: the pending update will strand the installed Haskell
# packages, either because they are broken already or because GHC / the
# dev-haskell libraries they link against are being replaced.
# Emits the markdown bullets explaining why a Haskell rebuild is coming; empty
# output means the pending update is harmless for the installed Haskell stack.
haskell_risk_reasons() {
  local pretend_log="$1" reasons="" pending_ghc pending_haskell

  if haskell_installed_packages_broken; then
    reasons+="- Installed Haskell packages are already broken (\`ghc-pkg check\` reports errors)"$'\n'
  fi

  pending_ghc="$(grep -cE '^\[ebuild[^]]*\][[:space:]]+dev-lang/ghc-' "$pretend_log" || true)"
  if [ "${pending_ghc:-0}" -gt 0 ]; then
    reasons+="- \`dev-lang/ghc\` is being upgraded, which invalidates every installed \`dev-haskell\` package"$'\n'
  fi

  pending_haskell="$(grep -cE '^\[ebuild[^]]*\][[:space:]]+dev-haskell/' "$pretend_log" || true)"
  if [ "${pending_haskell:-0}" -gt 0 ]; then
    reasons+="- ${pending_haskell} \`dev-haskell\` package(s) are being upgraded"$'\n'
  fi

  printf '%s' "$reasons"
}

# Prints the precheck warning and records it in precheck-<DATE>.md, so the
# reason survives after the terminal output is gone.
report_haskell_update_risk() {
  local pretend_log="$1" reasons
  reasons="$(haskell_risk_reasons "$pretend_log")"
  [ -n "$reasons" ] || return 0

  say "WARN: this update will need a Haskell rebuild afterwards:"
  printf '%s' "$reasons" | sed 's/^- /  - /'
  say "  Run 'bash scripts/update.sh --haskell-only' (or let --apply do it automatically)."

  {
    echo
    echo "## Haskell Rebuild Required"
    echo
    printf '%s' "$reasons"
    echo
    echo
    echo "Run \`bash scripts/update.sh --haskell-only\` afterwards, or let \`--apply\` do it automatically."
  } >>"$precheck_md"
}

# Rebuilds the installed Haskell packages that no longer match the tree.
# Optional arguments are atoms, forwarded to emerge so one broken dependency can
# be targeted (e.g. dev-haskell/tls).
# Returns non-zero, with the manual steps, when haskell-updater is unavailable.
repair_haskell_packages() {
  local hu_args=(--all) atoms="${*:-}"

  if ! command -v haskell-updater >/dev/null 2>&1; then
    say "WARN: haskell-updater is not installed, so the broken dev-haskell packages cannot be rebuilt here."
    say "Fix the Haskell breakage and rerun this script:"
    say "  echo 'app-admin/haskell-updater ~amd64' >> /etc/portage/package.accept_keywords/haskell-updater"
    say "  emerge --oneshot --ask=n app-admin/haskell-updater"
    say "  haskell-updater --all"
    return 1
  fi

  if [ -n "$atoms" ]; then
    hu_args+=(-- "$@")
    say "Rebuilding Haskell packages (${atoms})..."
  else
    say "Rebuilding broken Haskell packages (haskell-updater --all)..."
  fi

  if ! haskell-updater "${hu_args[@]}"; then
    say "WARN: haskell-updater failed; run it manually before retrying the update."
    return 1
  fi
  return 0
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
  # Re-exec once when this mode needs root; arguments are forwarded unchanged.
  escalate_if_needed "$@"
  if [ "$JUST_OXWM" = "true" ]; then
    update_oxwm_repo
    say "Done."
    exit 0
  fi

  if [ "$HASKELL_ONLY" = "true" ]; then
    if repair_haskell_packages ${args[@]+"${args[@]}"}; then
      say "Done."
      exit 0
    fi
    exit 1
  fi

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
  report_haskell_update_risk "$precheck_md.tmp"
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

  # Perform the update. Tee the output so a Haskell ABI breakage can be
  # recognised while emerge's progress still reaches the terminal.
  local apply_log status
  apply_log="$(mktemp)"
  say "Performing system update (emerge ${EMERGE_UPDATE[*]})..."
  status=0
  emerge "${EMERGE_UPDATE[@]}" 2>&1 | tee "$apply_log" || status=$?

  if [ "$status" -ne 0 ] && haskell_breakage_requested "$apply_log"; then
    say "Haskell ABI breakage detected: installed dev-haskell packages are broken."
    if repair_haskell_packages; then
      say "Retrying system update (emerge ${EMERGE_UPDATE[*]})..."
      status=0
      emerge "${EMERGE_UPDATE[@]}" 2>&1 | tee "$apply_log" || status=$?
    fi
  fi
  rm -f "$apply_log"

  if [ "$status" -ne 0 ]; then
    # --keep-going means most of @world may have merged; keep a record of what
    # did not, rather than discarding the whole run.
    local failures_file
    failures_file="$(mktemp)"
    failed_packages_from_log "$apply_log" >"$failures_file"
    if [ -s "$failures_file" ]; then
      say "Update incomplete: $(wc -l <"$failures_file" | tr -d ' ') package(s) failed to merge."
      write_post_update_report "$failures_file"
    else
      say "Update failed. No post-update report generated."
    fi
    rm -f "$apply_log" "$failures_file"
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
