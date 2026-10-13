#!/usr/bin/env bash
# ==================================================
#  fix-waybar-reload-crash.sh
#
#  Gentoo-local fix for the Waybar reload crash.
#
#  Symptom
#    Reloading Waybar - `kill -USR2 <pid>`, or the `pkill -SIGUSR2 -x waybar`
#    that the KooL dots send on every lid, monitor and wallpaper event - aborts
#    the bar:
#
#      GLib-GIO:ERROR:../glib-2.88.3/gio/gapplicationimpl-dbus.c:851:
#        g_application_impl_command_line: assertion failed: (object_id != 0)
#      Bail out! GLib-GIO:ERROR:...
#
#    The bar disappears and the session is left with no Waybar at all.
#
#  Cause
#    Every Waybar process is created with the same D-Bus application id,
#    "fr.arouillard.waybar". Only one process can own that well-known name; the
#    others do not, so GLib treats their GApplication as remote. A reload
#    re-enters Client::main(), which creates a *second* Gtk::Application, and for
#    a remote application GLib registers its command-line object - which cannot
#    succeed while the previous application object in the same process still
#    holds it. GLib asserts and aborts the process.
#
#    A lone Waybar (the name owner) reloads fine, which is why this only shows
#    up when two bars exist - exactly what a lid or monitor event can produce.
#
#  Fix
#    Give each Waybar process its own application id, so every instance is
#    primary and takes the local reload path. Applied as a Portage *user patch*
#    under /etc/portage/patches, so the ebuild, the overlay and the KooL dots
#    are all left untouched.
#
#  See ../gentoo-waybar-issue.md for the full write-up and the evidence.
#
#  Usage
#    sudo fix-waybar-reload-crash.sh            install the patch and rebuild
#    sudo fix-waybar-reload-crash.sh --remove   drop the patch and rebuild
#         fix-waybar-reload-crash.sh --check    report status, change nothing
#         fix-waybar-reload-crash.sh --test     live reload test, change nothing
#
#  Gentoo only, and deliberately kept out of the KooL dots repo: the dots are
#  distro-agnostic and must not carry a workaround for one box's packaging.
set -euo pipefail

readonly PATCH_DIR="/etc/portage/patches/gui-apps/waybar"
readonly PATCH_FILE="${PATCH_DIR}/99-waybar-per-process-app-id.patch"
readonly WAYBAR_ATOM="gui-apps/waybar"
# The patch rewrites a specific block of src/client.cpp, so it is tied to the
# Waybar release it was written against. A newer release means: re-check the
# patch (emerge will fail loudly rather than drop it), then update this.
readonly KNOWN_VERSION="0.15.0"

say() { printf '%s\n' "$*"; }
note() { printf '[note] %s\n' "$*"; }
warn() { printf '[warn] %s\n' "$*" >&2; }
die() {
  printf '[error] %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<'EOF'
fix-waybar-reload-crash.sh - local fix for the Waybar reload crash

Usage:
  sudo fix-waybar-reload-crash.sh            install the patch, rebuild Waybar
  sudo fix-waybar-reload-crash.sh --remove   drop the patch, rebuild Waybar
       fix-waybar-reload-crash.sh --check    report status, change nothing
       fix-waybar-reload-crash.sh --test     live reload test, change nothing

The live test starts two throwaway bars and reloads both, so run it as your
desktop user - it needs WAYLAND_DISPLAY and the session bus - not with sudo.

See ../gentoo-waybar-issue.md for the full write-up.
EOF
}

require_root() {
  [ "$(id -u)" -eq 0 ] || die "this step writes to ${PATCH_DIR} and runs emerge; re-run with sudo"
}

waybar_version() {
  command -v waybar >/dev/null 2>&1 || die "waybar is not installed"
  waybar --version 2>/dev/null | sed -n 's/.*v\([0-9][0-9.]*\).*/\1/p' | head -n1
}

patch_installed() {
  [ -f "$PATCH_FILE" ]
}

# True when the installed binary was built after the patch file was written.
patch_built_in() {
  [ -f "$PATCH_FILE" ] || return 1
  local binary
  binary="$(command -v waybar)" || return 1
  [ "$binary" -nt "$PATCH_FILE" ]
}

write_patch() {
  mkdir -p "$PATCH_DIR"
  cat >"$PATCH_FILE" <<'PATCH'
--- a/src/client.cpp
+++ b/src/client.cpp
@@ -3,7 +3,10 @@
 #include <gtk-layer-shell.h>
 #include <spdlog/spdlog.h>
 
+#include <unistd.h>
+
 #include <iostream>
+#include <string>
 #include <utility>
 
 #include "gtkmm/icontheme.h"
@@ -268,8 +271,19 @@
   if (!log_level.empty()) {
     spdlog::set_level(spdlog::level::from_str(log_level));
   }
-  gtk_app = Gtk::Application::create(argc, argv, "fr.arouillard.waybar",
-                                     Gio::APPLICATION_HANDLES_COMMAND_LINE);
+  // A unique application id per process.
+  //
+  // With the shared "fr.arouillard.waybar" id, a second Waybar process cannot
+  // own the well-known D-Bus name, so GLib marks its GApplication as remote.
+  // Reloading such a process (SIGUSR2 -> Client::reset() -> this function again)
+  // then creates a second Gtk::Application whose command-line object cannot be
+  // registered, and GLib aborts on its own assertion:
+  //   g_application_impl_command_line: assertion failed: (object_id != 0)
+  // A per-process id keeps every instance primary, which is what the reload
+  // path assumes. See ~/gentoo-ddubs/gentoo-waybar-issue.md
+  gtk_app = Gtk::Application::create(
+      argc, argv, "fr.arouillard.waybar.p" + std::to_string(getpid()),
+      Gio::APPLICATION_HANDLES_COMMAND_LINE);
 
   // Initialize Waybars GTK resources with our custom icons
   auto theme = Gtk::IconTheme::get_default();
PATCH
  say "wrote $PATCH_FILE"
}

rebuild() {
  say "rebuilding ${WAYBAR_ATOM} (Portage applies ${PATCH_FILE##*/} during src_prepare)"
  # No --quiet: eapply_user's output is what tells you the patch was applied.
  emerge --oneshot --ask=n "$WAYBAR_ATOM" \
    || die "emerge failed - if it failed in eapply_user, the patch no longer matches src/client.cpp"
  say "rebuilt: $(waybar --version)"
}

status() {
  local version
  version="$(waybar_version)"
  say "waybar version:       ${version} (patch written for ${KNOWN_VERSION})"
  if patch_installed; then
    say "user patch:           present (${PATCH_FILE})"
    if patch_built_in; then
      say "binary vs patch:      binary is newer - the patch is built in"
    else
      warn "binary vs patch:      binary is OLDER than the patch - run this script with no arguments"
    fi
  else
    say "user patch:           absent - the crash is expected on reload"
  fi
  if [ "$version" != "$KNOWN_VERSION" ]; then
    warn "waybar ${version} is not the version this patch was written against; check that it still applies"
  fi
}

# A live test has to draw real bars, so it needs the desktop session.
require_desktop_session() {
  [ "$(id -u)" -ne 0 ] \
    || die "the live test needs your Wayland session; run '$0 --test' as your desktop user, not with sudo"
  [ -n "${WAYLAND_DISPLAY:-}" ] || die "WAYLAND_DISPLAY is unset; run this from a terminal inside the session"
  [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] || die "DBUS_SESSION_BUS_ADDRESS is unset; the reload path needs the session bus"
}

# Two throwaway bars, then reload both. One bar alone never crashes, so the
# second instance is the whole point: it is the one that cannot own the name.
live_test() {
  require_desktop_session

  local tmp wb cfg style
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/waybar-reload-test.XXXXXX")"
  cfg="$tmp/config"
  style="$tmp/style.css"
  printf '%s\n' '{ "layer": "top", "position": "top", "height": 30, "modules-left": ["clock"] }' >"$cfg"
  : >"$style"
  wb="$(command -v waybar)"

  say "starting two throwaway bars (a minimal 30px bar on each monitor)"
  local i
  for i in 1 2; do
    setsid "$wb" -c "$cfg" -s "$style" >"$tmp/instance-$i.log" 2>&1 </dev/null &
    sleep 2
  done

  local pids=()
  mapfile -t pids < <(pgrep -f -- "-c ${cfg}" || true)
  if [ "${#pids[@]}" -lt 2 ]; then
    warn "expected 2 test instances, found ${#pids[@]}; the result below is not conclusive"
  fi

  local pid rc=0
  for pid in "${pids[@]}"; do
    kill -USR2 "$pid" 2>/dev/null || true
    sleep 2
    if kill -0 "$pid" 2>/dev/null; then
      say "  pid ${pid}: survived reload"
    else
      say "  pid ${pid}: DIED on reload"
      rc=1
    fi
  done

  if [ "$rc" -ne 0 ]; then
    say ""
    say "reload crash reproduced. Last lines from the second instance:"
    grep -aE 'Reloading|assertion|Bail out' "$tmp/instance-2.log" 2>/dev/null || true
  fi

  # Only the instances this run started are stopped, by pid.
  for pid in "${pids[@]}"; do kill -INT "$pid" 2>/dev/null || true; done
  sleep 1
  for pid in "${pids[@]}"; do kill -9 "$pid" 2>/dev/null || true; done
  rm -rf "$tmp"
  return "$rc"
}

main() {
  case "${1:-}" in
    "")
      require_root
      write_patch
      rebuild
      status
      say ""
      say "verify with: $0 --test"
      ;;
    --check)
      status
      ;;
    --test)
      if live_test; then
        say ""
        say "PASS: every instance survived its reload"
      else
        say ""
        die "FAIL: at least one instance aborted on reload (see above)"
      fi
      ;;
    --remove)
      require_root
      if patch_installed; then
        rm -f "$PATCH_FILE"
        rmdir "$PATCH_DIR" 2>/dev/null || true
        say "removed $PATCH_FILE"
        rebuild
        say "the reload crash will come back on reloads of a non-primary bar"
      else
        note "no patch installed; nothing to remove"
      fi
      ;;
    -h | --help)
      usage
      ;;
    *)
      die "unknown argument: $1 (try --help)"
      ;;
  esac
}

main "$@"
