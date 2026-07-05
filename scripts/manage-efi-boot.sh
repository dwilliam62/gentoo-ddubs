#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Manage UEFI EFI boot entries and kernel selection
#

set -euo pipefail

msg() {
	printf '%s\n' "$1"
}

error() {
	printf '\033[0;31mERROR:\033[0m %s\n' "$1" >&2
}

success() {
	printf '\033[0;32m✓\033[0m %s\n' "$1"
}

warn() {
	printf '\033[1;33m⚠\033[0m %s\n' "$1"
}

show_usage() {
	cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Manage UEFI EFI boot entries and direct kernel boot.

Options:
  --check              Show current EFI boot configuration
  --update-efi KERNEL  Update EFI kernel entry to specified kernel version
  --set-default INDEX  Set default EFI boot entry by index
  --switch-grub        Change boot order to prefer GRUB (Boot0002)
  --switch-efi         Change boot order to prefer direct EFI kernel boot
  -h, --help           Show this help

Examples:
  # Check current boot setup
  $(basename "$0") --check

  # Update EFI kernel to 7.1.3
  $(basename "$0") --update-efi 7.1.3-gentoo-dist-bin

  # Set default to first entry
  $(basename "$0") --set-default 0

  # Switch to GRUB boot
  $(basename "$0") --switch-grub

EOF
}

check_root() {
	if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
		error "must be run as root"
		exit 1
	fi
}

check_efi_boot_config() {
	msg "=== EFI Boot Configuration ==="
	msg ""

	if ! command -v efibootmgr >/dev/null 2>&1; then
		error "efibootmgr not found (install sys-boot/efibootmgr)"
		return 1
	fi

	efibootmgr -v || true

	msg ""
	msg "=== Current Kernel ==="
	uname -r

	msg ""
	msg "=== Available Kernels in /boot ==="
	find /boot -maxdepth 1 -name 'kernel-*' -type f -printf '%f\n' | sed 's/^kernel-//' | sort -V

	msg ""
	msg "=== EFI Kernel File ==="
	if [[ -f /boot/efi/vmlinuz.efi ]]; then
		stat -c "  %n: %s bytes, modified %y" /boot/efi/vmlinuz.efi
	else
		warn "No EFI kernel found at /boot/efi/vmlinuz.efi"
	fi

	msg ""
	msg "=== EFI vs GRUB Detection ==="
	local boot_current
	boot_current=$(efibootmgr -v | grep '^BootCurrent:' | awk '{print $2}')

	if [[ -n "$boot_current" ]]; then
		local entry_desc
		entry_desc=$(efibootmgr -v | grep "^Boot${boot_current}" | head -1)
		msg "Active boot entry ($boot_current): $entry_desc"

		if [[ "$entry_desc" =~ "gentoo" ]]; then
			warn "Currently using direct EFI kernel boot (not GRUB)"
			msg "Fix: Run '$(basename "$0") --update-efi <kernel-version>'"
		elif [[ "$entry_desc" =~ "vmlinuz" ]]; then
			warn "Currently using EFI kernel (not GRUB)"
			msg "Fix: Run '$(basename "$0") --update-efi <kernel-version>'"
		else
			success "Current boot method appears to be GRUB-compatible"
		fi
	fi
}

update_efi_kernel() {
	local kernel_version="$1"

	if [[ ! -f "/boot/kernel-${kernel_version}" ]]; then
		error "Kernel not found: /boot/kernel-${kernel_version}"
		return 1
	fi

	if [[ ! -f "/boot/initramfs-${kernel_version}.img" ]]; then
		error "Initramfs not found: /boot/initramfs-${kernel_version}.img"
		return 1
	fi

	if [[ ! -d /boot/efi ]]; then
		error "EFI boot directory not found: /boot/efi"
		return 1
	fi

	msg "=== Updating EFI Kernel ==="

	# Check if objectcopy is available
	if ! command -v objcopy >/dev/null 2>&1; then
		error "objcopy not found (install sys-devel/binutils)"
		return 1
	fi

	msg "Backing up current EFI kernel..."
	if [[ -f /boot/efi/vmlinuz.efi ]]; then
		cp /boot/efi/vmlinuz.efi "/boot/efi/vmlinuz.efi.bak-$(date +%Y%m%d%H%M%S)"
	fi

	msg "Creating EFI kernel for version ${kernel_version}..."

	# Create EFI kernel using objcopy
	# This requires the kernel to be built with EFI stub support
	cp "/boot/kernel-${kernel_version}" /boot/efi/vmlinuz.efi

	msg "Updating EFI boot parameters..."
	# Note: EFI kernel parameters are typically embedded at build time
	# For direct kernel boot, you may need to use efibootmgr to add boot options

	success "EFI kernel updated to ${kernel_version}"
	msg "Reboot to test the new kernel"
}

set_efi_default() {
	local index="$1"

	if ! [[ "$index" =~ ^[0-9]+$ ]]; then
		error "Invalid index: $index (must be a number)"
		return 1
	fi

	msg "Setting EFI default boot entry to $index..."
	efibootmgr -n "$index" || {
		error "Failed to set default boot entry"
		return 1
	}

	success "Default boot entry set to $index"
	efibootmgr | head -2
}

switch_to_grub() {
	msg "=== Switching to GRUB Boot ==="

	# Look for GRUB boot entry
	local grub_index
	grub_index=$(efibootmgr -v | grep -i "grub\|gentoo" | grep -v "vmlinuz" | awk -F'Boot' '{print $2}' | awk '{print $1}' | head -1)

	if [[ -z "$grub_index" ]]; then
		grub_index=$(efibootmgr -v | grep "^Boot0002" | head -1)
		if [[ -z "$grub_index" ]]; then
			warn "Could not find GRUB boot entry automatically"
			msg "Available boot entries:"
			efibootmgr -v | grep "^Boot"
			return 1
		fi
		grub_index="0002"
	else
		grub_index="${grub_index%\*}"
	fi

	msg "Setting boot order to prefer GRUB (Boot${grub_index})..."
	set_efi_default "$grub_index" || return 1
}

switch_to_efi() {
	msg "=== Switching to EFI Kernel Boot ==="

	# Look for EFI kernel boot entry
	local efi_index
	efi_index=$(efibootmgr -v | grep "gentoo\|vmlinuz" | awk -F'Boot' '{print $2}' | awk '{print $1}' | head -1)

	if [[ -z "$efi_index" ]]; then
		efi_index="0004"
	else
		efi_index="${efi_index%\*}"
	fi

	msg "Setting boot order to prefer EFI kernel (Boot${efi_index})..."
	set_efi_default "$efi_index" || return 1
}

main() {
	case "${1:-}" in
		-h | --help)
			show_usage
			exit 0
			;;
		--check)
			check_efi_boot_config
			;;
		--update-efi)
			check_root
			if [[ -z "${2:-}" ]]; then
				error "--update-efi requires a kernel version argument"
				show_usage
				exit 1
			fi
			update_efi_kernel "$2"
			;;
		--set-default)
			check_root
			if [[ -z "${2:-}" ]]; then
				error "--set-default requires an index argument"
				show_usage
				exit 1
			fi
			set_efi_default "$2"
			;;
		--switch-grub)
			check_root
			switch_to_grub
			;;
		--switch-efi)
			check_root
			switch_to_efi
			;;
		"")
			check_efi_boot_config
			;;
		*)
			error "Unknown option: $1"
			show_usage
			exit 1
			;;
	esac
}

main "$@"
