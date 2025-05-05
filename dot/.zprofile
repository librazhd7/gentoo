if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec dbus-run-session labwc
fi

exec /usr/libexec/xdg-desktop-portal-wlr -r &
exec nm-applet --indicator &
exec sfwbar &
exec swww-daemon &
exec xhost +SI:localuser:$(id -un) &
exec xhost +SI:localuser:root &
