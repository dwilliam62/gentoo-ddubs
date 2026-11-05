# scripts/lib/common.sh

Shared helpers for every script in `scripts/`. Each script sources it like this:

```bash
SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}
```

The stanza is safe under `set -euo pipefail` and keeps any `SCRIPT_DIR` the
script already computed.

## Output

| helper | use |
|---|---|
| `say "msg"` | timestamped progress line (`[HH:MM:SS] msg`) |
| `log_info` / `log_ok` / `log_warn` / `log_err` | ℹ / ✔ / ⚠ / ✖ prefixed lines (warn and err go to stderr) |
| `die "msg"` | `log_err` then `exit 1` |
| `step "heading"` | section heading (`==> ...`) |
| `run_step "label" cmd ...` | runs a command, records failure, never aborts the caller |
| `run_summary` | prints steps/failures; returns non-zero if any step failed |

Colour is disabled automatically when stdout is not a terminal, when
`NO_COLOR` is set, or when `TERM=dumb`, so redirected reports stay clean.

## Commands and privileges

| helper | use |
|---|---|
| `have cmd` | true when `cmd` is in `PATH` |
| `require_cmd cmd ...` | dies listing every missing command |
| `need_root "$@"` | re-executes the script under `sudo -E`, forwarding arguments |
| `require_root` | dies unless already root (for flows that must not re-exec) |

## Portage

| helper | use |
|---|---|
| `portage_conf_file /etc/portage/package.mask foo` | `.../package.mask/foo` when that path is a directory, otherwise the file itself |
| `pkg_installed atom` | installed check via `qlist`, falling back to `portageq` |
| `version_ge actual required` | `sort -V` version comparison |
