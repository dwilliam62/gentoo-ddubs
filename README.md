# gentoo-ddubs 🐧⚙️

## A reproducible snapshot of _my_ Gentoo config, plus Jak's Hyprland dotfiles

- Scripts to bootstrap a similar system quickly.
- It includes Portage configuration
- kernel config
- Desktop configs for Hyprland
- There are scripts for upgrading, post-install cleanup

> Note: I don't promise this will work for you.  
> I created this so I can test Hyprland dotfiles with Gentoo
> Mostly Jak's Hyprland [dotfiles](https://github.com/Jakoolit/Hyprland-Dots)

- The `gentoo-install-project-overview.md` has more info on this project
- It does attempt to detect GPU hardware.
  - To date it's only tested in Proxmox VMs.

## ✨ Highlights

- 🚀 Install Hyprland: Will build current Gentoo Hyprland and needed packages
- 📦 System snapshot: Portage configs, world file, fstab, locale, kernel .config
- 🧩 Window managers: Hyprland (default in ly) and DWM (local build wrapper)
- 🧰 Suckless stack: dwm, st, slstatus built to `~/.local`
- 🗂️ Dotfiles: hypr, rofi, picom, dunst, sxhkd, scripts, dwm autostart
- 🚀 One-command user setup: `scripts/deploy-dotfiles.sh`
  - This is Jak Koolit's Hyprland config.
  - You can install your own or clone from his repo for most current version

## 📁 Layout

```
system/                   # extracted system snapshot
  etc/portage/*           # repos, make.conf, package.*
  var/lib/portage/world   # world set
  etc/{fstab,locale.gen}
  usr/src/linux/.config   # kernel config

docs/                     # metadata from the VM
  emerge-info.txt
  eselect-profile.txt
  uname.txt

dotfiles/
  home/.config/hypr/*
  home/.config/suckless/{dunst,picom,rofi,sxhkd,scripts}
  home/.config/{dunst,picom,rofi,sxhkd}/*
  home/.dwm/autostart.sh

scripts/
  deploy-dotfiles.sh      # safe deploy with backups, PATH setup
  gemtoo-install-hyprland.sh  # Installs current HL and needed packages
  gentoo-cfg-backup.sh        # Simple backup script for current config
  post-install-cleanup.sh      # optional script to cleanup tarballs, etc
  set-default-pointer-theme    # sets cursor to Adwaita others get HL logo
  update.sh                    # Update gentoo
  hyprland-qtutils/build-hyprland-qtutils   # currently not in repo manual build

  > Note: There are some other misc scripts those are WIP and should not be used

```

## 🧪 Quick start (new machine)

- Clone and deploy user configs
  ```
  git clone https://github.com/dwilliam62/gentoo-ddubs.git
  cd gentoo-ddubs
  bash scripts/deploy-dotfiles.sh
  ```
- Install required tools (Gentoo examples)
  ```
  sudo emerge --ask dunst picom rofi sxhkd feh nitrogen games-misc/fortune-mod x11-terms/wezterm
  # Optional: Variety via Flatpak (if available on your system)
  flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
  flatpak --user install -y flathub com.github.variety.Variety || true
  ```

## 🪟 Window managers

- Hyprland
  - Wayland session entry: `/usr/share/wayland-sessions/hyprland.desktop`
  - Default in ly is set via `/etc/ly/save.ini` (session_index)
- DWM (local)
  - Local build installs binaries to `~/.local/bin`
  - X session entry: `/usr/share/xsessions/dwm-local.desktop`
  - Wrapper: `~/.local/bin/dwm-session` ensures PATH, runs `~/.dwm/autostart.sh`, starts `sxhkd`/`slstatus`, then execs dwm

## 🔧 Building suckless locally

From the synced sources on a target host (or your own clones):

```
for p in slstatus st dwm; do
  cd ~/src/suckless/$p && make clean && make PREFIX=$HOME/.local install
done
```

Ensure `~/.local/bin` is first in PATH (deploy script sets this automatically).

## ⌨️ Keybinds and autostart

- `~/.dwm/autostart.sh` runs on DWM start (resolution, polkit, sxhkd, dunst, picom, etc.)
- `sxhkd` config: `~/.config/suckless/sxhkd/sxhkdrc`
- Terminal: WezTerm (installed via Portage); config at `~/.config/wezterm/wezterm.lua`

## 📝 Notes

- Treat this repo as a reference snapshot; review diffs before using on other systems.
- Some paths assume user `~/.local/bin` and ly as the login manager.
- Variety availability via Flatpak may vary; use system package or source build if missing.
