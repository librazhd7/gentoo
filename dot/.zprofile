/usr/libexec/xdg-desktop-portal-wlr -r &

nm-applet --indicator &
sfwbar &
swww-daemon &

dbus-run-session labwc

xhost +SI:localuser:$(id -un) &
xhost +SI:localuser:root &
