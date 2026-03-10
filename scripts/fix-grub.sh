#!/usr/bin/env bash
# Force grub update

sudo grub-mkconfig -o /boot/grub/grub.cfg

sudo grep -n "menuentry" -n /boot/grub/grub.cfg
