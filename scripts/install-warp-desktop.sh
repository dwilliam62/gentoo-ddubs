#!/usr/bin/env bash
# ==============================================================================
# Script: install-warp-desktop.sh
# Description: Extracts application icons and installs desktop menu integration
#              for Warp AppImage on Gentoo Linux so launchers like Rofi can
#              discover and launch Warp with full icon support.
# ==============================================================================

set -euo pipefail

# Determine target user and home directory
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
    TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
else
    TARGET_USER="${USER:-$(id -un)}"
    TARGET_HOME="${HOME}"
fi

# Locate Warp AppImage
APPIMAGE_PATH="${1:-}"
if [[ -z "$APPIMAGE_PATH" ]]; then
    if [[ -f "$TARGET_HOME/AppImages/Warp-x86_64.AppImage" ]]; then
        APPIMAGE_PATH="$TARGET_HOME/AppImages/Warp-x86_64.AppImage"
    elif [[ -f "$TARGET_HOME/AppImages/warp-x86_64.AppImage" ]]; then
        APPIMAGE_PATH="$TARGET_HOME/AppImages/warp-x86_64.AppImage"
    elif [[ -f "$HOME/AppImages/Warp-x86_64.AppImage" ]]; then
        APPIMAGE_PATH="$HOME/AppImages/Warp-x86_64.AppImage"
    else
        # Try finding any Warp AppImage in AppImages directory
        MATCH=$(find "$TARGET_HOME/AppImages" -maxdepth 1 -name "*Warp*.AppImage" -o -name "*warp*.AppImage" 2>/dev/null | head -n 1 || true)
        if [[ -n "$MATCH" && -f "$MATCH" ]]; then
            APPIMAGE_PATH="$MATCH"
        fi
    fi
fi

if [[ -z "$APPIMAGE_PATH" || ! -f "$APPIMAGE_PATH" ]]; then
    echo "[!] Error: Warp AppImage not found at '$APPIMAGE_PATH'." >&2
    echo "    Usage: $0 [/path/to/Warp-x86_64.AppImage]" >&2
    exit 1
fi

echo "[*] Using Warp AppImage: $APPIMAGE_PATH"
chmod +x "$APPIMAGE_PATH"

# Setup temporary extraction directory
TMPDIR=$(mktemp -d)
cleanup() {
    rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "[*] Step 1: Extracting assets from AppImage..."
(
    cd "$TMPDIR"
    "$APPIMAGE_PATH" --appimage-extract >/dev/null 2>&1
)

if [[ ! -d "$TMPDIR/squashfs-root" ]]; then
    echo "[!] Error: Failed to extract AppImage contents." >&2
    exit 1
fi

echo "[*] Step 2: Installing icons into user & system themes..."
USER_ICON_DIR="$TARGET_HOME/.local/share/icons/hicolor"
USER_PIXMAP_DIR="$TARGET_HOME/.local/share/pixmaps"
USER_APP_DIR="$TARGET_HOME/.local/share/applications"
USER_BIN_DIR="$TARGET_HOME/.local/bin"

mkdir -p "$USER_ICON_DIR" "$USER_PIXMAP_DIR" "$USER_APP_DIR" "$USER_BIN_DIR"

# Copy hicolor icon directories from extracted AppImage
if [[ -d "$TMPDIR/squashfs-root/usr/share/icons/hicolor" ]]; then
    cp -r "$TMPDIR/squashfs-root/usr/share/icons/hicolor/"* "$USER_ICON_DIR/"
fi

# Copy fallback icon to pixmaps
if [[ -f "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" ]]; then
    cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" "$USER_PIXMAP_DIR/dev.warp.Warp.png"
    cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" "$USER_PIXMAP_DIR/warp.png"
fi

# If running as root or sudo is available, also install system-wide
if [[ $EUID -eq 0 ]]; then
    mkdir -p /usr/share/icons/hicolor /usr/share/pixmaps /usr/share/applications /usr/local/bin
    if [[ -d "$TMPDIR/squashfs-root/usr/share/icons/hicolor" ]]; then
        cp -r "$TMPDIR/squashfs-root/usr/share/icons/hicolor/"* /usr/share/icons/hicolor/
    fi
    if [[ -f "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" ]]; then
        cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" /usr/share/pixmaps/dev.warp.Warp.png
        cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" /usr/share/pixmaps/warp.png
    fi
elif command -v sudo >/dev/null 2>&1; then
    sudo mkdir -p /usr/share/icons/hicolor /usr/share/pixmaps /usr/share/applications /usr/local/bin || true
    if [[ -d "$TMPDIR/squashfs-root/usr/share/icons/hicolor" ]]; then
        sudo cp -r "$TMPDIR/squashfs-root/usr/share/icons/hicolor/"* /usr/share/icons/hicolor/ 2>/dev/null || true
    fi
    if [[ -f "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" ]]; then
        sudo cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" /usr/share/pixmaps/dev.warp.Warp.png 2>/dev/null || true
        sudo cp "$TMPDIR/squashfs-root/usr/share/icons/hicolor/512x512/apps/dev.warp.Warp.png" /usr/share/pixmaps/warp.png 2>/dev/null || true
    fi
fi

echo "[*] Step 3: Creating desktop entry..."
DESKTOP_FILE="$USER_APP_DIR/dev.warp.Warp.desktop"
cat << EOF > "$DESKTOP_FILE"
[Desktop Entry]
Version=1.0
Type=Application
Name=Warp
GenericName=Terminal Emulator
Comment=Fast, modern terminal built for productivity
Exec=${APPIMAGE_PATH} %U
Icon=dev.warp.Warp
Terminal=false
Categories=System;TerminalEmulator;
Keywords=shell;prompt;command;commandline;cmd;warp;terminal;
StartupWMClass=dev.warp.Warp
MimeType=x-scheme-handler/warp;
EOF

chmod 644 "$DESKTOP_FILE"

if [[ $EUID -eq 0 ]]; then
    cp "$DESKTOP_FILE" /usr/share/applications/dev.warp.Warp.desktop
elif command -v sudo >/dev/null 2>&1; then
    sudo cp "$DESKTOP_FILE" /usr/share/applications/dev.warp.Warp.desktop 2>/dev/null || true
fi

echo "[*] Step 4: Creating CLI symlinks..."
ln -sf "$APPIMAGE_PATH" "$USER_BIN_DIR/warp"

if [[ $EUID -eq 0 ]]; then
    ln -sf "$APPIMAGE_PATH" /usr/local/bin/warp
elif command -v sudo >/dev/null 2>&1; then
    sudo ln -sf "$APPIMAGE_PATH" /usr/local/bin/warp 2>/dev/null || true
fi

# Ensure user ownership of user files
if [[ $EUID -eq 0 && "$TARGET_USER" != "root" ]]; then
    chown -R "$TARGET_USER:$TARGET_USER" "$USER_ICON_DIR" "$USER_PIXMAP_DIR" "$USER_APP_DIR" "$USER_BIN_DIR" 2>/dev/null || true
fi

echo "[*] Step 5: Refreshing desktop and icon databases..."
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$USER_APP_DIR" 2>/dev/null || true
    if [[ $EUID -eq 0 ]]; then
        update-desktop-database /usr/share/applications 2>/dev/null || true
    elif command -v sudo >/dev/null 2>&1; then
        sudo update-desktop-database /usr/share/applications 2>/dev/null || true
    fi
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "$USER_ICON_DIR" 2>/dev/null || true
    if [[ $EUID -eq 0 ]]; then
        gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
    elif command -v sudo >/dev/null 2>&1; then
        sudo gtk-update-icon-cache -f -t /usr/share/icons/hicolor 2>/dev/null || true
    fi
fi

if command -v desktop-file-validate >/dev/null 2>&1; then
    desktop-file-validate "$DESKTOP_FILE" 2>/dev/null || true
fi

echo "[+] Warp desktop integration installed successfully!"
echo "    AppImage: $APPIMAGE_PATH"
echo "    Desktop:  $DESKTOP_FILE"
echo "    CLI:      $USER_BIN_DIR/warp"
