#!/usr/bin/env bash
set -euo pipefail

YAZI_ATOM="=app-misc/yazi-9999::guru"
KEYWORD_ENTRY="=app-misc/yazi-9999::guru **"
KEYWORDS_PATH="/etc/portage/package.accept_keywords"
GURU_REPO_CONF="/etc/portage/repos.conf/guru.conf"
GURU_SYNC_URI="https://gitweb.gentoo.org/repo/proj/guru.git"
MIN_RUSTC_VERSION_LIVE="1.95.0"

say() {
  printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"
}

current_rustc_version() {
  if ! command -v rustc >/dev/null 2>&1; then
    return 1
  fi

  rustc --version 2>/dev/null | awk '{print $2}' | sed 's/-.*$//'
}

version_ge() {
  local actual="$1"
  local required="$2"

  [[ -n "$actual" && -n "$required" ]] || return 1
  [[ "$(printf '%s\n%s\n' "$required" "$actual" | sort -V | head -n 1)" == "$required" ]]
}

ensure_min_rustc_for_live() {
  local rustc_ver desired_impl
  desired_impl="rust-bin-${MIN_RUSTC_VERSION_LIVE}"
  rustc_ver="$(current_rustc_version || true)"

  if [[ -n "$rustc_ver" ]] && version_ge "$rustc_ver" "$MIN_RUSTC_VERSION_LIVE"; then
    return 0
  fi

  say "rustc ${rustc_ver:-unavailable} is below required ${MIN_RUSTC_VERSION_LIVE}; installing ${desired_impl} ..."
  if ! emerge --oneshot "=dev-lang/${desired_impl}"; then
    say "WARN: failed to install dev-lang/${desired_impl}."
    return 1
  fi

  if command -v eselect >/dev/null 2>&1; then
    eselect rust set "${desired_impl}" >/dev/null 2>&1 || true
  fi

  hash -r || true
  rustc_ver="$(current_rustc_version || true)"
  if [[ -z "$rustc_ver" ]]; then
    say "WARN: rustc is still unavailable after installing ${desired_impl}."
    return 1
  fi
  if ! version_ge "$rustc_ver" "$MIN_RUSTC_VERSION_LIVE"; then
    say "WARN: rustc ${rustc_ver} is still below required ${MIN_RUSTC_VERSION_LIVE}."
    return 1
  fi

  say "Using rustc ${rustc_ver} for live yazi build."
  return 0
}

print_usage() {
  cat <<'EOF'
Usage:
  bash scripts/update-yazi.sh [--install|-i] [--status|-s] [--remove|-r] [--help|-h]

Options:
  --install, -i  Install/update yazi-9999 from guru and apply keyword fix.
  --status, -s   Show Yazi install status, current version, and keyword-fix status.
  --remove, -r   Remove app-misc/yazi and remove the yazi-9999 keyword fix.
  --help, -h     Show this help text.

Default behavior:
  With no arguments, this script runs --status and then prints this usage text.
EOF
}

keyword_target_file() {
  if [ -d "$KEYWORDS_PATH" ]; then
    printf "%s\n" "$KEYWORDS_PATH/yazi"
  else
    printf "%s\n" "$KEYWORDS_PATH"
  fi
}

keyword_fix_present_exact() {
  if [ -d "$KEYWORDS_PATH" ]; then
    grep -R -F -x -- "$KEYWORD_ENTRY" "$KEYWORDS_PATH" >/dev/null 2>&1
  elif [ -f "$KEYWORDS_PATH" ]; then
    grep -F -x -- "$KEYWORD_ENTRY" "$KEYWORDS_PATH" >/dev/null 2>&1
  else
    return 1
  fi
}

keyword_fix_present_any() {
  local pattern='(^|[[:space:]])=?app-misc/yazi-9999([[:space:]]|$)'
  if [ -d "$KEYWORDS_PATH" ]; then
    grep -R -E -- "$pattern" "$KEYWORDS_PATH" >/dev/null 2>&1
  elif [ -f "$KEYWORDS_PATH" ]; then
    grep -E -- "$pattern" "$KEYWORDS_PATH" >/dev/null 2>&1
  else
    return 1
  fi
}

ensure_keyword_fix() {
  local target
  target="$(keyword_target_file)"

  if [ -d "$KEYWORDS_PATH" ]; then
    install -d "$KEYWORDS_PATH"
  else
    install -d "$(dirname "$KEYWORDS_PATH")"
  fi
  touch "$target"

  if grep -F -x -- "$KEYWORD_ENTRY" "$target" >/dev/null 2>&1; then
    say "Keyword fix already present in $target"
    return 0
  fi

  printf "%s\n" "$KEYWORD_ENTRY" >> "$target"
  say "Added keyword fix to $target"
}

remove_keyword_fix() {
  local removed="false"
  local file tmp

  if [ -d "$KEYWORDS_PATH" ]; then
    while IFS= read -r -d '' file; do
      if grep -F -x -- "$KEYWORD_ENTRY" "$file" >/dev/null 2>&1; then
        tmp="$(mktemp)"
        grep -F -x -v -- "$KEYWORD_ENTRY" "$file" > "$tmp" || true
        cat "$tmp" > "$file"
        rm -f "$tmp"
        removed="true"
        say "Removed keyword fix from $file"
      fi
    done < <(find "$KEYWORDS_PATH" -type f -print0)
  elif [ -f "$KEYWORDS_PATH" ] && grep -F -x -- "$KEYWORD_ENTRY" "$KEYWORDS_PATH" >/dev/null 2>&1; then
    tmp="$(mktemp)"
    grep -F -x -v -- "$KEYWORD_ENTRY" "$KEYWORDS_PATH" > "$tmp" || true
    cat "$tmp" > "$KEYWORDS_PATH"
    rm -f "$tmp"
    removed="true"
    say "Removed keyword fix from $KEYWORDS_PATH"
  fi

  if [ "$removed" = "false" ]; then
    say "Keyword fix not found; nothing to remove."
  fi
}

installed_pkg_cpv() {
  if command -v portageq >/dev/null 2>&1; then
    portageq match / app-misc/yazi 2>/dev/null | tail -n 1 || true
  fi
}

status_yazi() {
  local binary_state="not installed"
  local version="n/a"
  local cpv
  local rustc_ver
  local rustc_live_state

  cpv="$(installed_pkg_cpv)"
  rustc_ver="$(current_rustc_version || true)"
  if [[ -z "$rustc_ver" ]]; then
    rustc_live_state="rustc unavailable"
  elif version_ge "$rustc_ver" "$MIN_RUSTC_VERSION_LIVE"; then
    rustc_live_state="ok (>= ${MIN_RUSTC_VERSION_LIVE})"
  else
    rustc_live_state="too old for yazi-9999 (needs >= ${MIN_RUSTC_VERSION_LIVE})"
  fi
  if command -v yazi >/dev/null 2>&1; then
    binary_state="installed"
    version="$(yazi --version 2>/dev/null || true)"
    [ -n "$version" ] || version="installed (version probe failed)"
  fi

  printf "Yazi status\n"
  printf "  binary: %s\n" "$binary_state"
  printf "  version: %s\n" "$version"
  if [ -n "${cpv:-}" ]; then
    printf "  package: %s\n" "$cpv"
  else
    printf "  package: not installed via Portage (or unavailable)\n"
  fi
  if [[ -n "$rustc_ver" ]]; then
    printf "  rustc: %s (%s)\n" "$rustc_ver" "$rustc_live_state"
  else
    printf "  rustc: unavailable (%s)\n" "$rustc_live_state"
  fi

  if keyword_fix_present_exact; then
    printf "  yazi-9999 keyword fix (%s): installed\n" "$KEYWORD_ENTRY"
  elif keyword_fix_present_any; then
    printf "  yazi-9999 keyword fix: custom entry found (not exact match)\n"
  else
    printf "  yazi-9999 keyword fix (%s): missing\n" "$KEYWORD_ENTRY"
  fi
}

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    exec sudo -E bash "$0" "$@"
  fi
}
ensure_guru_repo() {
  if ! command -v eselect >/dev/null 2>&1; then
    say "Installing app-eselect/eselect-repository for guru overlay management..."
    emerge --ask=n app-eselect/eselect-repository
  fi

  if eselect repository list 2>/dev/null | awk '/\*/ {print $2}' | grep -qx "guru"; then
    say "guru overlay already enabled."
  elif eselect repository list 2>/dev/null | awk 'NR>1 {print $2}' | grep -qx "guru"; then
    say "Enabling existing guru overlay entry..."
    eselect repository enable guru || true
  else
    say "Creating fallback repos.conf entry for guru overlay..."
    install -d /etc/portage/repos.conf
    cat >"$GURU_REPO_CONF" <<EOF
[guru]
location = /var/db/repos/guru
sync-type = git
sync-uri = ${GURU_SYNC_URI}
auto-sync = yes
EOF
  fi

  if command -v emaint >/dev/null 2>&1; then
    say "Syncing guru metadata..."
    emaint sync -r guru || say "WARN: Unable to sync guru via emaint."
  else
    say "Syncing repositories (emerge --sync) to pick up guru..."
    emerge --sync || say "WARN: emerge --sync failed while refreshing overlays."
  fi
}

install_yazi() {
  local rustc_ver
  need_root "$@"
  if ! ensure_min_rustc_for_live; then
    say "Skipping live yazi update and keeping current repository yazi package state."
    return 0
  fi

  rustc_ver="$(current_rustc_version || true)"
  ensure_guru_repo
  ensure_keyword_fix
  say "rustc ${rustc_ver} satisfies live yazi requirement (>= ${MIN_RUSTC_VERSION_LIVE})."
  say "Installing/updating $YAZI_ATOM ..."
  emerge --oneshot "$YAZI_ATOM"
  say "Install/update completed."
}

remove_yazi() {
  need_root "$@"
  if [ -n "$(installed_pkg_cpv)" ]; then
    say "Removing app-misc/yazi ..."
    emerge --ask=n --unmerge app-misc/yazi
  else
    say "app-misc/yazi is not installed."
  fi
  remove_keyword_fix
  say "Remove action completed."
}

main() {
  local show_help="false"
  local do_status="false"
  local do_install="false"
  local do_remove="false"
  local arg

  if [ "$#" -eq 0 ]; then
    do_status="true"
    show_help="true"
  fi

  for arg in "$@"; do
    case "$arg" in
      -h|--help) show_help="true" ;;
      -s|--status) do_status="true" ;;
      -i|--install) do_install="true" ;;
      -r|--remove|/remove) do_remove="true" ;;
      *)
        printf "Unknown option: %s\n\n" "$arg" >&2
        print_usage
        exit 2
        ;;
    esac
  done

  if [ "$do_install" = "true" ] && [ "$do_remove" = "true" ]; then
    printf "Cannot use --install and --remove together.\n" >&2
    exit 2
  fi

  if [ "$do_install" = "true" ]; then
    install_yazi "$@"
  fi
  if [ "$do_remove" = "true" ]; then
    remove_yazi "$@"
  fi
  if [ "$do_status" = "true" ]; then
    status_yazi
  fi
  if [ "$show_help" = "true" ]; then
    print_usage
  fi
}

main "$@"
