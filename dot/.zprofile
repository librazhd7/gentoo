#!/bin/zsh

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR=/run/user/$(id -u)
  if ! [ -d "$XDG_RUNTIME_DIR" ]; then
    mkdir -pm 0700 "$XDG_RUNTIME_DIR"
  fi
fi

#if [ ${LOGNAME} ]; then
#  export XDG_CACHE_HOME="/run/user/$(id -u)/cache"
#fi

if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
  exec startx
fi
