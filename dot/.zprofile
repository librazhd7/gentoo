#!/bin/zsh

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  #exec startx &>/dev/null
  exec dbus-run-session startplasma-wayland
fi
