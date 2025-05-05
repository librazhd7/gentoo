/usr/libexec/xdg-desktop-portal-wlr -r &

nm-applet --indicator &
sfwbar &
swww-daemon &

xhost +SI:localuser:$(id -un) &
xhost +SI:localuser:root &
