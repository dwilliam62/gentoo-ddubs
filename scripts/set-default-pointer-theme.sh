#!/usr/bin/env bash
sudo mkdir -p /usr/share/icons/default
sudo tee /usr/share/icons/default/index.theme <<'EOF'
[Icon Theme]
Inherits=Adwaita
EOF
