#!/usr/bin/env bash 
git clone https://github.com/hyprwm/hyprland-qtutils.git
cd hyprland-qtutils
cmake --no-warn-unused-cli -Bbuild -H. -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --target all
sudo cmake --install build

