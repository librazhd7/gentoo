if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec dbus-run-session startplasma-wayland
fi
