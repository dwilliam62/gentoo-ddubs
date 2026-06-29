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
  grub-mkconfig -o /boot/grub/grub.cfg
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
  cleanup_efistub_hooks
  log "Done. GRUB is installed and configured."
}

main "$@"
