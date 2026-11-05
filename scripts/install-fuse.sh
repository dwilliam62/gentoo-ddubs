#!/usr/bin/env bash
# ==============================================================================
# Script: install-fuse.sh
# Description: Installs and configures FUSE (FUSE 2 & 3) and tools necessary
#              to run AppImages seamlessly on Gentoo Linux.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

require_root
require_cmd emerge

step "Step 1: Loading kernel FUSE module and enabling persistent loading on boot..."
modprobe fuse || log_warn "modprobe fuse failed; the module may already be loaded or built in."

mkdir -p /etc/modules-load.d
if grep -qs "^fuse$" /etc/modules-load.d/fuse.conf 2>/dev/null; then
  log_info "'fuse' already listed in /etc/modules-load.d/fuse.conf"
else
  echo "fuse" > /etc/modules-load.d/fuse.conf
  log_ok "Added 'fuse' to /etc/modules-load.d/fuse.conf"
fi

step "Step 2: Installing FUSE 2 (libfuse.so.2), FUSE 3, and squashfs-tools..."
# sys-fs/fuse:0 provides libfuse.so.2 (strictly required by AppImage runtime)
# sys-fs/fuse:3 provides FUSE 3 and fusermount3
# sys-fs/squashfs-tools provides unsquashfs/mksquashfs for AppImage extraction
emerge --noreplace sys-fs/fuse:0 sys-fs/fuse:3 sys-fs/squashfs-tools ||
  die "failed to install the FUSE packages."

step "Step 3: Configuring /etc/fuse.conf for user mounting..."
if [ -f /etc/fuse.conf ]; then
  if grep -q "^#user_allow_other" /etc/fuse.conf; then
    sed -i 's/^#user_allow_other/user_allow_other/' /etc/fuse.conf
  elif ! grep -q "^user_allow_other" /etc/fuse.conf; then
    echo "user_allow_other" >> /etc/fuse.conf
  fi
else
  cat << 'EOF' > /etc/fuse.conf
# /etc/fuse.conf
# Allows non-root users to specify the allow_other mount option
user_allow_other
EOF
fi
chmod 644 /etc/fuse.conf
log_ok "user_allow_other enabled in /etc/fuse.conf"

step "Step 4: Ensuring /dev/fuse permissions..."
if [ -e /dev/fuse ]; then
  chmod 666 /dev/fuse
  log_ok "/dev/fuse is world read/write"
else
  log_warn "/dev/fuse not found; load the fuse module before relying on AppImages."
fi

# Add invoking user to fuse/cuse group if groups exist and user is known
TARGET_USER="${SUDO_USER:-${USER:-}}"
if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
  if getent group fuse >/dev/null 2>&1; then
    usermod -aG fuse "$TARGET_USER" || log_warn "could not add ${TARGET_USER} to the fuse group"
    log_ok "Added user '${TARGET_USER}' to 'fuse' group"
  fi
  if getent group cuse >/dev/null 2>&1; then
    usermod -aG cuse "$TARGET_USER" || log_warn "could not add ${TARGET_USER} to the cuse group"
    log_ok "Added user '${TARGET_USER}' to 'cuse' group"
  fi
fi

step "Step 5: Verifying FUSE installation..."
# libfuse.so.2 is normally a symlink, so test with -e rather than -f.
if [ -e /usr/lib64/libfuse.so.2 ] || [ -e /usr/lib/libfuse.so.2 ]; then
  log_ok "libfuse.so.2 found (AppImage compatibility verified)."
else
  log_warn "libfuse.so.2 was not found in /usr/lib64 or /usr/lib."
fi

if have fusermount; then
  log_ok "fusermount available at $(command -v fusermount)"
else
  log_warn "fusermount not found in PATH"
fi

if have unsquashfs; then
  log_ok "unsquashfs available at $(command -v unsquashfs)"
else
  log_warn "unsquashfs not found in PATH"
fi

log_ok "FUSE installation complete! You can now run AppImages."
