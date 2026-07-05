#!/usr/bin/env bash

# Exit immediately if any command fails
set -e

# Define paths based on your system configuration
LOCAL_REPO="/var/db/repos/localrepo"
ECLASS_DIR="${LOCAL_REPO}/eclass"
DUMMY_ECLASS="${ECLASS_DIR}/linux-mod.eclass"

echo "=== Starting Gentoo GURU Mask & Fix Automation ==="

# 1. Ensure the local repo eclass directory exists
echo "-> Ensuring directory exists: ${ECLASS_DIR}"
mkdir -p "${ECLASS_DIR}"

# 2. Write the dummy eclass file
echo "-> Creating dummy linux-mod.eclass to satisfy parsing..."
cat << 'EOF' > "${DUMMY_ECLASS}"
# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
# Dummy eclass to satisfy broken GURU overlay imports
EOF

# 3. Add to package.mask (standard structure)
echo "-> Ensuring standard package.mask block is active..."
mkdir -p /etc/portage/package.mask
cat << 'EOF' > /etc/portage/package.mask/hid-nintendo
# Mask hid-nintendo since it requires linux-mod eclass and we don't use Nintendo controllers
games-util/hid-nintendo::guru
EOF

# 4. Add to profile mask (metadata filtering backup)
echo "-> Ensuring profile package.mask block is active..."
mkdir -p /etc/portage/profile
if ! grep -q "games-util/hid-nintendo" /etc/portage/profile/package.mask 2>/dev/null; then
    echo "games-util/hid-nintendo" >> /etc/portage/profile/package.mask
fi

# 5. Regenerate Portage repository caches as root
echo "-> Regenerating GURU cache matrix (this may take a moment)..."
egencache --repo=guru --update

echo "=== Success! You can now safely run your emerge commands ==="

