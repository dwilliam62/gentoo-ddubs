#!/usr/bin/env bash
#
# Script: set-glaze-7-hl-fix.sh
# Purpose: Detect and fix Hyprland 0.56.x build failure caused by dev-cpp/glaze-8.x.
#          Hyprland CMakeLists.txt strictly requires glaze version 7...<8.
#          When glaze-8 is present, CMake falls back to FetchContent git clone,
#          which fails inside Portage's network-sandbox.
#
# Steps performed:
#   1. Detects installed glaze version and mask status.
#   2. Ensures hyproverlay repo is available.
#   3. Masks >=dev-cpp/glaze-8 in /etc/portage/package.mask/glaze.
#   4. Downgrades/installs dev-cpp/glaze-7.0.2 from hyproverlay.
#   5. Rebuilds gui-wm/hyprland.
#   6. Runs emerge @preserved-rebuild to fix preserved libraries (e.g. aquamarine).
#   7. Prints a clear status summary of all operations.
#

set -euo pipefail

# ANSI color codes
BOLD="\033[1m"
DIM="\033[2m"
RESET="\033[0m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
WHITE="\033[1;37m"

MASK_FILE="/etc/portage/package.mask/glaze"
TARGET_GLAZE_ATOM="=dev-cpp/glaze-7.0.2::hyproverlay"
FALLBACK_GLAZE_ATOM="<dev-cpp/glaze-8"

CHECK_ONLY=false
AUTO_YES=false
SKIP_PRESERVED=false
MASK_GLAZE_ONLY=false
REBUILD_HYPRLAND=false

print_usage() {
  printf "%b" "\
${BOLD}Usage:${RESET}
  sudo bash scripts/set-glaze-7-hl-fix.sh [OPTIONS]

${BOLD}Options:${RESET}
  -c, --check, --dry-run   Check host status without making any changes
  -m, --mask-glaze         Apply mask for >=dev-cpp/glaze-8 if not found and exit
  -r, --rebuild-hyprland   Rebuild gui-wm/hyprland without prompting
  -y, --auto-yes           Proceed with all operations without confirmation
  --skip-preserved         Skip running 'emerge @preserved-rebuild'
  -h, --help               Show this help message and exit

${BOLD}Description:${RESET}
  Hyprland 0.56.x requires dev-cpp/glaze >=7 and <8. If glaze-8 is installed
  (from ::gentoo), Hyprland fails during emerge because CMake tries to clone
  glaze-7 via FetchContent, which is blocked by Portage's network sandbox.

  This script checks host state, allows applying the >=dev-cpp/glaze-8 mask,
  ensures glaze 7.x from ::hyproverlay is installed, and optionally rebuilds
  Hyprland and preserved libraries.
"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    -c | --check | --dry-run)
      CHECK_ONLY=true
      shift
      ;;
    -m | --mask-glaze)
      MASK_GLAZE_ONLY=true
      shift
      ;;
    -r | --rebuild-hyprland)
      REBUILD_HYPRLAND=true
      shift
      ;;
    -y | --auto-yes)
      AUTO_YES=true
      shift
      ;;
    --skip-preserved)
      SKIP_PRESERVED=true
      shift
      ;;
    -h | --help)
      print_usage
      exit 0
      ;;
    *)
      printf "%bUnknown option: %s%b\n\n" "${RED}" "$1" "${RESET}" >&2
      print_usage
      exit 1
      ;;
  esac
done

# Require root unless running in check-only mode
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  if [ "$CHECK_ONLY" = true ]; then
    printf "%b[NOTE] Running check-only mode as non-root user.%b\n\n" "${DIM}" "${RESET}"
  else
    if command -v sudo >/dev/null 2>&1; then
      printf "%bEscalating to root privileges via sudo...%b\n" "${CYAN}" "${RESET}"
      exec sudo bash "$0" "$@"
    else
      printf "%bError: Root privileges required. Please run with sudo or as root.%b\n" "${RED}" "${RESET}" >&2
      exit 1
    fi
  fi
fi

# Helper functions
log_step() {
  printf "\n%b==>%b %b%s%b\n" "${CYAN}" "${RESET}" "${BOLD}" "$1" "${RESET}"
}

log_info() {
  printf "  %bℹ%b %s\n" "${CYAN}" "${RESET}" "$1"
}

log_ok() {
  printf "  %b✔%b %s\n" "${GREEN}" "${RESET}" "$1"
}

log_warn() {
  printf "  %b⚠%b %s\n" "${YELLOW}" "${RESET}" "$1"
}

log_err() {
  printf "  %b✘%b %s\n" "${RED}" "${RESET}" "$1"
}

get_installed_pkg() {
  local pkg="$1"
  qlist -Iv "$pkg" 2>/dev/null | head -n 1 || true
}

is_glaze8_masked() {
  grep -rqs ">=dev-cpp/glaze-8" /etc/portage/package.mask /etc/portage/package.mask.conf 2>/dev/null \
    || grep -rqs "dev-cpp/glaze:8" /etc/portage/package.mask 2>/dev/null
}

# Status tracking
STATUS_MASK="NOT_CHECKED"
STATUS_GLAZE_PKG="NOT_CHECKED"
STATUS_HYPRLAND_BUILD="SKIPPED"
STATUS_PRESERVED="SKIPPED"
OVERALL_RESULT="UNKNOWN"

INITIAL_GLAZE=$(get_installed_pkg "dev-cpp/glaze")
INITIAL_HYPRLAND=$(get_installed_pkg "gui-wm/hyprland")

printf "%b╭──────────────────────────────────────────────────────────────────────────╮%b\n" "${CYAN}" "${RESET}"
printf "%b│          %b  HYPRLAND GLAZE-7 FIX & REBUILD AUTOMATION%b                  %b│%b\n" "${CYAN}" "${WHITE}" "${CYAN}" "${CYAN}" "${RESET}"
printf "%b╰──────────────────────────────────────────────────────────────────────────╯%b\n\n" "${CYAN}" "${RESET}"

log_info "Host:       $(hostname 2>/dev/null || uname -n)"
log_info "Date:       $(date '+%Y-%m-%d %H:%M:%S')"
log_info "Hyprland:   ${INITIAL_HYPRLAND:-Not installed}"
log_info "Glaze:      ${INITIAL_GLAZE:-Not installed}"

# Check hyproverlay availability
if command -v eselect >/dev/null 2>&1 && eselect repository list >/dev/null 2>&1; then
  if eselect repository list 2>/dev/null | awk '/\*/ {print $2}' | grep -qx 'hyproverlay'; then
    log_ok "Repository 'hyproverlay' is enabled"
  else
    log_warn "Repository 'hyproverlay' is not enabled"
    if [ "$CHECK_ONLY" = false ]; then
      log_info "Attempting to enable 'hyproverlay' via eselect repository..."
      eselect repository enable hyproverlay || log_warn "Could not enable hyproverlay automatically"
    fi
  fi
fi

# Detect Issue
GLAZE_ISSUE=false
REBUILD_NEEDED=false

if is_glaze8_masked; then
  log_ok "Portage mask for >=dev-cpp/glaze-8 is active"
  STATUS_MASK="ALREADY_ACTIVE"
else
  log_warn "Portage mask for >=dev-cpp/glaze-8 is MISSING"
  STATUS_MASK="MISSING"
  GLAZE_ISSUE=true
fi

if [[ "$INITIAL_GLAZE" =~ glaze-8 ]]; then
  log_warn "Incompatible glaze version detected: $INITIAL_GLAZE (needs 7.x)"
  STATUS_GLAZE_PKG="NEEDS_DOWNGRADE"
  GLAZE_ISSUE=true
elif [[ "$INITIAL_GLAZE" =~ glaze-7 ]]; then
  log_ok "Compatible glaze 7.x is installed: $INITIAL_GLAZE"
  STATUS_GLAZE_PKG="ALREADY_OK"
else
  log_warn "Glaze 7.x is not installed (current: ${INITIAL_GLAZE:-none})"
  STATUS_GLAZE_PKG="NEEDS_INSTALL"
  GLAZE_ISSUE=true
fi

# Check if preserved libs require rebuild
PRESERVED_OUTPUT=$(emerge -p @preserved-rebuild 2>/dev/null || true)
if echo "$PRESERVED_OUTPUT" | grep -q "gui-wm/hyprland"; then
  log_warn "Hyprland rebuild is pending (preserved libraries detected, e.g. aquamarine)"
  REBUILD_NEEDED=true
fi

# Stop here if check-only mode
if [ "$CHECK_ONLY" = true ]; then
  log_step "Check Complete (Dry Run Mode)"
  if [ "$GLAZE_ISSUE" = true ]; then
    log_warn "Host is AFFECTED: Glaze 8 is present or unmasked."
    printf "      Run with '--mask-glaze' to apply the mask and exit, or run without options\\n"
    printf "      to interactively apply the mask and rebuild Hyprland when needed.\\n\\n"
  elif [ "$REBUILD_NEEDED" = true ]; then
    log_warn "Glaze 7 is configured, but Hyprland requires a rebuild for updated libraries."
    printf "      Run with '--rebuild-hyprland' to rebuild Hyprland and resolve preserved libraries.\\n\\n"
  else
    log_ok "Host is CLEAN: Glaze 7.x is active, properly masked, and Hyprland is up to date.\\n\\n"
  fi
  exit 0
fi

# Flag --mask-glaze: if mask not found, apply mask and exit
if [ "$MASK_GLAZE_ONLY" = true ]; then
  log_step "Applying Portage mask for >=dev-cpp/glaze-8 (--mask-glaze)"
  if [ "$STATUS_MASK" = "ALREADY_ACTIVE" ]; then
    log_ok "Portage mask for >=dev-cpp/glaze-8 is already active ($MASK_FILE)"
  else
    mkdir -p "$(dirname "$MASK_FILE")"
    cat <<'EOF' >"$MASK_FILE"
# Mask dev-cpp/glaze 8.x:
# Hyprland 0.56.x CMake strictly requires glaze version 7...<8.
# Glaze 8 causes CMake FetchContent to attempt network downloads during emerge.
>=dev-cpp/glaze-8
EOF
    log_ok "Created $MASK_FILE with rule: '>=dev-cpp/glaze-8'"
    STATUS_MASK="APPLIED"
  fi
  printf "\n%b[DONE] Exiting as requested by --mask-glaze.%b\n\n" "${GREEN}" "${RESET}"
  exit 0
fi

# -----------------------------------------------------------------------------
# Question 1: When mask for glaze is not found, ask to apply mask
# -----------------------------------------------------------------------------
DO_APPLY_MASK=false
if [ "$STATUS_MASK" = "ALREADY_ACTIVE" ]; then
  DO_APPLY_MASK=true
else
  if [ "$AUTO_YES" = true ]; then
    DO_APPLY_MASK=true
  else
    printf "\n%bPortage mask for >=dev-cpp/glaze-8 is missing. Apply mask now? [y/N]: %b" "${BOLD}" "${RESET}"
    read -r response
    case "$response" in
      [yY] | [yY][eE][sS])
        DO_APPLY_MASK=true
        ;;
      *)
        DO_APPLY_MASK=false
        log_warn "Skipping mask application for >=dev-cpp/glaze-8."
        STATUS_MASK="SKIPPED"
        ;;
    esac
  fi
fi

# Step 1: Apply package mask for glaze >= 8
if [ "$DO_APPLY_MASK" = true ]; then
  log_step "Step 1: Applying Portage mask for >=dev-cpp/glaze-8"
  if [ "$STATUS_MASK" = "ALREADY_ACTIVE" ]; then
    log_ok "Mask is already active; no modification needed."
  else
    mkdir -p "$(dirname "$MASK_FILE")"
    cat <<'EOF' >"$MASK_FILE"
# Mask dev-cpp/glaze 8.x:
# Hyprland 0.56.x CMake strictly requires glaze version 7...<8.
# Glaze 8 causes CMake FetchContent to attempt network downloads during emerge.
>=dev-cpp/glaze-8
EOF
    log_ok "Created $MASK_FILE with rule: '>=dev-cpp/glaze-8'"
    STATUS_MASK="APPLIED"
  fi

  # Step 2: Ensure dev-cpp/glaze 7.x is installed
  log_step "Step 2: Ensuring dev-cpp/glaze-7.x is installed"
  CURRENT_GLAZE=$(get_installed_pkg "dev-cpp/glaze")
  if [[ "$CURRENT_GLAZE" =~ glaze-7 ]] && [ "$STATUS_GLAZE_PKG" = "ALREADY_OK" ]; then
    log_ok "Glaze 7.x is already installed ($CURRENT_GLAZE)."
    STATUS_GLAZE_PKG="ALREADY_OK"
  else
    log_info "Merging glaze 7.x..."
    if emerge -1v --oneshot "$TARGET_GLAZE_ATOM"; then
      STATUS_GLAZE_PKG="SUCCESS"
      log_ok "Successfully merged $TARGET_GLAZE_ATOM"
    elif emerge -1v --oneshot "$FALLBACK_GLAZE_ATOM"; then
      STATUS_GLAZE_PKG="SUCCESS"
      log_ok "Successfully merged $FALLBACK_GLAZE_ATOM"
    else
      STATUS_GLAZE_PKG="FAILED"
      log_err "Failed to emerge glaze 7.x"
      OVERALL_RESULT="FAILED"
    fi
  fi
fi

POST_GLAZE=$(get_installed_pkg "dev-cpp/glaze")
log_info "Installed glaze package: ${POST_GLAZE:-none}"

# -----------------------------------------------------------------------------
# Question 2: Ask to rebuild Hyprland (might not be needed yet)
# -----------------------------------------------------------------------------
DO_REBUILD_HYPRLAND=false
if [ "$REBUILD_HYPRLAND" = true ] || [ "$AUTO_YES" = true ]; then
  DO_REBUILD_HYPRLAND=true
else
  printf "\n%bRebuild gui-wm/hyprland now? [y/N]: %b" "${BOLD}" "${RESET}"
  read -r response
  case "$response" in
    [yY] | [yY][eE][sS])
      DO_REBUILD_HYPRLAND=true
      ;;
    *)
      DO_REBUILD_HYPRLAND=false
      log_info "Skipping Hyprland rebuild (not needed yet)."
      STATUS_HYPRLAND_BUILD="SKIPPED"
      STATUS_PRESERVED="SKIPPED"
      ;;
  esac
fi

# Step 3: Rebuild gui-wm/hyprland
if [ "$DO_REBUILD_HYPRLAND" = true ]; then
  log_step "Step 3: Rebuilding gui-wm/hyprland"
  if [ "$STATUS_GLAZE_PKG" = "FAILED" ]; then
    log_err "Skipping Hyprland rebuild because glaze installation failed."
    STATUS_HYPRLAND_BUILD="SKIPPED"
    OVERALL_RESULT="FAILED"
  else
    log_info "Running: emerge -1v --oneshot gui-wm/hyprland"
    if emerge -1v --oneshot gui-wm/hyprland; then
      STATUS_HYPRLAND_BUILD="SUCCESS"
      log_ok "Hyprland rebuilt successfully!"
    else
      STATUS_HYPRLAND_BUILD="FAILED"
      log_err "Hyprland rebuild failed! Check /var/tmp/portage/gui-wm/hyprland-*/temp/build.log"
      OVERALL_RESULT="FAILED"
    fi
  fi

  # Step 4: Handle preserved libraries
  log_step "Step 4: Checking preserved libraries (@preserved-rebuild)"
  if [ "$SKIP_PRESERVED" = true ]; then
    log_info "Skipping @preserved-rebuild as requested via --skip-preserved."
    STATUS_PRESERVED="SKIPPED"
  else
    PRESERVED_CHECK=$(emerge -p @preserved-rebuild 2>/dev/null || true)
    if echo "$PRESERVED_CHECK" | grep -q "ebuild"; then
      log_info "Preserved rebuild targets found. Running emerge @preserved-rebuild..."
      if emerge @preserved-rebuild; then
        STATUS_PRESERVED="SUCCESS"
        log_ok "@preserved-rebuild completed successfully."
      else
        STATUS_PRESERVED="FAILED"
        log_err "@preserved-rebuild failed."
        OVERALL_RESULT="FAILED"
      fi
    else
      log_ok "No preserved library rebuilds needed."
      STATUS_PRESERVED="CLEAN"
    fi
  fi
fi

# Final overall status calculation
if [ "$STATUS_GLAZE_PKG" = "FAILED" ] || [ "$STATUS_HYPRLAND_BUILD" = "FAILED" ] || [ "$STATUS_PRESERVED" = "FAILED" ]; then
  OVERALL_RESULT="FAILED"
elif [ "$STATUS_HYPRLAND_BUILD" = "SUCCESS" ]; then
  OVERALL_RESULT="SUCCESS"
else
  OVERALL_RESULT="COMPLETED"
fi

# -----------------------------------------------------------------------------
# Summary Report
# -----------------------------------------------------------------------------
printf "\n"
printf "  %b╭──────────────────────────────────────────────────────────────────────────╮%b\n" "${CYAN}" "${RESET}"
printf "  %b│                            %bEXECUTION SUMMARY%b                            %b│%b\n" "${CYAN}" "${WHITE}" "${CYAN}" "${CYAN}" "${RESET}"
printf "  %b╰──────────────────────────────────────────────────────────────────────────╯%b\n\n" "${CYAN}" "${RESET}"

format_status() {
  case "$1" in
    SUCCESS | ALREADY_OK | CLEAN)
      printf "%b✔ %s%b" "${GREEN}" "$1" "${RESET}"
      ;;
    APPLIED | ALREADY_ACTIVE)
      printf "%b✔ %s%b" "${GREEN}" "$1" "${RESET}"
      ;;
    SKIPPED)
      printf "%b- %s%b" "${DIM}" "$1" "${RESET}"
      ;;
    FAILED)
      printf "%b✘ %s%b" "${RED}" "$1" "${RESET}"
      ;;
    *)
      printf "%b%s%b" "${YELLOW}" "$1" "${RESET}"
      ;;
  esac
}

printf "  ${BOLD}%-26s %s${RESET}\n" "COMPONENT" "STATUS"
printf "  ${DIM}%-26s %s${RESET}\n" "──────────────────────────" "────────────────────────────────"
printf "  %-26s $(format_status "$STATUS_MASK")\n" "Portage Mask (glaze>=8):"
printf "  %-26s %s -> %s\n" "Glaze Version:" "${INITIAL_GLAZE:-none}" "${POST_GLAZE:-none}"
printf "  %-26s $(format_status "$STATUS_GLAZE_PKG")\n" "Glaze 7 Package:"
printf "  %-26s $(format_status "$STATUS_HYPRLAND_BUILD")\n" "Hyprland Rebuild:"
printf "  %-26s $(format_status "$STATUS_PRESERVED")\n" "Preserved Rebuild:"
printf "  ${DIM}%-26s %s${RESET}\n" "──────────────────────────" "────────────────────────────────"

if [ "$OVERALL_RESULT" = "SUCCESS" ]; then
  printf "  ${BOLD}%-26s %b✔ PASSED (Hyprland build & fix verified)%b${RESET}\\n\\n" "OVERALL RESULT:" "${GREEN}" "${RESET}"
  exit 0
elif [ "$OVERALL_RESULT" = "COMPLETED" ]; then
  printf "  ${BOLD}%-26s %b✔ COMPLETED (Configuration applied; Hyprland rebuild not requested)%b${RESET}\\n\\n" "OVERALL RESULT:" "${GREEN}" "${RESET}"
  exit 0
else
  printf "  ${BOLD}%-26s %b✘ FAILED (Check logs above for details)%b${RESET}\\n\\n" "OVERALL RESULT:" "${RED}" "${RESET}"
  exit 1
fi
