#!/usr/bin/env bash 

echo "dev-qt/qt5compat qml gui" | sudo tee -a /etc/portage/package.use/quickshell

sudo emerge --ask dev-qt/qt5compat
