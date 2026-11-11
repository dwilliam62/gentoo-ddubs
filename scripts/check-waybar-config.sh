#!/usr/bin/env bash
# ==================================================
#  check-waybar-config.sh
#
#  Name the include file that stops Waybar from starting.
#
#  Symptom
#    Waybar exits before it draws anything, and all it says is
#
#      Error parsing JSON: * Line 1, Column 1
#        Syntax error: value, object or array expected.
#
#    That message is identical for every possible fault, so it does not say
#    which of the five files in the config's `include` list is at fault - and
#    with no bar on screen there is nothing else to go on. Seen on this host
#    with a zero-byte ~/.config/hypr/waybar/UserModules.
#
#  Cause
#    Waybar parses each entry of `include` as its own JSON document. jsoncpp
#    rejects an empty document with exactly the message above, and an empty
#    document is the easiest thing to end up with: truncating the file, an
#    editor saving no content, or a script that writes it conditionally.
#
#  Fix
#    A file that is only there as a placeholder needs a body - `{ }` is enough.
#    Comments on their own are not: jsoncpp still has no value to parse.
#
#  Usage
#    check-waybar-config.sh                check the running config
#    check-waybar-config.sh -c <config>    check a specific config
#    check-waybar-config.sh -q             print only the verdict
#
#  Exit status: 0 every include parses, 1 something failed, 2 cannot check.
#
#  Comments (`//`, `/* */`) and trailing commas are accepted here because
#  Waybar's jsoncpp accepts them - the KooL configs rely on both, so a
#  strict JSON parser would report faults that Waybar itself does not have.
set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

# Plain lines for the report; icons only where a status is asserted.
say() { printf '%s\n' "$*"; }
die() {
  log_err "$*"
  exit 2
}

usage() {
  cat <<'EOF'
check-waybar-config.sh - find the include file that stops Waybar

Usage:
  check-waybar-config.sh                check the running config
  check-waybar-config.sh -c <config>    check a specific config
  check-waybar-config.sh -q             print only the verdict

Waybar parses each `include` entry as its own JSON document and exits before
drawing anything if one fails, reporting only "Line 1, Column 1". This names
the file. An empty placeholder needs a body: `{ }` is enough.

Exit status: 0 every include parses, 1 something failed, 2 cannot check.
EOF
}

config=""
quiet=0
while [ $# -gt 0 ]; do
  case "$1" in
    -c)
      [ $# -ge 2 ] || die "-c needs a config path"
      config="$2"
      shift 2
      ;;
    -q)
      quiet=1
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1 (try --help)"
      ;;
  esac
done

config="${config:-${XDG_CONFIG_HOME:-$HOME/.config}/hypr/waybar/config}"
[ -f "$config" ] || die "no Waybar config at ${config}"
have python3 || die "python3 is required to parse the config"

# Waybar (jsoncpp) tolerates comments and trailing commas; this strips both so
# a document Waybar accepts is not reported as a fault, and a document it
# rejects is caught with the same "value expected" result.
read -r -d '' py_parser <<'PY' || true
import json, os, sys

def strip(text):
    out, i, n = [], 0, len(text)
    in_str = esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i = min(i + 2, n)
            continue
        out.append(c)
        i += 1
    return drop_trailing_commas("".join(out))

def drop_trailing_commas(text):
    out, i, n = [], 0, len(text)
    in_str = esc = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
            continue
        if c == '"':
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == ",":
            j = i + 1
            while j < n and text[j] in " \t\r\n":
                j += 1
            if j < n and text[j] in "}]":
                i += 1
                continue
        out.append(c)
        i += 1
    return "".join(out)

def load(path):
    with open(path, encoding="utf-8", errors="replace") as fh:
        return json.loads(strip(fh.read()))

config = sys.argv[1]
try:
    cfg = load(config)
except Exception as exc:  # noqa: BLE001 - the message is the report
    print("CONFIG\t%s\t%s" % (config, exc))
    sys.exit(2)

includes = cfg.get("include") or []
if isinstance(includes, str):
    includes = [includes]

if not includes:
    print("NOINCLUDE\t%s\t-" % config)

for inc in includes:
    path = os.path.expandvars(os.path.expanduser(str(inc)))
    if not os.path.exists(path):
        print("MISSING\t%s\t-" % path)
        continue
    if os.path.getsize(path) == 0:
        print("EMPTY\t%s\t-" % path)
        continue
    try:
        load(path)
        print("OK\t%s\t-" % path)
    except Exception as exc:  # noqa: BLE001
        print("INVALID\t%s\t%s" % (path, exc))
PY

report="$(python3 -c "$py_parser" "$config")" || die "cannot parse ${config}"

bad=0
total=0
while IFS=$'\t' read -r status path detail; do
  total=$((total + 1))
  case "$status" in
    OK)
      [ "$quiet" -eq 1 ] || say "  ok       ${path}"
      ;;
    NOINCLUDE)
      [ "$quiet" -eq 1 ] || say "  no include list in ${path}; nothing to check"
      ;;
    EMPTY)
      bad=$((bad + 1))
      say "✖ empty    ${path}"
      [ "$quiet" -eq 1 ] || say "           jsoncpp sees no value and Waybar aborts with"
      [ "$quiet" -eq 1 ] || say "           'Line 1, Column 1: value, object or array expected'"
      [ "$quiet" -eq 1 ] || say "           fix: put \`{ }\` in the file (comments alone are not enough)"
      ;;
    MISSING)
      bad=$((bad + 1))
      say "✖ missing  ${path}"
      ;;
    INVALID)
      bad=$((bad + 1))
      say "✖ invalid  ${path}"
      [ "$quiet" -eq 1 ] || say "           ${detail}"
      ;;
    CONFIG)
      bad=$((bad + 1))
      say "✖ config   ${config}"
      [ "$quiet" -eq 1 ] || say "           ${detail}"
      ;;
    *)
      bad=$((bad + 1))
      say "? unknown result for ${path}: ${status}"
      ;;
  esac
done <<<"$report"

if [ "$bad" -eq 0 ]; then
  [ "$quiet" -eq 1 ] || say "waybar config ok: ${total} include(s) in ${config}"
  exit 0
fi

say "waybar config FAILED: ${bad} of ${total} entr(ies) in ${config} will stop the bar"
exit 1
