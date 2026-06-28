#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"

if [[ ! -x "${INSTALL_SCRIPT}" ]]; then
  echo "Error: install script not found or not executable at ${INSTALL_SCRIPT}" >&2
  exit 1
fi
missing=()
for bin in picom virt-viewer; do
  if ! command -v "${bin}" >/dev/null 2>&1; then
    missing+=("${bin}")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Warning: missing runtime tools: ${missing[*]}" >&2
  echo "Run oxwm/scripts/install.sh (without --update-only) or install them manually." >&2
fi

exec "${INSTALL_SCRIPT}" --update-only "$@"
