#!/bin/sh

# merge in defaults and keymaps
if [ -f "$xinitdir/Xresources" ]; then
  if [ -x /usr/bin/cpp ] ; then
    "$xrdb" -merge "$xinitdir/Xresources"
  else
    "$xrdb" -nocpp -merge "$xinitdir/Xresources"
  fi
fi

if [ -f "$xinitdir/Xmodmap" ]; then
  "$xmodmap" "$xinitdir/Xmodmap"
fi

if [ -f "$HOME/.Xresources" ]; then
  if [ -x /usr/bin/cpp ] ; then
    "$xrdb" -merge "$HOME/.Xresources"
  else
    "$xrdb" -nocpp -merge "$HOME/.Xresources"
  fi
fi

if [ -f "$HOME/.Xmodmap" ]; then
  "$xmodmap" "$HOME/.Xmodmap"
fi

if [ -d "$xinitdir"/xinitrc.d ] ; then
  for f in "$xinitdir/xinitrc.d"/?* ; do
    [ -x "$f" ] && . "$f"
    done
    unset f
fi

#xrandr --setprovideroutputsource modesetting NVIDIA-0
#xrandr --auto
#exec dbus-launch --sh-syntax --exit-with-session wmaker
