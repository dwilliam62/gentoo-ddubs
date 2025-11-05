# Changelog

All notable changes to this project will be documented in this file.

## 2025-11-05
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
