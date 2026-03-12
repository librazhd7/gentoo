#!/bin/zsh

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/tmp/$(id -u)-runtime-dir
  if ! [ -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -pm 0700 "$XDG_RUNTIME_DIR"
  fi
fi

#if [ ${LOGNAME} ]; then
#  export XDG_CACHE_HOME="/run/user/${UID}/cache"
#fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  #exec startx -- vt7
  weston &
  Xwayland :1 -rootless -terminate &
  exec dbus-launch --sh-syntax --exit-with-session icewm-session
fi
