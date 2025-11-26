#!/bin/bash
# 💫 AGS v1.9.0 Installation Script for Gentoo 💫
# Adapted from JaKooLit's ags.sh for Gentoo Linux

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Symbols
ERROR="${RED}✗${RESET}"
OK="${GREEN}✓${RESET}"
INFO="${BLUE}ℹ${RESET}"
NOTE="${CYAN}★${RESET}"
WARN="${YELLOW}⚠${RESET}"

# AGS specific tag
ags_tag="v1.9.0"

# Gentoo package names for AGS dependencies
ags_gentoo=(
    dev-lang/typescript
    net-libs/nodejs
    dev-build/meson
    dev-libs/glib
    dev-libs/gjs
    x11-libs/gtk+:3
    gui-libs/gtk-layer-shell
    sys-power/upower
    net-misc/networkmanager
    dev-libs/gobject-introspection
    dev-libs/libdbusmenu
    net-libs/libsoup:3.0
)

echo -e "${NOTE} ${MAGENTA}AGS v1.9.0 Installation Script for Gentoo${RESET}\n"

# Check for nodejs npm USE flag
if ! equery list net-libs/nodejs 2>/dev/null | grep -q npm; then
    echo -e "${WARN} nodejs needs 'npm' USE flag enabled."
    echo -e "${INFO} Enabling npm USE flag for nodejs..."
    echo 'net-libs/nodejs npm' | sudo tee -a /etc/portage/package.use/nodejs >/dev/null
    echo -e "${OK} USE flag configured. Will reinstall nodejs if needed."
fi

# Check if AGS is already installed
if command -v ags &>/dev/null; then
    AGS_VERSION=$(ags -v 2>/dev/null | awk '{print $NF}')
    if [[ "$AGS_VERSION" == "1.9.0" ]]; then
        echo -e "${INFO} ${MAGENTA}Aylur's GTK Shell v1.9.0${RESET} is already installed. Skipping installation."
        exit 0
    else
        echo -e "${WARN} AGS version $AGS_VERSION found. Will upgrade to 1.9.0."
    fi
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${ERROR} This script should not be run as root. Please run as a normal user." 
   exit 1
fi

# Check for sudo access
if ! sudo -v; then
    echo -e "${ERROR} This script requires sudo privileges."
    exit 1
fi

echo -e "${NOTE} Installing ${CYAN}AGS dependencies${RESET}...\n"

# Install dependencies
failed_packages=()
for PKG in "${ags_gentoo[@]}"; do
    echo -e "${INFO} Checking ${YELLOW}$PKG${RESET}..."
    
    # Check if package is already installed (simple check)
    PKG_NAME=$(echo "$PKG" | cut -d: -f1)
    if equery list "$PKG_NAME" &>/dev/null; then
        echo -e "${OK} ${YELLOW}$PKG${RESET} is already installed."
    else
        echo -e "${INFO} Installing ${YELLOW}$PKG${RESET}..."
        if sudo emerge -v "$PKG"; then
            echo -e "${OK} ${YELLOW}$PKG${RESET} installed successfully."
        else
            echo -e "${ERROR} Failed to install ${YELLOW}$PKG${RESET}"
            failed_packages+=("$PKG")
        fi
    fi
    echo ""
done

# Check if any packages failed
if [ ${#failed_packages[@]} -gt 0 ]; then
    echo -e "${ERROR} The following packages failed to install:"
    for pkg in "${failed_packages[@]}"; do
        echo -e "  - ${RED}$pkg${RESET}"
    done
    echo -e "\n${WARN} Continuing anyway, but AGS may fail to build..."
    read -p "Press Enter to continue or Ctrl+C to abort..."
fi

echo -e "\n${NOTE} Installing and compiling ${CYAN}Aylur's GTK Shell $ags_tag${RESET}...\n"

# Check if directory exists and remove it
if [ -d "ags_v1.9.0" ]; then
    echo -e "${NOTE} Removing existing ags directory..."
    rm -rf "ags_v1.9.0"
fi

# Clone repository
echo -e "${INFO} Cloning ${CYAN}AGS $ags_tag${RESET} repository..."
if ! git clone --depth=1 https://github.com/JaKooLit/ags_v1.9.0.git; then
    echo -e "${ERROR} Failed to clone AGS repository. Check your internet connection."
    exit 1
fi

cd ags_v1.9.0 || exit 1

# Install npm dependencies
echo -e "\n${INFO} Installing npm dependencies..."
if ! npm install; then
    echo -e "${ERROR} npm install failed."
    cd ..
    exit 1
fi

# Setup meson build
echo -e "\n${INFO} Setting up meson build..."
if ! meson setup build; then
    echo -e "${ERROR} Meson setup failed."
    cd ..
    exit 1
fi

# Install AGS
echo -e "\n${INFO} Installing AGS (requires sudo)..."
if ! sudo meson install -C build; then
    echo -e "${ERROR} AGS installation failed."
    cd ..
    exit 1
fi

echo -e "\n${OK} ${YELLOW}Aylur's GTK Shell $ags_tag${RESET} installed successfully.\n"

# Apply launcher patch for GI typelibs search path
echo -e "${NOTE} Applying AGS launcher patch for GI typelibs search path..."
LAUNCHER="/usr/local/share/com.github.Aylur.ags/com.github.Aylur.ags"

if sudo test -f "$LAUNCHER"; then
    # 1) Switch from GIRepository ESM import to GLib and drop deprecated prepend_* calls
    sudo sed -i \
        -e 's|^import GIR from "gi://GIRepository?version=2.0";$|import GLib from "gi://GLib";|' \
        -e '/GIR.Repository.prepend_search_path/d' \
        -e '/GIR.Repository.prepend_library_path/d' \
        "$LAUNCHER"
    
    # 2) Inject GI_TYPELIB_PATH export right after the GLib import
    sudo awk '{print} $0 ~ /^import GLib from "gi:\/\/GLib";$/ {print "const __old = GLib.getenv(\"GI_TYPELIB_PATH\");"; print "GLib.setenv(\"GI_TYPELIB_PATH\", \"/usr/local/lib\" + (__old ? \":\" + __old : \"\"), true);"}' "$LAUNCHER" > /tmp/ags_launcher
    sudo mv /tmp/ags_launcher "$LAUNCHER"
    sudo chmod +x "$LAUNCHER"
    
    echo -e "${OK} AGS launcher patched successfully."
else
    echo -e "${WARN} Launcher not found at $LAUNCHER, skipping patch."
fi

# Cleanup
cd ..
echo -e "\n${INFO} Cleaning up..."
rm -rf ags_v1.9.0

# Verify installation
echo -e "\n${NOTE} Verifying installation..."
if command -v ags &>/dev/null; then
    AGS_VERSION=$(ags -v 2>/dev/null | awk '{print $NF}')
    echo -e "${OK} AGS version ${GREEN}$AGS_VERSION${RESET} installed successfully!"
    
    echo -e "\n${INFO} You can now run AGS with: ${YELLOW}ags${RESET}"
    echo -e "${INFO} For help, run: ${YELLOW}ags --help${RESET}"
else
    echo -e "${ERROR} AGS installation verification failed. Command not found."
    exit 1
fi

echo -e "\n${OK} ${GREEN}Installation complete!${RESET}\n"
