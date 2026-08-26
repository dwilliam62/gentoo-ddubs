#!/usr/bin/env bash
# ==============================================================================
# Script: install-fuse.sh
# Description: Installs and configures FUSE (FUSE 2 & 3) and tools necessary
#              to run AppImages seamlessly on Gentoo Linux.
# ==============================================================================

set -euo pipefail

# Ensure running as root
if [[ $EUID -ne 0 ]]; then
    echo "[!] This script must be run as root (or with sudo)." >&2
    exit 1
fi

echo "[*] Step 1: Loading kernel FUSE module and enabling persistent loading on boot..."
modprobe fuse || true

mkdir -p /etc/modules-load.d
if ! grep -qs "^fuse$" /etc/modules-load.d/fuse.conf 2>/dev/null; then
    echo "fuse" > /etc/modules-load.d/fuse.conf
    echo "[+] Added 'fuse' to /etc/modules-load.d/fuse.conf"
fi

echo "[*] Step 2: Installing FUSE 2 (libfuse.so.2), FUSE 3, and squashfs-tools..."
# sys-fs/fuse:0 provides libfuse.so.2 (strictly required by AppImage runtime)
# sys-fs/fuse:3 provides FUSE 3 and fusermount3
# sys-fs/squashfs-tools provides unsquashfs/mksquashfs for AppImage extraction
emerge --noreplace sys-fs/fuse:0 sys-fs/fuse:3 sys-fs/squashfs-tools

echo "[*] Step 3: Configuring /etc/fuse.conf for user mounting..."
if [[ -f /etc/fuse.conf ]]; then
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

echo "[*] Step 4: Ensuring /dev/fuse permissions..."
if [[ -e /dev/fuse ]]; then
    chmod 666 /dev/fuse
fi

# Add invoking user to fuse/cuse group if groups exist and user is known
TARGET_USER="${SUDO_USER:-${USER:-}}"
if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]]; then
    if getent group fuse >/dev/null 2>&1; then
        usermod -aG fuse "$TARGET_USER" || true
        echo "[+] Added user '$TARGET_USER' to 'fuse' group"
    fi
    if getent group cuse >/dev/null 2>&1; then
        usermod -aG cuse "$TARGET_USER" || true
        echo "[+] Added user '$TARGET_USER' to 'cuse' group"
    fi
fi

echo "[*] Step 5: Verifying FUSE installation..."
if [[ -f /usr/lib64/libfuse.so.2 || -f /usr/lib/libfuse.so.2 ]]; then
    echo "[+] libfuse.so.2 found (AppImage compatibility verified)."
else
    echo "[!] Warning: libfuse.so.2 was not found in /usr/lib64 or /usr/lib." >&2
fi

if command -v fusermount >/dev/null 2>&1; then
    echo "[+] fusermount available at $(command -v fusermount)"
fi

if command -v unsquashfs >/dev/null 2>&1; then
    echo "[+] unsquashfs available at $(command -v unsquashfs)"
fi

echo "[+] FUSE installation complete! You can now run AppImages."
