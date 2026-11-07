# Changelog

All notable changes to this project will be documented in this file.

## Nov 2026

- Refactored all 29 scripts onto a shared library
  - Added `scripts/lib/common.sh` (with `scripts/lib/README.md` documenting the API)
    - Colours, icons and helpers: `log_info`/`log_ok`/`log_warn`/`log_err`, `die`, `step`, `run_step`/`run_summary`, `have`, `require_cmd`, `need_root`/`require_root`, `portage_conf_file`, `pkg_installed`, `version_ge`
    - `portage_conf_file` handles configs that are either a file or a per-package directory
    - Output honours `NO_COLOR` and non-tty stdout, so icons/colours are now consistent everywhere
  - Every script sources it through an absolute `SCRIPT_DIR`, so scripts run from any cwd
  - Each script keeps its historical message prefix and layout (e.g. `[migrate-efi-to-grub]`, `[after-kernel-update]`) as thin wrappers
  - Steps that fail now surface in a `run_summary` and set a non-zero exit status (`cleanup.sh`, `post-install-cleanup.sh`)
- Fixed correctness and safety bugs
  - `update.sh`: post-update report dropped one package row (off-by-one); the `sudo` re-exec lost `JUST_OXWM`; `emaint sync -a` errors were silently ignored
  - `install-grub-efi.sh`: NVMe/mmcblk devices were truncated to `/dev/nvme0n`; `df` output could wrap on long device names; GRUB target arch is detected instead of hardcoded x86_64
  - `manage-efi-boot.sh`: `--set-default` replaced the whole `BootOrder`; the initramfs was not copied next to `vmlinuz.efi` (unbootable after module changes); `--switch-grub`/`--switch-efi` now prioritise an entry instead of discarding the others
  - `migrate-efi-to-grub.sh`: `BootOrder` is prepended to rather than replaced; the detected EFI mountpoint is reused for the boot-entry step instead of assuming `/boot/efi`
  - `after-kernel-update.sh`: `eclean-kernel -L auto` aborted (only `std`/`blspec` are valid layouts); BLS systems no longer fail trying to verify a GRUB menu they do not boot from
  - `sync-gentoo-cfg.sh`: `[[ -f /boot/config-* ]]` never expanded a glob; `emerge-info` is not a command (now `emerge --info`); sudo redirects no longer create root-owned log files
  - `gentoo-cfg-backup.sh`: under `sudo`, `whoami` captured `/root/.config` instead of the invoking user's home
  - `deploy-dotfiles.sh`, `install-fuse.sh`, `fix-variety.sh`, `install-weather-waybar.sh`: rewritten for idempotency, artifact checks and hard failure instead of continuing half-installed
  - `install-hyprmod.sh`: `--help` and unknown arguments are handled; `gentoo-install-hyprland.sh` passes Nix installer flags without re-globbing
  - Repeated `emerge` USE-flag writes are idempotent; `lspci` GPU detection is de-duplicated; `eselect` module probing no longer assumes a fixed module name
- Lint: shellcheck-clean at warning level across all scripts
  - Fixed dead variables, `local` masking exit status (SC2155), literal `=~` matching (SC2076), sudo redirects (SC2024) and unquoted pattern removal (SC2295)
  - Seven `SC2016` notes remain by design: awk field references and a runtime-expanded `$(id -u)` written into shell rc files
  - shellcheck is not installable here (masked `~amd64`, pulls masked `dev-haskell/aeson`), so the official static binary is used
- Reworked `scripts/install-contour.sh`
  - Added `--check-only` and `--help`; check-only writes the Portage configuration, skips Steps 1–2 (overlay setup), reports Qt USE overrides, and previews the Qt rebuild and Contour emerge with `emerge --pretend` without merging anything
  - Trimmed the generated `/etc/portage/package.use/contour`: dropped `qml`, `vulkan` and `qtquick3d`, while keeping `opengl` on `qtbase`, `qtdeclarative` and `qtmultimedia` because their `opengl=` USE dependencies must match
  - Kept `sys-libs/zlib minizip` because the installed `virtual/minizip` (pulled in by `media-libs/assimp`) requires it; documented why `qml`/`vulkan` are not negated (`quickshell` hard-requires `qtbase[vulkan]`, and other `package.use` files enable `qml`)
  - Suppressed Portage's "binary packages have been ignored due to non matching USE" warning with `--binpkg-respect-use=y` on every emerge
  - Step 6 now uses `--oneshot` so the Qt dependencies stay out of `@world`; `@world` keeps only `gui-apps/contour`
  - Added non-fatal warnings when global `USE` or another `package.use` file turns `qml`/`vulkan` back on, followed by the effective per-package flags from `equery uses`
- Finished the remaining review findings
  - `after-kernel-update.sh` handles `vmlinuz-*` images as well as `kernel-*` when pruning, detecting the newest kernel, verifying artifacts and checking `grub.cfg` (exact image names only, not a loose `-<version>` match)
  - `after-kernel-update.sh` gained `--check`/`--dry-run`: it lists the /boot images it recognises, the prune decisions, the newest-kernel artifacts and the GRUB reference, changes nothing, and exits non-zero on problems. `/boot` is usually `0700 root`, so such hosts need `sudo` even for the check
  - `gentoo-install-hyprland.sh`: the truncating Portage writes (hyproverlay and gentoo `repos.conf`, `package.use/hyprland-qt`, `package.use/libdrm-gpu-cards`, `/etc/portage/env/cxx17-fix`, the Discord `package.license` entry) go through a `write_managed_file` wrapper that reports entries they would drop
  - `gentoo-install-hyprland.sh` also installs `/etc/kernel/postinst.d/90-after-kernel-update-check`, which appends an `after-kernel-update.sh --check` report to `/var/log/after-kernel-update-check.log` after every kernel install. It is deliberately separate from the EFI-copy hook, which GRUB-managed systems skip or have removed, and it never fails the merge
  - `clone-repo-configs.sh` warns before replacing `package.use/mesa-gpu-cards`, `libdrm-gpu-cards`, `ly-login-manager` and `audio-runtime`, which it used to truncate silently
  - Audited `tui-installer/scripts/main.sh`: its only truncating Portage write is `repos.conf/gentoo.conf`, in the stage3 chroot it just created, so it keeps the plain write
  - Audited `install-grub-efi.sh`, `manage-efi-boot.sh` and `install-fuse.sh`: none of them write to `/etc/portage` (they only touch `/boot`, the EFI variables, `/etc/modules-load.d`, `/etc/fuse.conf` and `/dev/fuse`), so none need a drift warning
  - `scripts/lib/common.sh`: `warn_drift_from_managed <path> <content>` reports host-specific entries a managed write would drop; `install-contour.sh`, `set-glaze-7-hl-fix.sh` and `update-yazi.sh` now call it before replacing a file
  - `warn_drift_from_managed` normalizes both sides of the comparison (comments stripped, whitespace collapsed, lines trimmed), so an indented file no longer reports entries that the rewrite writes verbatim; it is documented as being for one-entry-per-line Portage files only
  - `gentoo-install-hyprland.sh`: added `ensure_overlay_keywords` with explicit per-atom `~amd64` entries instead of blanket `*/*::<overlay>` lines (an existing blanket entry is respected, so nothing is appended), plus `dev-qt/qt5compat icu qml`, `dev-cpp/cpptrace unwind`, the Python 3.13 target block and `media-plugins/alsa-plugins`
- Followed `docs/fix-contour-plan.md` on the source host and fixed what it exposed
  - Added `portage_backup_file`/`portage_write_file` to `scripts/lib/common.sh` (`PORTAGE_BACKUP_DIR`, default `/root/portage-backups`): the previous contents are backed up outside `/etc/portage` and unchanged files are not rewritten, because Portage reads every regular file inside `package.*` directories and a `*.bak` left in place becomes live configuration
  - `install-contour.sh` writes its three managed files through that helper, so a rerun no longer silently discards hand-added flags
  - `install-contour.sh` warns when any of its three managed files already holds entries the new contents would drop (the `qtbase[vulkan]` that installed `gui-apps/quickshell` requires, for example) and points at a separate `-extra` snippet
  - `install-contour.sh`, `update.sh`, `update-yazi.sh`, `install-hyprmod.sh`: `app-eselect/eselect-repository` is installed with `--oneshot` and stays out of `@world`
  - `set-glaze-7-hl-fix.sh` and `update-yazi.sh` no longer truncate an existing mask file or `repos.conf` entry in place
  - `docs/fix-contour-plan.md`: the Phase 2.8 backup recipe copies outside `/etc/portage`; rows 8 and 9 match the script's backup and `--oneshot` behaviour
  - `set-glaze-7-hl-fix.sh`: the check-mode advice lines and the final summary printed a literal `\n\n` (their printf formats carried escaped backslashes); they now emit real line breaks

## Oct 2026

- Added `scripts/fix-waybar-reload-crash.sh`
  - Waybar aborts on reload when a second bar is running
  - `pkill -SIGUSR2` is what the KooL dots send on lid, monitor and wallpaper events
  - Installs a Portage user patch giving each Waybar process its own D-Bus app id, then rebuilds
  - `--check` reports status, `--test` reproduces and verifies the crash, `--remove` backs it out
- Added `gentoo-waybar-issue.md`
  - Symptom, cause, evidence and maintenance notes for the above

## Sep 2026

- Added scripts/set-glaze-7-hl.sh 
    - Hyprland doesn't support glaze v8.0 
    - Script masks glaze and will optionally reubild Hyprland


## Aug 2026

- Added `install-contour` script
- Added `install-fuse` script
- Added `install-hyprmod` script
- Fixed `oxwm` build errors

## Jul 2026

- Fixed:
  - `update.sh` building oxwm failed on unbound variable

- Added:
  - Script `quickshell-qtcompact.sh`

## Jun 2026

- Updated:
  - `gentoo-install-hyprland` script
    - Chaned default from `efibootmgr` to `grub`
  - `yazi` build script to install current yazi bld
- Added:
  - Script to migrate `efibootmgr` to grub with current kernel
  - `oxwm` install script
    - Removed `oxwm` install from hyprland install
  - `clone-gentoo.sh` script
  - installs my config on blank systems
  - `ly` login mgr
  - `nwg-display`
  - `variety`
  - `docutils`
  - `pycairo`
  - `pygobject`
  - `waypaper`
  - python target fix to `make.conf`
  - `PYTHON_TARGETS="python3_13 python3_14"`
  - `PYTHON_SINGLE_TARGET="python3_14"`
- Added python overrides for:
  - `nwg-display`
  - `variety`
  - `docutils`
  - `pycairo`
  - `pygobject`
  - `waypaper`
- Added python target fix to `make.conf`
  - `PYTHON_TARGETS="python3_13 python3_14"`
  - # `PYTHON_SINGLE_TARGET="python3_14"`
- Added gentoo installer
  - From `https://github.com/oddlama/gentoo-install`
  - I had to patch it to get it to install
  - The patched version is now included
- Added python overrides for:
  - `nwg-display`
  - `variety`
  - `docutils`
  - `pycairo`
  - `pygobject`
  - `waypaper`
- Added python target fix to `make.conf`
  - `PYTHON_TARGETS="python3_13 python3_14"`
  - `PYTHON_SINGLE_TARGET="python3_14"`
    > > > > > > > fa38ee9d (Added tui-installer from GH oddlama/gentoo-install)

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
