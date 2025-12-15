#!/bin/env sh

print_section() {
  printf "\n===== %s =====\n" "$1" | lolcat
}

print_section "SYNC START"
sudo emaint sync -a

print_section "EIX UPDATE"
sudo eix-update

print_section "EMERGE WORLD UPDATE"
LOGFILE="/tmp/emerge.log"
sudo emerge --verbose --update --deep --newuse --getbinpkg @world 2>&1 | tee "$LOGFILE"

UPDATED=$(grep -E "ebuild.+(U|R).+to" "$LOGFILE" | sed -E 's/^\[ebuild[^\]]+\]\s+([^ ]+).*/\1/')

print_section "NOTIFY RESULT"
if [ -n "$UPDATED" ]; then
  notify-send "Emerge Update" "Updated packages:\n$UPDATED"
  printf "Updated packages:\n$UPDATED\n"
else
  notify-send "Emerge Update" "No packages updated."
  printf "No packages updated.\n"
fi

print_section "MISE UPGRADE"
/home/mio-dokuhaki/.local/bin/mise upgrade --bump

print_section "DONE"
