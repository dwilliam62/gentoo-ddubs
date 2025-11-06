#!/usr/bin/env bash
set -euo pipefail

# Deploy dotfiles from this repo into the current user's home.
# - Backs up any replaced paths to ~/.local/share/dotfiles-backup/<timestamp>
# - Installs configs under ~/.config and dwm autostart under ~/.dwm
# - Installs suckless helper scripts to ~/.local/bin
# - Ensures ~/.local/bin is in PATH for future shells

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
src_home="$repo_root/dotfiles/home"
backup_root="$HOME/.local/share/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

mkdir -p "$backup_root" "$HOME/.config" "$HOME/.dwm" "$HOME/.local/bin" "$HOME/.config/profile.d"

backup_if_exists() {
  local target="$1"
  if [ -e "$target" ] || [ -L "$target" ]; then
    local rel
    rel="${target#$HOME/}"
    mkdir -p "$backup_root/$(dirname "$rel")"
    mv -f "$target" "$backup_root/$rel"
    echo "Backed up $target -> $backup_root/$rel"
  fi
}

# Deploy ~/.config tree
if [ -d "$src_home/.config" ]; then
  while IFS= read -r -d '' item; do
    rel="${item#$src_home/}"
    dest="$HOME/${rel}"
    backup_if_exists "$dest"
  done < <(find "$src_home/.config" -mindepth 1 -maxdepth 1 -print0)
  rsync -a "$src_home/.config/" "$HOME/.config/"
fi

# Deploy ~/.dwm
if [ -d "$src_home/.dwm" ]; then
  while IFS= read -r -d '' item; do
    rel="${item#$src_home/}"
    dest="$HOME/${rel}"
    backup_if_exists "$dest"
  done < <(find "$src_home/.dwm" -mindepth 1 -maxdepth 1 -print0)
  rsync -a "$src_home/.dwm/" "$HOME/.dwm/"
fi

# Ensure scripts executable and copy to ~/.local/bin
if [ -d "$src_home/.config/suckless/scripts" ]; then
  chmod -R u+rx "$src_home/.config/suckless/scripts"
  rsync -a "$src_home/.config/suckless/scripts/" "$HOME/.local/bin/"
fi

# Ensure ~/.local/bin on PATH for future shells
cat > "$HOME/.config/profile.d/local-bin.sh" <<'EOF'
# ensure ~/.local/bin in PATH
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH";; esac
EOF
for f in "$HOME/.profile" "$HOME/.zprofile" "$HOME/.bash_profile" "$HOME/.zshrc" "$HOME/.bashrc"; do
  [ -f "$f" ] || touch "$f"
  grep -q "profile.d/local-bin.sh" "$f" || printf "\n# Ensure ~/.local/bin is in PATH\n[ -f \"$HOME/.config/profile.d/local-bin.sh\" ] && . \"$HOME/.config/profile.d/local-bin.sh\"\n" >> "$f"
done

# Permissions
chmod -R u+rwX "$HOME/.config" "$HOME/.dwm"
[ -f "$HOME/.dwm/autostart.sh" ] && chmod u+x "$HOME/.dwm/autostart.sh"

# Summary
printf "\nDeployed dotfiles from %s\n" "$repo_root"
printf "Backups (if any) stored at: %s\n" "$backup_root"
command -v dwm >/dev/null 2>&1 && echo "dwm -> $(command -v dwm)" || true
command -v Hyprland >/dev/null 2>&1 && echo "Hyprland -> $(command -v Hyprland)" || true
