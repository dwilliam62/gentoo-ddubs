#!/usr/bin/env bash
set -euo pipefail

# Deploy dotfiles from this repo into the current user's home.
# - Backs up any replaced paths to ~/.local/share/dotfiles-backup/<timestamp>
# - Installs configs under ~/.config and dwm autostart under ~/.dwm
# - Installs suckless helper scripts to ~/.local/bin
# - Ensures ~/.local/bin is in PATH for future shells

SCRIPT_DIR="${SCRIPT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"
# shellcheck disable=SC1091
. "${SCRIPT_DIR}/lib/common.sh" || {
  printf '✖ Missing %s/lib/common.sh\n' "$SCRIPT_DIR" >&2
  exit 1
}

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
src_home="$repo_root/dotfiles/home"
backup_root="$HOME/.local/share/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

require_cmd rsync find

if [ ! -d "$src_home" ]; then
  die "dotfiles source not found: $src_home"
fi

mkdir -p "$backup_root" "$HOME/.config" "$HOME/.dwm" "$HOME/.local/bin" "$HOME/.config/profile.d"

backup_if_exists() {
  local target="$1" rel dest
  if [ -e "$target" ] || [ -L "$target" ]; then
    rel="${target#"$HOME"/}"
    dest="$backup_root/$rel"
    mkdir -p "$(dirname "$dest")"
    mv -f "$target" "$dest"
    log_info "Backed up ${target} -> ${dest}"
  fi
}

# Back up each top-level entry of <src>, then rsync the tree into <dest_dir>.
deploy_tree() {
  local src="$1" dest_dir="$2" item rel dest
  if [ ! -d "$src" ]; then
    log_warn "Skipping missing ${src}"
    return 0
  fi
  while IFS= read -r -d '' item; do
    rel="${item#"$src_home"/}"
    dest="$HOME/$rel"
    backup_if_exists "$dest"
  done < <(find "$src" -mindepth 1 -maxdepth 1 -print0)
  mkdir -p "$dest_dir"
  rsync -a "$src/" "$dest_dir/" || die "rsync failed for ${src}"
}

# Deploy ~/.config tree
deploy_tree "$src_home/.config" "$HOME/.config"

# Deploy ~/.dwm
deploy_tree "$src_home/.dwm" "$HOME/.dwm"

# Ensure scripts executable and copy to ~/.local/bin
if [ -d "$src_home/.config/suckless/scripts" ]; then
  chmod -R u+rx "$src_home/.config/suckless/scripts"
  rsync -a "$src_home/.config/suckless/scripts/" "$HOME/.local/bin/" ||
    die "rsync failed for the suckless helper scripts"
fi

# Ensure ~/.local/bin on PATH for future shells
cat > "$HOME/.config/profile.d/local-bin.sh" <<'EOF'
# ensure ~/.local/bin in PATH
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
EOF
for f in "$HOME/.profile" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$f" ] || touch "$f"
  grep -q "profile.d/local-bin.sh" "$f" ||
    printf '\n# Ensure ~/.local/bin is in PATH\n[ -f "%s/.config/profile.d/local-bin.sh" ] && . "%s/.config/profile.d/local-bin.sh"\n' \
      "$HOME" "$HOME" >> "$f"
done

# Permissions
chmod -R u+rwX "$HOME/.config" "$HOME/.dwm"
if [ -f "$HOME/.dwm/autostart.sh" ]; then
  chmod u+x "$HOME/.dwm/autostart.sh"
fi

# Summary
log_ok "Deployed dotfiles from ${repo_root}"
log_info "Backups (if any) stored at: ${backup_root}"
if have dwm; then log_info "dwm -> $(command -v dwm)"; fi
if have Hyprland; then log_info "Hyprland -> $(command -v Hyprland)"; fi
