# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.
``

## Repository purpose
Snapshot of a configured Gentoo VM plus user dotfiles and scripts to quickly reproduce the environment. Includes: system snapshot (Portage configs, kernel .config), Hyprland and a local Suckless (dwm/st/slstatus) setup, and a safe dotfiles deploy script.

## High-level architecture
- system/: Reference-only Gentoo system snapshot (e.g., etc/portage, world, fstab, locale, usr/src/linux/.config). Not modified by scripts here.
- docs/: System metadata exports (e.g., emerge-info.txt, uname.txt). Reference-only.
- dotfiles/: User-level configs captured from the VM
  - home/.config/hypr/* (Hyprland configs and helper scripts)
  - home/.config/suckless/{dunst,picom,rofi,sxhkd,scripts}
  - home/.dwm/autostart.sh (DWM session bootstrap)
- scripts/
  - deploy-dotfiles.sh: idempotent deploy into $HOME with backups and PATH setup

### deploy-dotfiles.sh behavior (big picture)
- Backs up any replaced files into ~/.local/share/dotfiles-backup/<timestamp>
- Rsyncs dotfiles to ~/.config and ~/.dwm
- Installs helper scripts to ~/.local/bin and ensures ~/.local/bin is added to PATH for future shells via ~/.config/profile.d/local-bin.sh sourced from common shell init files

## Common commands
- Clone and deploy dotfiles to current user
  - git clone <repo> && cd <repo>
  - bash scripts/deploy-dotfiles.sh

- Lint all shell scripts (requires shellcheck)
  - find . -type f -name "*.sh" -print0 | xargs -0 -n1 shellcheck -x

- Format all shell scripts (requires shfmt)
  - Preview changes: shfmt -i 2 -ci -bn -l .
  - Apply changes:   shfmt -w -i 2 -ci -bn .

- Run a single helper script from the repo (without deploying)
  - bash dotfiles/home/.config/hypr/scripts/Refresh.sh
  - Note: many scripts expect runtime paths under $HOME after deploy; prefer running post-deploy from ~/.local/bin or ~/.config/* paths.

- Build Suckless tools locally (from your own clones on the target host)
  - for p in slstatus st dwm; do cd ~/src/suckless/$p && make clean && make PREFIX=$HOME/.local install; done

## Runtime/WM notes (from README)
- Hyprland: default session via ly (see /etc/ly/save.ini)
- DWM: local wrapper (~/.local/bin/dwm-session) ensures PATH, runs ~/.dwm/autostart.sh, starts sxhkd/slstatus, then execs dwm; X session entry at /usr/share/xsessions/dwm-local.desktop

## Testing and CI
- No automated test suite or CI is present in this repository. Manual verification after deploy is typical (e.g., start WM, verify autostart, run helper scripts).

## Important docs to consult
- README.md: quick start, highlights, and build notes for the local Suckless stack
- CHANGELOG.md: historical changes to the snapshot and dotfiles

## Tooling/rules discovered
- No CLAUDE.md, Cursor rules (.cursor/rules or .cursorrules), or Copilot instruction files were found.
