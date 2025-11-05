#!/usr/bin/env bash

slstatus &

#
# Laptop 
~/.screenlayout/laptop.sh 

# vm 
~/.screenlayout/vm.sh 


# polkit
/run/wrappers/bin/polkit-agent-helper-1
#/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &

# background
#feh --bg-scale ~/.config/suckless/wallpaper/wallhaven-d61z1m_3440x1440.png &

# sxhkd
# (re)load sxhkd for keybinds
if hash sxhkd >/dev/null 2>&1; then
	pkill sxhkd
	sleep 0.5
	sxhkd -c "$HOME/.config/suckless/sxhkd/sxhkdrc" &
fi

dunst -config ~/.config/suckless/dunst/dunstrc &
picom --config ~/.config/suckless/picom/picom.conf --animations -b &

# Startup 
pkill volumeicon
pkill variety 
pkill flameshot
sleep 0.5 
volumeicon & 
variety & 
flameshot & 

