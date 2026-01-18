#!/usr/bin/env bash
# Install Bugsvim on Gentoo with nicer output and basic safety checks.

set -euo pipefail

# -----------------------------
# Styling / icons
# -----------------------------
BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
RESET="\033[0m"

ICON_INFO="➜"
ICON_OK="✔"
ICON_WARN="⚠"
ICON_ERR="✖"
ICON_STEP="▶"

REPO_URL="https://github.com/dwilliam62/bugsvim"
TARGET_DIR="${HOME}/bugsvim"
INSTALL_SCRIPT="install-gentoo.sh"

# Show a friendly header
printf "${BOLD}${BLUE}%s${RESET}\n" "Bugsvim installer for Gentoo"
printf "${BLUE}%s${RESET}\n" "--------------------------------"

# Trap unexpected errors so the user sees a clear message.
trap 'printf "${RED}%s ${ICON_ERR} An unexpected error occurred. See messages above.${RESET}\n" "" >&2' ERR

# -----------------------------
# Helper functions
# -----------------------------
need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf "${RED}%s ${ICON_ERR} Required command '%s' not found in PATH.${RESET}\n" "" "$1" >&2
    exit 1
  fi
}

# -----------------------------
# Pre-flight checks
# -----------------------------
printf "${YELLOW}%s ${ICON_STEP} Checking system requirements...${RESET}\n" ""
need_cmd git
printf "${GREEN}%s ${ICON_OK} git found.${RESET}\n" ""

# -----------------------------
# Clone or update repository
# -----------------------------
printf "${YELLOW}%s ${ICON_STEP} Preparing Bugsvim repository...${RESET}\n" ""

if [ -d "${TARGET_DIR}" ]; then
  if [ -d "${TARGET_DIR}/.git" ]; then
    printf "${BLUE}%s ${ICON_INFO} Existing Bugsvim repo detected, updating...${RESET}\n" ""
    git -C "${TARGET_DIR}" pull --ff-only
  else
    printf "${RED}%s ${ICON_ERR} '${TARGET_DIR}' exists but is not a git repository.${RESET}\n" ""
    printf "${YELLOW}%s ${ICON_WARN} Please move or remove that directory and re-run this script.${RESET}\n" ""
    exit 1
  fi
else
  printf "${BLUE}%s ${ICON_INFO} Cloning Bugsvim into '%s'...${RESET}\n" "" "${TARGET_DIR}"
  git clone "${REPO_URL}" "${TARGET_DIR}" --depth=1
fi

printf "${GREEN}%s ${ICON_OK} Repository ready.${RESET}\n" ""

# -----------------------------
# Run project installer
# -----------------------------
printf "${YELLOW}%s ${ICON_STEP} Running Bugsvim Gentoo installer...${RESET}\n" ""

cd "${TARGET_DIR}"

if [ ! -f "${INSTALL_SCRIPT}" ]; then
  printf "${RED}%s ${ICON_ERR} Could not find '%s' in '%s'.${RESET}\n" "" "${INSTALL_SCRIPT}" "${TARGET_DIR}" >&2
  exit 1
fi

if [ ! -x "${INSTALL_SCRIPT}" ]; then
  chmod +x "${INSTALL_SCRIPT}" || {
    printf "${RED}%s ${ICON_ERR} Failed to mark '%s' as executable.${RESET}\n" "" "${INSTALL_SCRIPT}" >&2
    exit 1
  }
fi

"./${INSTALL_SCRIPT}"

cd "${HOME}"

printf "${GREEN}%s ${ICON_OK} Bugsvim installation completed successfully.${RESET}\n" ""
