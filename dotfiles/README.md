# Dotfiles

This directory contains user-level configs captured from the Gentoo VM.

Included
- home/.config/hypr/* (Hyprland)
- home/.config/suckless/* (dunst, picom, rofi, sxhkd, scripts)
- home/.config/{dunst,picom,rofi,sxhkd}/* (direct paths, if preferred)
- home/.dwm/autostart.sh

Deploy
- Local: run scripts/deploy-dotfiles.sh (backs up to ~/.local/share/dotfiles-backup/<timestamp>)
- Remote host: git clone this repo on the target and run the same script

Notes
- The script also installs suckless helper scripts to ~/.local/bin and ensures PATH setup for future shells.
- Review configs before deploying to non-VM systems.
