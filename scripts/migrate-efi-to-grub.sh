#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[migrate-efi-to-grub] %s\n' "$*"
}

die() {
  printf '[migrate-efi-to-grub] ERROR: %s\n' "$*" >&2
  exit 1
}

require_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "must be run as root"
  fi
}

detect_efi_mountpoint() {
  local candidate
  for candidate in /boot/efi /efi /boot; do
    if [[ -d "$candidate" ]] && mountpoint -q "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ensure_kernel_install_layout_grub() {
  local conf="/etc/kernel/install.conf"
  mkdir -p /etc/kernel
  if [[ -f "$conf" ]] && grep -q '^layout=' "$conf"; then
    sed -i 's/^layout=.*/layout=grub/' "$conf"
  elif [[ -f "$conf" ]]; then
    printf '\nlayout=grub\n' >> "$conf"
  else
    echo 'layout=grub' > "$conf"
  fi

  if [[ -f "$conf" ]] && grep -q '^initrd_generator=' "$conf"; then
    sed -i 's/^initrd_generator=.*/initrd_generator=dracut/' "$conf"
  else
    printf 'initrd_generator=dracut\n' >> "$conf"
  fi

  if [[ -f "$conf" ]] && grep -q '^uki_generator=' "$conf"; then
    sed -i 's/^uki_generator=.*/uki_generator=none/' "$conf"
  else
    printf 'uki_generator=none\n' >> "$conf"
  fi
}

ensure_kernel_package() {
  local kernel_type="${KERNEL_TYPE:-bin}"
  if [[ "$kernel_type" == "source" ]]; then
    log "Ensuring sys-kernel/gentoo-kernel (source) is installed"
    emerge --verbose sys-kernel/gentoo-kernel
  else
    log "Ensuring sys-kernel/gentoo-kernel-bin (binary) is installed"
    emerge --verbose sys-kernel/gentoo-kernel-bin
  fi
}

install_grub() {
  local efi_dir target
  efi_dir="$(detect_efi_mountpoint)" || die "EFI mountpoint not found (expected /boot/efi, /efi, or /boot)"

  case "$(uname -m)" in
    x86_64) target="x86_64-efi" ;;
    aarch64|arm64) target="arm64-efi" ;;
    *) die "unsupported architecture for GRUB EFI: $(uname -m)" ;;
  esac

  log "Installing GRUB to ${efi_dir}"
  emerge --verbose sys-boot/grub
  grub-install --target="$target" --efi-directory="$efi_dir" --bootloader-id="GentooGRUB" --recheck
  mkdir -p /boot/grub
  grub-mkconfig -o /boot/grub/grub.cfg
}
ensure_grub_efi_entry() {
  local efi_source disk part entry_id
  efi_source="$(findmnt -no SOURCE /boot/efi 2>/dev/null || true)"
  if [[ -z "$efi_source" ]]; then
    die "Could not determine EFI device from /boot/efi"
  fi

  if [[ "$efi_source" =~ ^(/dev/.+p)([0-9]+)$ ]]; then
    disk="${BASH_REMATCH[1]%p}"
    part="${BASH_REMATCH[2]}"
  elif [[ "$efi_source" =~ ^(/dev/.+)([0-9]+)$ ]]; then
    disk="${BASH_REMATCH[1]}"
    part="${BASH_REMATCH[2]}"
  else
    die "Unrecognized EFI device format: $efi_source"
  fi

  entry_id="$(efibootmgr -v | awk -F'[ *]' '/GentooGRUB/ && /\\\\EFI\\\\GentooGRUB\\\\grubx64\\.efi/ {print $1}' | sed 's/^Boot//' | head -n 1)"
  if [[ -z "$entry_id" ]]; then
    log "Creating UEFI entry for GRUB"
    efibootmgr --create --disk "$disk" --part "$part" --label "GentooGRUB" --loader "\\EFI\\GentooGRUB\\grubx64.efi"
    entry_id="$(efibootmgr -v | awk -F'[ *]' '/GentooGRUB/ && /\\\\EFI\\\\GentooGRUB\\\\grubx64\\.efi/ {print $1}' | sed 's/^Boot//' | head -n 1)"
  fi

  if [[ -n "$entry_id" ]]; then
    log "Setting BootOrder to prioritize GRUB entry Boot${entry_id}"
    efibootmgr --bootorder "${entry_id}"
    efibootmgr --bootnext "${entry_id}" || true
  else
    log "WARN: Could not determine GRUB entry ID; BootOrder unchanged."
  fi
}
remove_efistub_entries() {
  local bootnums
  bootnums="$(efibootmgr -v | awk -F'[ *]' '/\\vmlinuz\\.efi/ {print $1}' | sed 's/^Boot//')"
  if [[ -z "$bootnums" ]]; then
    return
  fi
  for num in $bootnums; do
    log "Removing EFI-stub entry Boot${num}"
    efibootmgr --delete-bootnum --bootnum "${num}" || true
  done
}

verify_latest_kernel_artifacts() {
  local latest kernel initrd
  latest="$(find /boot -maxdepth 1 -type f -name 'kernel-*' -printf '%f\n' | sort -V | tail -n 1 | sed 's/^kernel-//')"
  if [[ -z "$latest" ]]; then
    die "No kernel-* images found in /boot"
  fi
  kernel="/boot/kernel-${latest}"
  initrd="/boot/initramfs-${latest}.img"

  [[ -f "$kernel" ]] || die "Missing ${kernel}"
  [[ -f "$initrd" ]] || die "Missing ${initrd}"

  log "Latest kernel: ${latest}"
  log "Kernel OK: ${kernel}"
  log "Initrd OK: ${initrd}"
}

cleanup_efistub_hooks() {
  if [[ -f /etc/kernel/postinst.d/99-efi-update.sh ]]; then
    rm -f /etc/kernel/postinst.d/99-efi-update.sh
    log "Removed EFI copy hook (/etc/kernel/postinst.d/99-efi-update.sh)"
  fi
}

main() {
  require_root
  ensure_kernel_install_layout_grub
  ensure_kernel_package
  install_grub
  ensure_grub_efi_entry
  verify_latest_kernel_artifacts
  remove_efistub_entries
  cleanup_efistub_hooks
  log "Done. GRUB is installed and configured."
}

main "$@"
