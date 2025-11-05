# gentoo-ddubs

Snapshot of my Gentoo VM configuration for reproducibility and sharing. This repo contains Portage configs, world set, fstab, locale, and kernel config, plus metadata from the system.

Contents
- system/etc/portage/*
- system/var/lib/portage/world
- system/etc/fstab
- system/etc/locale.gen
- system/usr/src/linux/.config
- docs/emerge-info.txt, docs/eselect-profile.txt, docs/uname.txt

Notes
- Treat this as a reference snapshot; review diffs before applying to another machine.
- To apply Portage config to a target, copy desired files from system/etc/portage and update system/var/lib/portage/world as appropriate, then sync and emerge.
