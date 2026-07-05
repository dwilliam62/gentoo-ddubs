# Kernel 7.1.3 Boot Issue - Troubleshooting & Fix

## Problem
Kernel 7.1.3 installed but system boots kernel 6.18.5 instead.

## Root Cause
The GRUB configuration (`/boot/grub/grub.cfg`) contains incorrect paths:
```
linux   /root/boot/kernel-7.1.3-gentoo-dist-bin ...
```

Should be:
```
linux   /boot/kernel-7.1.3-gentoo-dist-bin ...
```

This typically occurs with btrfs subvolume setups where GRUB's root detection incorrectly includes the subvolume mount point in the path.

## Quick Diagnosis

SSH into the affected system and run:

```bash
ssh dwilliams@192.168.40.5

# Check current kernel
uname -r

# List available kernels
ls -lh /boot/kernel-*

# Check GRUB paths
grep "linux\s\+" /boot/grub/grub.cfg | head -3
```

If you see `/root/boot/` paths, proceed with the fix.

## Solution: Use fix-remote-grub.sh (Recommended)

A new script has been created to diagnose and fix the GRUB configuration remotely:

```bash
# From your local machine, in the gentoo-ddubs directory:

# 1. Check current GRUB configuration
bash scripts/fix-remote-grub.sh dwilliams@192.168.40.5 --check

# 2. Deploy corrected /etc/default/grub and regenerate GRUB
bash scripts/fix-remote-grub.sh dwilliams@192.168.40.5 --deploy-config --regen

# 3. Reboot the remote system
ssh dwilliams@192.168.40.5 'sudo reboot'

# 4. Verify after boot
ssh dwilliams@192.168.40.5 'uname -r'
# Should output: 7.1.3-gentoo-dist-bin
```

What the script does:
1. Verifies SSH connection to remote system
2. Checks current GRUB configuration and kernel status
3. Backs up current `/etc/default/grub`
4. Deploys corrected configuration (10-second timeout, proper paths)
5. Regenerates GRUB config with correct paths
6. Verifies the fix

### Alternative: Manual Fix on Remote System

If you prefer to fix it manually on the remote system:

### Option 2: Manual Fix

```bash
ssh dwilliams@192.168.40.5

# Backup current config
sudo cp /boot/grub/grub.cfg /boot/grub/grub.cfg.bak-$(date +%Y%m%d%H%M%S)

# Regenerate GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Verify kernel 7.1.3 is in the config
sudo grep "kernel-7.1.3" /boot/grub/grub.cfg

# Check for any remaining /root/boot/ paths (should be none)
sudo grep "/root/boot/" /boot/grub/grub.cfg || echo "No /root/boot/ paths found - OK"
```

## After Fix

### 1. Verify GRUB Config
```bash
sudo /path/to/fix-grub.sh --info
```

Expected output should show kernel 7.1.3 as the default entry with correct paths.

### 2. Test Boot
Reboot and select the 7.1.3 kernel from GRUB menu (or let it auto-select).

```bash
sudo reboot
```

### 3. Verify After Boot
After reboot:
```bash
uname -r
# Should output: 7.1.3-gentoo-dist-bin
```

## Prevention

The `after-kernel-update.sh` script should be run after every kernel update to ensure GRUB is regenerated with correct paths:

```bash
sudo /path/to/after-kernel-update.sh
```

This:
- Prunes kernels without matching modules
- Ensures latest kernel modules are available
- Regenerates GRUB config
- Validates the new kernel is in the config

## If Fix Doesn't Work

### Check GRUB Boot Parameters

The problem might be in GRUB's root detection. Check `/etc/default/grub`:

```bash
ssh dwilliams@192.168.40.5
cat /etc/default/grub | grep -E "GRUB_|root"
```

Look for `GRUB_PRELOAD_MODULES`, `GRUB_ROOT`, or similar that might be misconfigured.

### Check Btrfs Mount

```bash
# Check how /boot is mounted
mount | grep -E '/boot|root'

# On btrfs systems, you might see:
# /dev/... on /boot type btrfs (rw,...,subvol=@boot)
# /dev/... on / type btrfs (rw,...,subvol=@)
```

If `/boot` is on a subvolume, GRUB's `grub-mkconfig` needs to understand the filesystem layout. Sometimes you need to specify the correct subvolume in `/etc/default/grub`:

```bash
# Edit /etc/default/grub and ensure the correct boot root is set
# Then regenerate
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Reference

- `scripts/fix-grub.sh` — Interactive GRUB config management tool
- `scripts/after-kernel-update.sh` — Automated kernel update & GRUB regeneration
