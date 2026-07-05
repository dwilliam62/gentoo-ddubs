#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Install GRUB as EFI bootloader
# Replaces direct kernel EFI boot with GRUB
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

Install GRUB as the EFI bootloader, replacing direct kernel EFI boot.

Options:
  --check              Check if GRUB is installed and verify setup
  --install            Install GRUB to EFI partition
  --regen              Regenerate GRUB config after install
  --full               Full install: --install + --regen (recommended)
  --help               Show this help

Examples:
  # Check current setup
  $(basename "$0") --check

  # Full GRUB installation (install + regenerate config)
  $(basename "$0") --full

  # Install only (without regenerating config)
  $(basename "$0") --install

  # Just regenerate config
  $(basename "$0") --regen

EOF
}

check_root() {
	if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
		error "must be run as root"
		exit 1
	fi
}

verify_efi_system() {
	msg "=== Verifying EFI System Setup ==="

	if [[ ! -d /sys/firmware/efi ]]; then
		error "System is not EFI (no /sys/firmware/efi found)"
		return 1
	fi
	success "System is EFI-enabled"

	if [[ ! -d /boot/efi ]]; then
		error "EFI partition not mounted at /boot/efi"
		return 1
	fi
	success "EFI partition mounted at /boot/efi"

	if ! command -v grub-install >/dev/null 2>&1; then
		error "grub-install not found (install sys-boot/grub)"
		return 1
	fi
	success "GRUB tools are installed"

	if ! command -v grub-mkconfig >/dev/null 2>&1; then
		error "grub-mkconfig not found"
		return 1
	fi
	success "GRUB config generator available"

	msg ""
	return 0
}

check_grub_status() {
	msg "=== Current Boot Status ==="

	msg "Current kernel:"
	uname -r

	msg ""
	msg "EFI boot entries:"
	if command -v efibootmgr >/dev/null 2>&1; then
		efibootmgr -v | head -10 || true
	else
		warn "efibootmgr not found (install sys-boot/efibootmgr for detailed info)"
	fi

	msg ""
	msg "GRUB installation status:"
	if [[ -f /boot/grub/grub.cfg ]]; then
		success "GRUB config exists at /boot/grub/grub.cfg"
	else
		warn "GRUB config not found at /boot/grub/grub.cfg"
	fi

	if [[ -d /boot/efi/EFI/gentoo ]]; then
		success "GRUB EFI files found at /boot/efi/EFI/gentoo"
	elif [[ -d /boot/efi/EFI/BOOT ]]; then
		msg "GRUB EFI files at /boot/efi/EFI/BOOT"
	else
		warn "GRUB EFI files not found"
	fi

	msg ""
	msg "Available kernels:"
	find /boot -maxdepth 1 -name 'kernel-*' -type f -printf '%f\n' | sed 's/^kernel-//' | sort -V

	msg ""
}

install_grub_efi() {
	msg "=== Installing GRUB to EFI Partition ==="

	check_root
	verify_efi_system || return 1

	msg ""
	msg "Detecting boot device and partition..."

	local boot_device efi_partition
	boot_device=$(df /boot/efi | tail -1 | awk '{print $1}')

	if [[ -z "$boot_device" ]]; then
		error "Could not determine boot device"
		return 1
	fi

	msg "Boot device: $boot_device"

	# Extract base device (remove partition number)
	local base_device="${boot_device%[0-9]*}"
	msg "Base device: $base_device"

	if [[ ! -b "$base_device" ]]; then
		error "Base device not found: $base_device"
		return 1
	fi

	msg ""
	msg "Installing GRUB to $base_device..."
	msg "This will install GRUB to the EFI System Partition"

	if grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=gentoo --recheck; then
		success "GRUB installed successfully"
	else
		error "GRUB installation failed"
		return 1
	fi

	msg ""
	msg "GRUB EFI files installed to /boot/efi/EFI/gentoo"

	return 0
}

regen_grub_config() {
	msg "=== Regenerating GRUB Configuration ==="

	check_root

	if [[ ! -f /boot/grub/grub.cfg ]]; then
		msg "Creating new GRUB config..."
	else
		msg "Backing up current GRUB config..."
		cp /boot/grub/grub.cfg "/boot/grub/grub.cfg.bak-$(date +%Y%m%d%H%M%S)"
	fi

	msg "Running grub-mkconfig..."
	if grub-mkconfig -o /boot/grub/grub.cfg; then
		success "GRUB config regenerated"
	else
		error "grub-mkconfig failed"
		return 1
	fi

	msg ""
	msg "Verifying GRUB config..."
	if grep -q "menuentry" /boot/grub/grub.cfg; then
		success "GRUB config contains menu entries"
		msg ""
		msg "Menu entries:"
		grep "^menuentry" /boot/grub/grub.cfg | sed "s/^menuentry '/  /" | sed "s/' .*//"
	else
		warn "No menu entries found in GRUB config"
	fi

	return 0
}

main() {
	case "${1:-}" in
		-h | --help)
			show_usage
			exit 0
			;;
		--check)
			check_grub_status
			;;
		--install)
			install_grub_efi
			;;
		--regen)
			regen_grub_config
			;;
		--full)
			install_grub_efi && regen_grub_config
			;;
		"")
			msg "No action specified. Run with --help for usage."
			show_usage
			exit 0
			;;
		*)
			error "Unknown option: $1"
			show_usage
			exit 1
			;;
	esac

	msg ""
	msg "=== Summary ==="

	if [[ "${1:-}" == "--full" || "${1:-}" == "--install" || "${1:-}" == "--regen" ]]; then
		msg "GRUB installation/config update complete!"
		msg ""
		msg "Next steps:"
		msg "  1. Review the changes above"
		msg "  2. Reboot the system: sudo reboot"
		msg "  3. You should see the GRUB menu on boot"
		msg "  4. Select the 7.1.3 kernel to test"
		msg ""
		msg "If you don't see GRUB menu:"
		msg "  - Press ESC/SPACE during boot to access GRUB menu"
		msg "  - Check EFI boot order: sudo efibootmgr -v"
		msg "  - Verify GRUB is first in boot order"
	fi
}

main "$@"
