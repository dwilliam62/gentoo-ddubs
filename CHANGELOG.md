# Changelog

All notable changes to this project will be documented in this file.

## Jun 2026  

- Added python overrides for: 
   - `nwg-display`
   - `variety` 
   - `docutils`
   - `pycairo`
   - `pygobject`
   - `waypaper`

## May 2026  

- Updated: `scripts/update.sh` Now calls kernel cleanup script 
- Added `scripts/update-yazi.sh` 
  - Checks existing version and updates to current build 
- Updated `zig` compiler to v0.16.0 `oxwm` now compatible
- Reworked `/boot/efi` mount options 
  - To prevent boot failure `can't mount /boot/efi` 

## Apr 2026

- Added gdk-pixbuf/tumbler JPEG USE flags in ensure_use_flags.
- Added ensure_gdk_pixbuf_loaders_cache
- Called after the Hyprland package install.

## Mar 2026

- Removed source-build helper for `hyprland-qtutils` now that it is available via Portage/overlay.
- Added `gui-libs/hyprland-qtutils` to the Hyprland package list in `gentoo-install-hyprland.sh`.

## Jan 2026 

- Added: `OxWM` Window Manager from `@tony,btw`
- GitHub repo [here](https://github.com/tonybanters/oxwm)
- Inspired by `dwm` built with `rust`
- Major re-do of the script
  - Added function in flatpak install to add flathub repo
  - Set `ly` login manager to `Hyprland` not `Hyprland-uwsm`
  - Added document describing project
    - `gentoo-insall-project-overview.md`
  - Walked through process found issues, missing pkgs
  - Wrong package names, conflicting USE flags
  - Added post install script `post-install-cleanup.sh`
  - Fixed `pamixer` compile issue
  - Fixed `pipewire` not starting
  - Added function to add current user to audio groups
  - Added function to set proper paths for `pamixer`
    - Adds them to `~/.zshrc` and/or `~/.bashrc`
      - Checks to see if already added to them
  - Updted hyprland dotfiles to v2.3.19-dev
  - Added `install-bugsvim.sh` script
    - clones and installs `bugsvim` Neovim config
    - Disabled `dev-lang/rust` and `llvim-core/clang`
      - Both are long builds
      - Nodejs is still there also a large build
  - Added `uwsm` package as `hyprland-uwsm` is default
    - In case someone leaves it at that and tries to login
  - Added `quickshell` package
  - Added solo script to build `hyprland-qtutils` from source
    - Gentoo does not have it in any repo I could find
  - Disabled `pamixer` as it won't build waiting for upstream fix
    - There is a potential workaround but for now leaving as-is
  - Added functions to the script to try to resolve common issues
    - slot conficts
    - USE flag autounmasking
    - If binary emerge fails switch to source build
    - `equery` wasn't detecting installed packages
      - Causing all packages to be rebuilt every time script ran
      - Switch to `qlist -I` faster, and works
    ```bash
     install_if_missing() {
         local pkg=$1
         if ! qlist -I "$pkg" > /dev/null 2>&1; then
             echo ">>> Installing $pkg..."
             sudo emerge --ask=n --verbose --oneshot "$pkg"
         else
             echo ">>> $pkg is already installed, skipping."
         fi
     }
    ```
  - Added check to suggest reboot and deep clean rebuild pkgs
  - Added "prebuild problem packages" function to fix python failures
  - Added script to fix gentoo default cursor issue in HL
    - Need to integrate into install script
  - Added Backup script for gentoo config
  - Added `--set-dark` flag set GTK themes to `Aiwaita-Dark`
  - Need investigate this repo:
    - `https://codeberg.org/hyproverlay/hyproverlay/src/branch/main`
    - To build current Hyprland from source

## Nov 2025

- Initial repository: imported Gentoo system snapshot (Portage configs, world, fstab, locale, kernel .config) and system metadata.
- Added dotfiles captured from VM: Hyprland, suckless (dunst, picom, rofi, sxhkd, scripts), and `~/.dwm/autostart.sh`.
- Deployment: added `scripts/deploy-dotfiles.sh` (backups, PATH setup, script install to `~/.local/bin`).
- DWM setup:
  - Built and installed local `dwm`, `st`, `slstatus` to `~/.local/bin`.
  - Created wrapper `~/.local/bin/dwm-session` to run autostart, start `sxhkd`/`slstatus`, then exec `dwm`.
  - Added X session entry `/usr/share/xsessions/dwm-local.desktop` using the wrapper.
  - Ensured `~/.local/bin` is first in `PATH` for login/interactive shells.
  - Inserted `xrandr --output Virtual-1 --mode 1920x1080` at top of `~/.dwm/autostart.sh` for VM resolution.
  - Fixed `sxhkd` config typo (shft -> shift).
- Ly configuration: kept Hyprland set as default session by updating `/etc/ly/save.ini`.
- Package changes on VM:
  - Removed Portage-managed `dwm` and `st` (local builds preferred); `slstatus` wasn’t installed via Portage.
  - Installed `wezterm` and copied `~/.config/wezterm/wezterm.lua`.
  - Installed `feh`, `nitrogen`, `fortune-mod`.
  - Attempted Variety via Flatpak; not available on Flathub at time of setup.
