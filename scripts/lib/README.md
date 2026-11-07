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
| `portage_backup_file /etc/portage/package.use/foo` | copies an existing config file to `${PORTAGE_BACKUP_DIR:-/root/portage-backups}` |
| `portage_write_file /etc/portage/package.use/foo <<'EOF' ... EOF` | replaces a config file from stdin, backing up the old contents first and skipping the write when they already match |
| `warn_drift_from_managed /etc/portage/package.use/foo "$content"` | reports entries the existing file holds that the new contents would drop (call it just before `portage_write_file`) |

`warn_drift_from_managed` normalizes **both** sides (comments stripped,
whitespace collapsed, lines trimmed) before comparing, so an indented or
space-padded file does not report entries it actually still writes. It is meant
for one-entry-per-line Portage files; don't run it over a shell script.

`portage_write_file` is the way to rewrite a file the script owns: a rerun with
identical contents leaves the file alone, and a changed file is preserved first.
Backups deliberately live **outside** `/etc/portage` (default
`/root/portage-backups`, override with `PORTAGE_BACKUP_DIR`) because Portage
reads every regular file inside a `package.*` directory — a
`foo.bak-<stamp>` left next to the original would become live configuration.
Host-specific additions therefore belong in a separate snippet (for example
`package.use/contour-extra`), not in the file a script manages. Pair a managed
write with `warn_drift_from_managed "$path" "$content"` so the run says which
of those additions it is about to drop instead of removing them silently.
