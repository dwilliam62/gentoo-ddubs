#!/usr/bin/env bash
# ==================================================
#  KoolDots (2026)
#  Project URL: https://github.com/LinuxBeginnings
#  License: GNU GPLv3
#  SPDX-License-Identifier: GPL-3.0-or-later
# ==================================================
# 💫 https://github.com/LinuxBeginnings 💫 #
# Gentoo hyprmod installer with edgets repo setup
#

set -o pipefail

KEYWORDS_FILE="/etc/portage/package.accept_keywords/edgets"

msg() {
	printf '%s\n' "$1"
}

error() {
	printf 'ERROR: %s\n' "$1" >&2
}

require_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		error "Required command '$1' was not found."
		return 1
	fi
}

setup_edgets_repository() {
	msg "Setting up edgets repository..."

	require_command eselect || {
		msg "eselect not found. Installing eselect-repository..."
		if ! sudo emerge --ask app-eselect/eselect-repository; then
			error "Failed to install eselect-repository"
			return 1
		fi
	}

	msg "Enabling edgets repository..."
	if ! sudo eselect repository enable edgets; then
		error "Failed to enable edgets repository"
		return 1
	fi

	msg "Syncing portage tree..."
	if ! sudo emerge --sync; then
		error "Failed to sync portage tree"
		return 1
	fi

	msg "Edgets repository setup complete."
}

setup_package_keywords() {
	msg "Configuring package keywords for edgets..."

	if [[ ! -d /etc/portage/package.accept_keywords ]]; then
		msg "Creating /etc/portage/package.accept_keywords directory..."
		sudo mkdir -p /etc/portage/package.accept_keywords
	fi

	if [[ -f "$KEYWORDS_FILE" ]]; then
		if grep -q '^\*\/\*::edgets' "$KEYWORDS_FILE"; then
			msg "edgets keyword entry already exists in $KEYWORDS_FILE"
			return 0
		fi
	fi

	msg "Adding edgets keyword entry to $KEYWORDS_FILE..."
	echo "*/*::edgets ~amd64" | sudo tee -a "$KEYWORDS_FILE" >/dev/null

	if [[ $? -eq 0 ]]; then
		msg "Keywords configured successfully."
	else
		error "Failed to configure package keywords"
		return 1
	fi
}

install_hyprmod() {
	msg "Installing hyprmod from edgets repository..."

	if ! sudo emerge -a hyprmod; then
		error "hyprmod installation failed"
		return 1
	fi

	msg "hyprmod installed successfully."
}

main() {
	msg "Starting hyprmod installation for Gentoo..."

	setup_edgets_repository || return 1
	setup_package_keywords || return 1
	install_hyprmod || return 1

	msg "Installation complete!"
}

main
