#!/usr/bin/env bash

sudo tar -cvpjf "gentoo_backup_$(date +%F).tar.bz2" \
  /etc/portage/ \
  /etc/locale.gen \
  /etc/hosts \
  /etc/fstab \
  "/home/$(whoami)/.config/"
