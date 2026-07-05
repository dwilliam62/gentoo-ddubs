# Install GRUB as EFI Bootloader

## Quick Fix for Kernel 7.1.3 Boot Issue

The remote system is using **direct EFI kernel boot** instead of GRUB, which is why kernel 7.1.3 doesn't boot (old 6.18.5 kernel is hardcoded in EFI).

To fix this, install GRUB as the EFI bootloader:

## Steps

### 1. Copy Script to Remote System

```bash
scp scripts/install-grub-efi.sh dwilliams@192.168.40.5:/tmp/
```

### 2. SSH into Remote System

```bash
ssh dwilliams@192.168.40.5
```

### 3. Check Current Setup (Optional)

```bash
sudo bash /tmp/install-grub-efi.sh --check
```

This shows:
- Current kernel (should be 6.18.5)
- Available kernels (should include 7.1.3)
- Current EFI boot entries
- GRUB installation status

### 4. Install GRUB and Regenerate Config (Full Fix)

```bash
sudo bash /tmp/install-grub-efi.sh --full
```

This will:
1. Verify EFI system setup
2. Install GRUB to the EFI partition (`/boot/efi/EFI/gentoo`)
3. Regenerate GRUB configuration with all available kernels
4. Display the menu entries

### 5. Reboot and Test

```bash
sudo reboot
```

On reboot, you should see:
- **GRUB menu** with kernel options (10-second timeout)
- Option to select **7.1.3-gentoo-dist-bin** kernel
- Select it and boot

### 6. Verify After Boot

```bash
uname -r
# Should output: 7.1.3-gentoo-dist-bin
```

## If GRUB Menu Doesn't Appear

Press **ESC** or **SPACE** during boot to show the GRUB menu.

If it still doesn't show:

```bash
# Check EFI boot order
sudo efibootmgr -v

# GRUB should be first (BootCurrent should point to gentoo entry)
# If not, manually set it:
sudo efibootmgr -n 0000  # or whichever number is the "gentoo" entry
sudo reboot
```

## What Changed

**Before** (Direct EFI Kernel Boot):
- EFI entry `Boot0004 (gentoo)` pointed directly to `/boot/efi/vmlinuz.efi`
- No GRUB menu, no kernel selection
- Old 6.18.5 kernel was hardcoded

**After** (GRUB EFI Boot):
- EFI entry points to GRUB bootloader at `/boot/efi/EFI/gentoo/grubx64.efi`
- GRUB menu shows all available kernels on boot
- Can select 7.1.3 or any other kernel
- Easy kernel switching and GRUB parameters

## Troubleshooting

### GRUB installation fails with "invalid device specification"

The script auto-detects the boot device. If it fails:

```bash
# Find your boot device manually
df /boot/efi
# Example: /dev/sda1

# Install GRUB manually
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi \
  --bootloader-id=gentoo --recheck /dev/sda
```

### GRUB menu shows wrong kernel as default

Edit `/etc/default/grub`:

```bash
sudo nano /etc/default/grub
# Set: GRUB_DEFAULT=0  (or use kernel version string)
# Set: GRUB_TIMEOUT=10
```

Then regenerate:

```bash
sudo bash /tmp/install-grub-efi.sh --regen
sudo reboot
```

### Need to switch back to direct EFI boot

Use `manage-efi-boot.sh` to switch boot methods.

## Reference

- `scripts/install-grub-efi.sh` — GRUB EFI installation tool
- `scripts/manage-efi-boot.sh` — EFI boot entry management
- `scripts/after-kernel-update.sh` — Automated kernel updates
