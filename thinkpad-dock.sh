#!/bin/sh -e

# Save this file as /etc/sbin/thinkpad-dock.sh

# NB: you will need to modify the username and tweak the xrandr
# commands to suit your setup.

# wait for the dock state to change
sleep 0.5

username=fabian

#export IFS=$"\n"

if [[ "$ACTION" == "add" ]]; then
  DOCKED=1
  logger -t DOCKING "Detected condition: docked"
elif [[ "$ACTION" == "remove" ]]; then
  DOCKED=0
  logger -t DOCKING "Detected condition: un-docked"
else
  logger -t DOCKING "Detected condition: unknown"
  echo Please set env var \$ACTION to 'add' or 'remove'
  exit 1
fi

# invoke from XSetup with NO_KDM_REBOOT otherwise you'll end up in a KDM reboot loop
NO_KDM_REBOOT=0
for p in $*; do
  case "$p" in
  "NO_KDM_REBOOT") NO_KDM_REBOOT=1 ;;
  "SWITCH_TO_LOCAL") DOCKED=0 ;;
  esac
done

function switch_to_local {
  export DISPLAY=$1
  #export XAUTHORITY=$(find /var/run/kdm -name "A${DISPLAY}-*")
  #export XAUTHORITY=/var/run/lightdm/sflaniga/xauthority
  logger -t DOCKING "Switching off HDMI2/3 and switching on LVDS1"
  # su $username -c '
  #   /usr/bin/xrandr \
  #     --output DP1-1 --off \
  #     --output DP1-2 --off \
  #     --output eDP1  --mode 1920x1080 --primary \
  #   '
  xrandr --output DP1-2 --off
  xrandr --output DP1-1 --off
  xrandr --output eDP1 --auto --primary

  bspc monitor DP1-1 --remove
  bspc monitor DP1-2 --remove
  bspc monitor eDP1 --add-desktops I II III IV V VI VII VIII
  conky -c ~/.config/conky/conkyrc
  bspc wm -r
}

function switch_to_external {
  export DISPLAY=$1
  #export XAUTHORITY=/var/run/lightdm/sflaniga/xauthority
  #export XAUTHORITY=$(find /var/run/kdm -name "A${DISPLAY}-*")

  # The Display port on the docking station is on HDMI2 - let's use it and turn off local display
  logger -t DOCKING "Switching off LVDS1 and switching on HDMI2/3"

  # su $username -c '
  #   /usr/bin/xrandr \
  #     --output eDP1  --auto \
  #     --output DP1-1 --mode 2560x1440 --primary \
  #     --output DP1-2 --mode 1920x1080 --rotate left \
  #   '
  # alternative:
  # xrandr --output LVDS1 --off --output HDMI3 --primary --auto --pos 0x0
  # --output HDMI2 --auto --rotate left --pos 1680x-600

  # this will probably fail ("Configure crtc 2 failed"):
  #/usr/bin/xrandr --output LVDS1 --auto
  xrandr --output DP1-1 --mode 2560x1440 --primary
  xrandr --output DP1-2 --mode 1920x1080 --rotate left
  xrandr --output eDP1 --off
  
  bspc monitor eDP1 --remove
  bspc monitor DP1-1 --add-desktops I II III IV V VI VII VIII
  bspc monitor DP1-2 --add-desktops IX
  bspc wm -r
}

case "$DOCKED" in
  "0")
    #undocked event
    switch_to_local :0 ;;
  "1")
    #docked event
    switch_to_external :0 ;;
esac
