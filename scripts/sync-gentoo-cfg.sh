#!/usr/bin/env bash
echo "Syncing /etc/portage"
sudo rsync -av --delete /etc/portage ~/gentoo-ddubs/system/etc/portage/ 
echo "Syncing /var/lib/portage"
sudo rsync -av  /var/lib/portage/  ~/gentoo-ddubs/system/var/lib/portage/ 

