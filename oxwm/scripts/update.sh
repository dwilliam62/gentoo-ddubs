#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="${SCRIPT_DIR}/install.sh"
REQUIRED_RUNTIME_TOOLS=(picom xwallpaper flameshot feh)

if [[ ! -x "${INSTALL_SCRIPT}" ]]; then
  echo "Error: install script not found or not executable at ${INSTALL_SCRIPT}" >&2
  exit 1
fi

check_runtime_tools() {
  local missing=()
  local tool

  for tool in "${REQUIRED_RUNTIME_TOOLS[@]}"; do
    command -v "${tool}" >/dev/null 2>&1 || missing+=("${tool}")
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Error: missing required OxWM runtime tools after update: ${missing[*]}" >&2
    return 1
  fi

  echo "Verified OxWM runtime tools: ${REQUIRED_RUNTIME_TOOLS[*]}"
}

"${INSTALL_SCRIPT}" --update-only "$@"
check_runtime_tools
