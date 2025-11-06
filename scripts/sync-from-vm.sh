#!/usr/bin/env bash
set -euo pipefail

# Sync user dotfiles from this VM back into the repo.
# - Mirrors selected ~/.config subtrees and ~/.dwm into dotfiles/home/*
# - Optionally captures system snapshot (/etc/portage, fstab, locale, world, kernel .config)
# - Refreshes docs (emerge-info, eselect-profile, uname)
#
# Usage:
#   bash scripts/sync-from-vm.sh [--include-system] [--dry-run|-n] [--help|-h]
#
# Options:
#   --include-system   Include system snapshot (may require sudo).
#   --dry-run, -n      Preview rsync changes only.
#   --help, -h         Show this help and exit.

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

print_usage() {
  cat <<'EOF'
Usage:
  bash scripts/sync-from-vm.sh [--include-system] [--dry-run|-n] [--help|-h]

Options:
  --include-system   Include system snapshot (may require sudo).
  --dry-run, -n      Preview rsync changes only.
  --help, -h         Show this help and exit.
EOF
}

dry_run=""
include_system="false"
for arg in "$@"; do
  case "$arg" in
    --dry-run|-n) dry_run="-n" ;;
    --include-system) include_system="true" ;;
    --help|-h) print_usage; exit 0 ;;
    *)
      echo "Unknown arg: $arg" >&2
      echo >&2
      print_usage >&2
      exit 2
      ;;
  esac
done

say() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

# rsync helper: src_dir -> dest_dir (creates dest, skips if src missing)
sync_dir() {
  local src="$1" dest="$2"
  if [ -d "$src" ]; then
    mkdir -p "$dest"
    say "rsync $(basename "$src") -> ${dest#$repo_root/}"
    rsync -a --delete $dry_run "$src/" "$dest/"
  else
    say "skip (missing): $src"
  fi
}

# 1) Dotfiles
say "Syncing dotfiles into repo..."
base_dst="$repo_root/dotfiles/home"

# Ensure base dirs
mkdir -p "$base_dst/.config" "$base_dst/.dwm"

sync_dir "$HOME/.config/hypr"          "$base_dst/.config/hypr"
sync_dir "$HOME/.config/dunst"         "$base_dst/.config/dunst"
sync_dir "$HOME/.config/rofi"          "$base_dst/.config/rofi"
sync_dir "$HOME/.config/picom"         "$base_dst/.config/picom"
sync_dir "$HOME/.config/sxhkd"         "$base_dst/.config/sxhkd"
sync_dir "$HOME/.config/suckless"      "$base_dst/.config/suckless"
sync_dir "$HOME/.dwm"                  "$base_dst/.dwm"

# Variety (native)
sync_dir "$HOME/.config/variety"       "$base_dst/.config/variety"
# Variety (Flatpak)
flatpak_variety="$HOME/.var/app/com.github.variety.Variety/config/variety"
[ -d "$flatpak_variety" ] && sync_dir "$flatpak_variety" "$base_dst/.config/variety"

# 2) Docs (always refresh, harmless)
say "Refreshing docs/ metadata..."
mkdir -p "$repo_root/docs"
{ emerge --info || true; } > "$repo_root/docs/emerge-info.txt"
{ eselect profile show || true; } > "$repo_root/docs/eselect-profile.txt"
{ uname -a || true; } > "$repo_root/docs/uname.txt"

# 3) System snapshot (optional)
if [ "$include_system" = "true" ]; then
  say "Including system snapshot..."
  sys="$repo_root/system"
  mkdir -p "$sys/etc" "$sys/var/lib/portage" "$sys/usr/src/linux"
  # /etc/portage
  if [ -d /etc/portage ]; then
    rsync -a --delete $dry_run /etc/portage/ "$sys/etc/portage/"
  fi
  # fstab, locale.gen
  [ -f /etc/fstab ] && install -m 644 /etc/fstab "$sys/etc/fstab" || true
  [ -f /etc/locale.gen ] && install -m 644 /etc/locale.gen "$sys/etc/locale.gen" || true
  # world set
  [ -f /var/lib/portage/world ] && install -m 644 /var/lib/portage/world "$sys/var/lib/portage/world" || true
  # kernel config
  [ -f /usr/src/linux/.config ] && install -m 644 /usr/src/linux/.config "$sys/usr/src/linux/.config" || true
fi

say "Done. Review changes with: git --no-pager status && git --no-pager diff"
