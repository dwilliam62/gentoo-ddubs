#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# Fix GRUB configuration on remote Gentoo system
# Handles /root/boot paths, timeout, and menu visibility
#

set -euo pipefail

msg() {
	printf '%s\n' "$1"
}

error() {
	printf 'ERROR: %s\n' "$1" >&2
}

success() {
	printf '\033[0;32m✓\033[0m %s\n' "$1"
}

warn() {
	printf '\033[1;33m⚠\033[0m %s\n' "$1"
}

show_usage() {
	cat <<EOF
Usage: $(basename "$0") <host> [options]

Fix GRUB configuration on a remote Gentoo system.

Arguments:
  host              SSH host (e.g., dwilliams@192.168.40.5)

Options:
  --deploy-config   Copy /etc/default/grub to remote system
  --regen           Regenerate GRUB config after deploying
  --check           Check current GRUB configuration (default)
  --help            Show this help message

Examples:
  # Check current configuration
  $(basename "$0") dwilliams@192.168.40.5 --check

  # Deploy corrected config and regenerate GRUB
  $(basename "$0") dwilliams@192.168.40.5 --deploy-config --regen

  # Just regenerate without deploying new config
  $(basename "$0") dwilliams@192.168.40.5 --regen

EOF
}

HOST=""
DEPLOY_CONFIG=0
REGEN=0
ACTION="check"

while [[ $# -gt 0 ]]; do
	case "$1" in
		-h | --help)
			show_usage
			exit 0
			;;
		--deploy-config)
			DEPLOY_CONFIG=1
			shift
			;;
		--regen)
			REGEN=1
			ACTION="regen"
			shift
			;;
		--check)
			ACTION="check"
			shift
			;;
		-*)
			error "Unknown option: $1"
			show_usage
			exit 1
			;;
		*)
			if [[ -z "$HOST" ]]; then
				HOST="$1"
				shift
			else
				error "Unexpected argument: $1"
				exit 1
			fi
			;;
	esac
done

if [[ -z "$HOST" ]]; then
	error "Host argument required"
	show_usage
	exit 1
fi

# Verify SSH connection
msg "Verifying SSH connection to $HOST..."
if ! ssh -o ConnectTimeout=5 "$HOST" 'true' >/dev/null 2>&1; then
	error "Cannot connect to $HOST via SSH"
	exit 1
fi
success "Connected to $HOST"

check_grub_config() {
	msg ""
	msg "=== Current GRUB Configuration ==="

	msg "Current kernel:"
	ssh "$HOST" 'uname -r' || true

	msg ""
	msg "Available kernels in /boot:"
	ssh "$HOST" 'ls -lh /boot/kernel-* 2>/dev/null | awk "{print \$9, \$5}" | sed "s|/boot/||"' || true

	msg ""
	msg "GRUB timeout:"
	ssh "$HOST" 'grep "^set timeout=" /boot/grub/grub.cfg | head -1' || true

	msg ""
	msg "First GRUB menu entry:"
	ssh "$HOST" 'grep "^menuentry" /boot/grub/grub.cfg | head -1' || true

	msg ""
	msg "Kernel paths in GRUB config:"
	ssh "$HOST" 'grep "linux\s\+" /boot/grub/grub.cfg | head -3 | sed "s/^[[:space:]]*/  /"' || true

	msg ""
	if ssh "$HOST" 'sudo grep -q "/root/boot/" /boot/grub/grub.cfg'; then
		warn "GRUB config contains /root/boot/ paths (INCORRECT)"
		msg "Affected lines:"
		ssh "$HOST" 'sudo grep "/root/boot/" /boot/grub/grub.cfg | head -2 | sed "s/^/  /"' || true
		return 1
	else
		success "No /root/boot/ paths in GRUB config (CORRECT)"
		return 0
	fi
}

deploy_grub_config() {
	local config_file="./etc/default/grub"

	if [[ ! -f "$config_file" ]]; then
		error "Config file not found: $config_file"
		return 1
	fi

	msg ""
	msg "=== Deploying /etc/default/grub ==="

	msg "Backing up current /etc/default/grub on remote system..."
	ssh "$HOST" 'sudo cp /etc/default/grub /etc/default/grub.bak-$(date +%Y%m%d%H%M%S)' || true

	msg "Copying new config..."
	scp "$config_file" "$HOST:/tmp/grub" || {
		error "Failed to copy config file"
		return 1
	}

	msg "Installing config..."
	ssh "$HOST" 'sudo mv /tmp/grub /etc/default/grub && sudo chmod 644 /etc/default/grub' || {
		error "Failed to install config"
		return 1
	}

	success "Config deployed successfully"
	return 0
}

regen_grub_config() {
	msg ""
	msg "=== Regenerating GRUB Configuration ==="

	msg "Running grub-mkconfig..."
	ssh "$HOST" 'sudo grub-mkconfig -o /boot/grub/grub.cfg' || {
		error "grub-mkconfig failed"
		return 1
	}

	success "GRUB config regenerated"

	msg ""
	msg "=== Verification ==="
	check_grub_config
}

main() {
	case "$ACTION" in
		check)
			check_grub_config
			;;
		regen)
			if [[ "$DEPLOY_CONFIG" -eq 1 ]]; then
				deploy_grub_config || exit 1
			fi
			regen_grub_config
			;;
		*)
			error "Unknown action: $ACTION"
			exit 1
			;;
	esac

	msg ""
	msg "=== Summary ==="
	msg "To complete the fix:"
	msg "  1. Review the changes above"
	msg "  2. Reboot the remote system: ssh $HOST 'sudo reboot'"
	msg "  3. Verify boot: ssh $HOST 'uname -r'"
	msg ""
}

main
