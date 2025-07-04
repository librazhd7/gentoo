#!/bin/zsh

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
  if ! [ -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -pm 0700 "$XDG_RUNTIME_DIR"
  fi
fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  #exec startx -- vt7
  #exec dbus-run-session startplasma-wayland
fi