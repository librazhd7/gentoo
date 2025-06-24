#!/bin/zsh

if test [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
  if ! test [ -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -pm 0700 "$XDG_RUNTIME_DIR"
  fi
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  #exec startx &>/dev/null
  #exec dbus-run-session startplasma-wayland
fi