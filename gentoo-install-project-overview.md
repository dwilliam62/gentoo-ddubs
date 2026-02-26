# gentoo-install-hyprland: Project Overview

This document describes the `gentoo-install-hyprland.sh` installer script and its surrounding repository layout so both humans and automation agents can understand how to use and extend it.

---

## 1. Repository layout

Top-level tree (annotated):

```text
.
├── system/              # 📂 Captured system snapshot from a reference Gentoo VM
│   ├── etc/             #   🧩 Reference config: Portage, fstab, locale, ly, pam, etc.
│   │   ├── portage/     #   └─ Portage config (repos.conf, package.use, make.conf, ...)
│   │   ├── ly/          #      ly config, save file, x/wsetup scripts
│   │   └── pam.d/       #      PAM configs for ly and hyprlock
│   ├── usr/src/linux/   #   🧪 Kernel `.config` used in the snapshot VM
│   └── var/lib/portage/ #   📦 world file and Portage metadata
│
├── dotfiles/            # 🧩 User-level configs captured from the VM
│   └── home/
│       ├── .config/hypr/    # Hyprland configs + helper scripts
│       ├── .config/suckless # Dunst, picom, rofi, sxhkd, helper scripts
│       ├── .config/variety  # Variety (native + Flatpak) config
│       └── .dwm/            # DWM autostart and related scripts
│
├── scripts/             # 🛠 Operational scripts for install, sync, backup, update
│   ├── gentoo-install-hyprland.sh   # Main Hyprland + audio + ly installer
│   ├── deploy-dotfiles.sh          # Deploy captured dotfiles into $HOME
│   ├── gentoo-cfg-backup.sh        # One-shot Gentoo config backup (tarball)
│   ├── sync-from-vm.sh             # Sync dotfiles + optional system snapshot from VM
│   ├── sync-gentoo-cfg.sh          # Structured system config sync with logs
│   ├── post-install-cleanup.sh     # Portage/cache cleanup + eix/journal maintenance
│   ├── set-default-pointer-theme.sh# Set system default cursor theme (Adwaita)
│   ├── install-bugsvim.sh          # Clone + run Bugsvim installer for Gentoo
│   ├── update.sh                   # Structured Gentoo @world update helper
│   ├── yuni-update.sh              # Simple colorful updater (legacy/alt flow)
│   └── i3-install-script-onhold    # Older i3 installer, kept on hold
│
├── docs/               # 📑 Generated metadata (emerge-info, uname, profiles, ...)
├── README.md           # 🔎 High-level description and quick start
├── CHANGELOG.md        # 📜 History of changes
└── WARP.md             # 🤖 Guidance for agents working in this repo
```

Key point: `system/` is reference-only; `gentoo-install-hyprland.sh` writes into the real `/etc`, `/var`, etc. using these files as templates.

---

## 2. `gentoo-install-hyprland.sh`: high-level behavior

Location: `scripts/gentoo-install-hyprland.sh`

### 2.1 Purpose

Automate bringing a Gentoo system to a working Hyprland desktop with:

- Hyprland + supporting Wayland/GTK/XFCE tooling
- PipeWire/WirePlumber audio stack
- ly login manager configured for Hyprland by default
- User runtime exports and GTK dark theme settings
- Flatpak main Flathub remote configured for the user

The script is designed to be re-runnable and idempotent where practical: it skips packages already installed, reuses Portage configuration files, and avoids duplicating configuration entries.

### 2.2 Execution phases (top-level flow)

In order of execution at the bottom of the script:

1. `ensure_use_flags`
2. `ensure_video_cards`
3. `ensure_gentoo_rsync_repo`
4. `ensure_pamixer_cxx17_fix`
5. `ensure_pipewire_use_fix`
6. `prebuild_problematic_binaries`
7. `install_list "Hyprland stack" "${HYPR_PACKAGES[@]}"`
8. `configure_shell_runtime_exports`
9. `install_list \"Fonts\" \"${FONTS[@]}\"`
10. `configure_ly`
11. `configure_pipewire`
12. `configure_flatpak_flathub`
13. `configure_gtk_dark_theme`

Each of these steps is encapsulated in a function; failures in optional helpers are logged but generally do not abort the whole run unless critical.

---

## 3. Core helper functions / modules

### 3.1 Command and tool bootstrap

- `require_cmd <name>`
  - Verifies that a command is available; exits with an error if missing.
  - Used early to enforce the presence of `sudo` and `emerge`.

- Equery and qlist bootstrap:
  - If `equery` is missing, installs `app-portage/gentoolkit`.
  - If `qlist` is missing, installs `app-portage/portage-utils`.

These helpers provide the primitives used by the rest of the script to query and manage packages.

### 3.2 Package detection and installation

- `pkg_installed(pkg)`
  - Uses `qlist -I` to check if a given category/atom is installed.

- `install_pkg(pkg)`
  - Primary installer wrapper around `emerge`.
  - First pass:
    - `sudo emerge --ask=n --autounmask-write --autounmask-continue --binpkg-respect-use=y "$pkg"`
    - If it succeeds, the package is considered installed.
  - Retry path:
    - Runs `etc-update` in a non-interactive mode (`echo -e "-5\ny" | etc-update`) if available.
    - Then performs `sudo emerge --ask=n --oneshot "$pkg"` as a fallback.

- `install_if_missing(pkg)`
  - Uses `pkg_installed` to skip already-installed packages.
  - On first install or failed/partial previous builds, calls `install_pkg`.

- `install_list(label, pkgs...)`
  - Batch-installs a labeled set (e.g. "Hyprland stack", "Fonts").
  - Loops over `pkgs[@]` and invokes `install_if_missing` for each.

### 3.3 Portage configuration helpers

- `ensure_use_flags()`
  - Writes `/etc/portage/package.use/hyprland-qt` with the required USE flags for:
    - Qt 6 (qtbase, qtwayland, qtdeclarative)
    - `libxkbcommon` (X + Wayland)
    - `systemd` with `policykit`
    - GTK3/GTK4, cairo/cairomm, Waybar, XFCE panel + Thunar stack
    - PipeWire/Libcanberra/Libpulse for audio
    - GTK4 layer-shell for swaync
    - Kitty Wayland support
    - Vulkan loader flags

- `ensure_video_cards()`
  - Targets `/etc/portage/make.conf`.
  - Default `VIDEO_CARDS="virgl"` (VM-oriented), then attempts to append GPU-specific cards based on `lspci` output (NVIDIA/AMD/Intel heuristics).
  - Replaces an existing `VIDEO_CARDS=` line if present; otherwise appends a new line.

- `ensure_gentoo_rsync_repo()`
  - Forces the main Gentoo repo to be synced via rsync, not git.
  - Writes `/etc/portage/repos.conf/gentoo.conf` with:
    - `location = /var/db/repos/gentoo`
    - `sync-type = rsync`
    - `sync-uri = rsync://rsync.gentoo.org/gentoo-portage`
    - `auto-sync = yes`
  - Removes any `.git*` metadata directly under `/var/db/repos/gentoo` to avoid conflicts.

- `ensure_pamixer_cxx17_fix()`
  - Creates `/etc/portage/env/cxx17-fix` with `CXXFLAGS="${CXXFLAGS} -std=c++17"`.
  - Ensures `/etc/portage/package.env/pamixer` contains `media-sound/pamixer cxx17-fix` (appended only once).

- `ensure_pipewire_use_fix()`
  - Manages `/etc/portage/package.use/pipewire` and `/etc/portage/package.use/libpulse`.
  - Adds or ensures the following lines exist:
    - `media-video/pipewire sound-server extra alsa-pipewire`
    - `media-libs/libpulse glib`
  - Guards against duplication by checking file contents before appending.

### 3.4 Pre-building problematic math libraries

- `prebuild_problematic_binaries()`
  - Purpose: avoid issues where binary packages of heavy math libs can cause Python async build/runtime problems later.
  - Packages:
    - `sci-libs/fftw`
    - `sci-libs/openblas`
    - `sci-libs/flexiblas`
  - For each, if not installed:
    - `sudo emerge -v --ask=n --usepkg=n "$pkg"` to force a source build.

### 3.5 Hyprland stack definitions

- `HYPR_PACKAGES` array
  - Core graphical stack:
    - `gui-wm/hyprland`
    - `gui-apps/hypridle`, `hyprlock`, `hyprpaper`, `hyprshot`
    - `gui-libs/hyprcursor`, `xdg-desktop-portal-hyprland`, `hyprland-qt-support`, `hyprland-qtutils`
  - Wayland utilities:
    - `gui-apps/awww`, `clipman`, `grim`, `slurp`, `swappy`, `swaync`, `waybar`, `wlogout`, `wofi`, `wlr-randr`, `wl-clipboard`, `waypaper`
    - `gui-apps/nwg-drawer`, `nwg-displays`, `quickshell`
  - Audio and media:
    - `media-video/pipewire`, `wireplumber`
    - `media-libs/alsa-lib`, `media-sound/alsa-utils`
    - `media-sound/pavucontrol` (listed twice in the array but harmless)
    - `media-sound/pamixer` (with C++17 fix)
    - `media-sound/playerctl`
    - `media-libs/libcanberra`
    - `media-video/mpv`
  - System / CLI tools:
    - `app-misc/fastfetch`, `ranger`, `tmux`, `yazi`
    - `app-shells/starship`, `zoxide`
    - `sys-apps/bat`, `eza`, `sys-fs/ncdu`
    - `dev-lang/python`, `dev-libs/libdbusmenu`, `dev-libs/newt`
  - Desktop integration:
    - `net-misc/networkmanager`
    - `net-wireless/bluez`, `bluez-tools`
    - `sys-auth/rtkit`
    - XFCE components for Thunar and panel: `thunar`, `tumbler`, `xfce4-panel`, `libxfce4windowing`, `libxfce4ui`, `exo`
  - Misc extras:
    - `sys-apps/flatpak` (Flatpak runtime)
    - `www-client/google-chrome`
    - `x11-misc/matugen`, `rofi`, `wallust`, `xdg-user-dirs`
    - `x11-terms/kitty`
    - `x11-libs/libdrm`

- `FONTS` array
  - Various font families used by the desktop configuration:
    - Cardo, Cascadia Code, DejaVu, Fira Code, Font Awesome, Hack,
      JetBrains Mono, Nerd Fonts, Droid, Victor Mono, Fantasque Sans Mono,
      Noto (including emoji), Source Code Pro, Symbols Nerd Font, URW fonts.

### 3.6 File deployment helper

- `copy_file(src, dst, mode)`
  - Thin wrapper around `install -Dm<mode>`.
  - Logs success and warns if the source file is missing.
  - Used heavily by `configure_ly` to deploy config files from `system/` into `/etc`.

### 3.7 Login manager: `configure_ly()`

Responsibilities:

1. Ensure packages:
   - `x11-misc/ly`
   - `app-misc/cmatrix` (for the matrix animation)

2. Deploy configuration from the repo snapshot:
   - `system/etc/ly/config.ini` → `/etc/ly/config.ini`
   - `system/etc/ly/save.ini`   → `/etc/ly/save.ini`
   - `system/etc/ly/wsetup.sh`  → `/etc/ly/wsetup.sh`
   - `system/etc/ly/xsetup.sh`  → `/etc/ly/xsetup.sh`
   - `system/etc/pam.d/ly`      → `/etc/pam.d/ly`
   - `system/etc/pam.d/hyprlock`→ `/etc/pam.d/hyprlock`

3. Enforce some defaults in `/etc/ly/config.ini`:
   - Sets `animation = matrix`
   - Sets `bigclock = true`

4. Enable the login manager:
   - `sudo systemctl enable ly.service`

5. Default session selection:
   - The `save.ini` file is part of `system/etc/ly/` and contains `session_index`.
   - That index is aligned to the Hyprland Wayland session entry, so the default ly session is Hyprland (not Hyprland-uwsm).

### 3.8 PipeWire and audio: `configure_pipewire()`

- Adds the current user to audio-related groups: `audio`, `video`, `pipewire` (where present).
- Enables lingering for the user via `loginctl enable-linger`, so user systemd services can run without an active login session.
- Attempts to enable and start the user units:
  - `pipewire.socket`
  - `pipewire-pulse.socket`
  - `wireplumber.service`
- If user-level systemd is not active yet (e.g. running from TTY with no user systemd session), logs a warning and prints the manual command to run later as the user.

### 3.9 User runtime exports: `configure_shell_runtime_exports()`

- Ensures the following vars are exported in `~/.bashrc` and `~/.zshrc`:

  ```sh
  # Hyprland audio runtime exports (added by gentoo-install-hyprland.sh)
  export XDG_RUNTIME_DIR="/run/user/$(id -u)"
  export PULSE_SERVER="unix:${XDG_RUNTIME_DIR}/pulse/native"
  ```

- Only appends the block once per file by checking for a marker comment.

### 3.10 Flatpak remote: `configure_flatpak_flathub()`

- Only runs if the `flatpak` command is available (installed as part of `HYPR_PACKAGES`).
- Operates at user scope (`--user`).
- Behavior:
  1. Checks `flatpak --user remote-list` for a remote named `flathub`.
  2. If missing, runs:

     ```sh
     flatpak --user remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
     ```

  3. Logs whether Flathub was added or already present.
- Does not configure any beta/testing remotes; this is intentionally limited to the main Flathub remote.

### 3.11 GTK dark theme: `configure_gtk_dark_theme()`

- Writes `~/.config/gtk-3.0/settings.ini` and `~/.config/gtk-4.0/settings.ini` for the current user:

  ```ini
  [Settings]
  gtk-theme-name=Adwaita-dark
  gtk-application-prefer-dark-theme=1
  gtk-icon-theme-name=Adwaita
  ```

- Provides a consistent dark theme preference for GTK applications under Hyprland.

---

## 4. Script switches and invocation

`gentoo-install-hyprland.sh` currently supports a single user-facing flag:

- `--set-dark`
  - Mode: configure only the GTK dark theme for the current user and exit.
  - Behavior:
    - Calls `configure_gtk_dark_theme`.
    - Prints completion message and terminates without touching packages, ly, audio, or Portage.

- `-h`, `--help`
  - Prints usage and exits.

Any other arguments cause an error and immediate exit.

### 4.1 Normal install run

From the repo root:

```sh
bash scripts/gentoo-install-hyprland.sh
```

This performs the full sequence of configuration and package installation described in section 2.2.

### 4.2 Theme-only mode

```sh
bash scripts/gentoo-install-hyprland.sh --set-dark
```

This is safe to run on any system where you want the GTK dark theme settings applied without modifying system-wide configuration.

---

## 5. Other scripts in `scripts/` (summary)

This section briefly documents the other scripts so an agent can understand their responsibilities and avoid unintentional overlap.

- `deploy-dotfiles.sh`
  - Deploys dotfiles from `dotfiles/home` into the current user’s `$HOME`.
  - Backs up any replaced files into `~/.local/share/dotfiles-backup/<timestamp>`.
  - Ensures `~/.local/bin` exists and is added to PATH via `~/.config/profile.d/local-bin.sh`.
  - Copies suckless helper scripts to `~/.local/bin`.

- `gentoo-cfg-backup.sh`
  - Creates a compressed tarball backup of key system configuration:
    - `/etc/portage/`, `/etc/locale.gen`, `/etc/hosts`, `/etc/fstab`, and the user’s `~/.config/`.

- `sync-from-vm.sh`
  - Syncs live user dotfiles from the running system back into the repo (`dotfiles/home`).
  - Optional `--include-system` flag to also capture `system/` snapshot (Portage, fstab, locale, world, kernel `.config`).
  - Optional `--dry-run` / `-n` for rsync preview.
  - Regenerates metadata in `docs/` (`emerge-info.txt`, `eselect-profile.txt`, `uname.txt`).

- `sync-gentoo-cfg.sh`
  - More structured system configuration sync into `system/` with logging.
  - Options:
    - `-h`, `--help`   – show help
    - `-q`, `--quiet`  – quieter rsync
    - `-d`, `--dry-run` – dry-run mode
  - Captures:
    - `/etc/portage/`, `/var/lib/portage/`
    - Core system files (`fstab`, locale, hostname, hosts, resolv.conf, profile, environment)
    - Kernel configs (`/boot/config-*`, `/usr/src/linux/.config`)
    - Module and systemd configs
    - Metadata into `docs/`

- `post-install-cleanup.sh`
  - Performs maintenance after heavy Portage activity:
    - Cleans distfiles (`eclean-dist -d` or manual rm).
    - Clears `/var/tmp/portage/*`.
    - Optionally runs `eclean-pkg` for old binary packages.
    - Optionally runs `eix-update` if available.
    - Optionally runs `fstrim -av` and `journalctl --vacuum-time=7d`.

- `set-default-pointer-theme.sh`
  - Writes `/usr/share/icons/default/index.theme` with:

    ```ini
    [Icon Theme]
    Inherits=Adwaita
    ```

  - Ensures the default X/Wayland cursor theme is Adwaita, aligning with the Hyprland config expectations.

- `install-bugsvim.sh`
  - Installs Bugsvim Neovim configuration for Gentoo.
  - Ensures `git` exists.
  - Clones or updates `https://github.com/dwilliam62/bugsvim` into `~/bugsvim`.
  - Executes `install-gentoo.sh` inside the repository.

- `update.sh`
  - Structured Gentoo updater with reporting:
    - Modes: `--eval`, `--dry-run`, `--apply` (exactly one required).
    - Options: `--no-sync`, `--use-binpkgs`, `--auto-yes`, `--help`.
  - Writes pre-update markdown summaries (`precheck-<DATE>.md`) describing pending world updates.
  - On `--apply`, performs `emerge` updates on `@world` and writes a post-update report (`Post-Update-<DATE>-Report.md`).

- `yuni-update.sh`
  - Simpler update helper using `emaint sync -a`, `eix-update`, and `emerge --update --deep --newuse --getbinpkg @world`.
  - Uses `lolcat` for colored section headers and sends a desktop notification summarizing updated packages.

- `i3-install-script-onhold`
  - Older i3-based installer that follows a similar pattern to the Hyprland script (USE flags, ly config, etc.).
  - Marked “on hold” and not part of the primary Hyprland flow but kept for reference.

---

## 6. How to extend `gentoo-install-hyprland.sh`

When adding new behavior, the recommended pattern is:

1. Add any new Portage configuration to dedicated `ensure_*` helpers that write into `/etc/portage/*`.
2. Extend `HYPR_PACKAGES` or `FONTS` with new atoms instead of ad-hoc `emerge` calls.
3. Use `install_if_missing` for new packages to keep the script idempotent.
4. For new configuration files under `/etc`, place templates under `system/` and deploy via `copy_file` from within a `configure_*` function.
5. Keep all top-level actions behind functions and only call them once at the bottom of the script in a clear, ordered sequence.
