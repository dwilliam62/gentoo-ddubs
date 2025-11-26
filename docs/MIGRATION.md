# Migration and Restoration Guide

This document describes how to migrate your Gentoo system configuration to another machine or restore from this snapshot.

## What Gets Captured

The `scripts/sync-gentoo-cfg.sh` script captures:

- **Portage Configuration** (`/etc/portage/`)
  - `make.conf` — global build flags, USE flags, compiler settings
  - `make.profile` — profile symlink (e.g., default/linux/amd64/23.0/systemd)
  - `repos.conf/` — repository configurations
  - `package.use/`, `package.accept_keywords/`, `package.env/`, `package.license/` — per-package settings
  - `savedconfig/` — saved build configurations

- **Portage Database** (`/var/lib/portage/`)
  - `world` — set of explicitly installed packages
  - `world_sets` — package set definitions
  - `eclass/` — eclass cache

- **System Configuration**
  - `/etc/fstab` — filesystem mount points
  - `/etc/locale.gen`, `/etc/locale.conf` — localization settings
  - `/etc/hostname`, `/etc/hosts` — network identification
  - `/etc/profile`, `/etc/environment` — shell environment
  - `/etc/modprobe.d/` — kernel module options
  - `/etc/systemd/` — systemd unit configurations

- **Kernel Configuration**
  - `/usr/src/linux/.config` — current kernel build configuration
  - `/boot/config-*` — installed kernel config (for reference)

- **System Metadata** (`docs/`)
  - `emerge-info.txt` — Portage and system information
  - `eselect-profile.txt` — active profile
  - `uname.txt` — kernel and hardware info
  - `os-release.txt` — distribution identification

## Capturing Configuration

### On the Source System

```bash
# Clone or navigate to the repo
cd /path/to/gentoo-ddubs

# Run the sync script
bash scripts/sync-gentoo-cfg.sh

# Or with options
bash scripts/sync-gentoo-cfg.sh --dry-run  # preview changes
bash scripts/sync-gentoo-cfg.sh --quiet    # suppress verbose output
```

The script will:
1. Create or update all files in `system/`
2. Export metadata to `docs/`
3. Log all actions to `.sync-logs/sync-TIMESTAMP.log`

After running, commit the changes:

```bash
git add -A
git commit -m "sync: update gentoo config snapshot"
git push
```

## Restoring Configuration to a New System

### Prerequisites

- Fresh Gentoo installation with basic system packages
- Git (to clone the repository)
- Portage initialized (`sudo emerge-sync` or similar)

### Step 1: Clone the Repository

```bash
git clone https://github.com/dwilliam62/gentoo-ddubs.git
cd gentoo-ddubs
```

### Step 2: Review System Differences

Before restoring, compare the source and target systems:

```bash
# Check system profile
cat docs/eselect-profile.txt

# Review kernel version
cat docs/uname.txt

# Check Portage info
cat docs/emerge-info.txt
```

### Step 3: Restore Portage Configuration (Recommended)

Use rsync with `--dry-run` first to preview:

```bash
# Preview what would be synced
sudo rsync -av --dry-run system/etc/portage/ /etc/portage/

# Actually sync (will merge, not delete)
sudo rsync -av system/etc/portage/ /etc/portage/
```

**Note:** This is safer than using `--delete` on a new system, as rsync will merge new files without removing your existing configuration.

### Step 4: Restore Portage World Set

```bash
# Backup current world file
sudo cp /var/lib/portage/world /var/lib/portage/world.backup

# Restore the snapshot
sudo cp system/var/lib/portage/world /var/lib/portage/world

# Update your system to match
sudo emerge --sync
sudo emerge -uDN @world
```

### Step 5: Restore System Configuration

Selectively restore files based on your needs:

```bash
# Restore fstab (review first!)
sudo diff system/etc/fstab /etc/fstab
sudo cp system/etc/fstab /etc/fstab

# Restore locale configuration
sudo cp system/etc/locale.gen /etc/locale.gen
sudo locale-gen

# Restore hostname
sudo cp system/etc/hostname /etc/hostname

# Restore modules config (if applicable)
sudo rsync -av system/etc/modprobe.d/ /etc/modprobe.d/

# Restore systemd configs (review first)
sudo rsync -av system/etc/systemd/ /etc/systemd/
sudo systemctl daemon-reload
```

### Step 6: Deploy User Dotfiles

After restoring system configuration, deploy user dotfiles:

```bash
bash scripts/deploy-dotfiles.sh
```

This will safely install Hyprland, DWM, and other user configurations.

## Restoring Kernel Configuration

If you want to rebuild the kernel with the same configuration:

```bash
# Check what kernel version was used
cat docs/uname.txt

# If using the same kernel version:
sudo cp system/usr/src/linux/.config /usr/src/linux/.config
cd /usr/src/linux
sudo make oldconfig  # or 'make menuconfig' to review
sudo make && sudo make modules_install install
```

## Troubleshooting

### "Permission denied" when syncing

The script requires `sudo` for reading protected system files. Ensure you can run `sudo` without password prompts, or enter your password when prompted.

### Portage world set conflicts

If restoring the world set causes emerge conflicts:

```bash
# Revert to backup
sudo cp /var/lib/portage/world.backup /var/lib/portage/world

# Or manually review and merge conflicts
sudo emerge -uDN @world
```

### Locale generation fails

If `sudo locale-gen` fails:

```bash
# Check supported locales
grep -v '^#' /etc/locale.gen | grep -v '^$'

# Update locale.gen to match your system's available locales
sudo nano /etc/locale.gen
sudo locale-gen
```

### Systemd units won't start

After restoring systemd configs, reload and check for errors:

```bash
sudo systemctl daemon-reload
sudo systemctl status <unit-name>  # check specific unit
journalctl -xe  # view recent errors
```

## Incremental Updates

To keep your snapshot fresh, re-run the sync script periodically:

```bash
bash scripts/sync-gentoo-cfg.sh
git add -A
git commit -m "sync: update gentoo config"
```

This captures any new package settings, make.conf changes, or system configurations since the last sync.

## See Also

- [README.md](../README.md) — Quick start and overall setup
- [CHANGELOG.md](../CHANGELOG.md) — Historical changes to the snapshot
- [Gentoo Handbook](https://wiki.gentoo.org/wiki/Handbook:Main_Page) — Official documentation
