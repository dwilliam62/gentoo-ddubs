#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"

if [[ ! -x "${INSTALL_SCRIPT}" ]]; then
  echo "Error: install script not found or not executable at ${INSTALL_SCRIPT}" >&2
  exit 1
fi

exec "${INSTALL_SCRIPT}" --update-only "$@"
