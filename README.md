# gentoo-ddubs 🐧⚙️

## A reproducible snapshot of _my_ Gentoo config

- Plus snapshot of Jak's Hyprland dotfiles
- You can download current dotfiles [here](https://github.com/Jakoolit/Hyprland-Dots)

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

- 🚀 Installs Hyprland: Will install Hyprland from Gentoo repo and needed packages
  - Currently Gentoo Hyprland is at v0.51.1 in testing repo
- Installs `OxWM` Window Manager from `@tony,btw`
  - Inspired by `dwm` built in rust, fast and lightweight
  - GitHub repo [here](https://github.com/tonybanters/oxwm)
- 📦 System snapshot: Portage configs, world file, fstab, locale, kernel .config
- 🧩 Window manager: Hyprland
  - Login manager: `ly`
- 🗂️ Dotfiles: Jakoolit's Hyprland config
- 🚀 One-command user setup: `scripts/gentoo-install-hyprland.sh`
  - This is Jak Koolit's Hyprland config.
  - You can install your own or clone from his repo for most current version
  - Jakoolit's dotfiles are NOT auto installed just the Hyprland WM

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
  update.sh                    # Update gentoo (supports --skip-quickshell)

  > Note: There are some other misc scripts those are WIP and should not be used

```

## 🧪 Quick start (new machine)

- Clone and deploy user configs
  ```
  git clone https://github.com/dwilliam62/gentoo-ddubs.git
  cd ~/gentoo-ddubs
  bash scripts/gentool-install-hyprland.sh
  ```

## 🪟 Window managers

- Hyprland
  - Wayland session entry: `/usr/share/wayland-sessions/hyprland.desktop`
  - Default in ly is set via `/etc/ly/save.ini` (session_index)
- OxWM
  - X11 Window Manager
  - Inspired by `dwm`
  - Built in `rust`
  - Fast and lightweight
  - From `@tony,btw`
  - GitHub repo [here](https://github.com/tonybanters/oxwm)
