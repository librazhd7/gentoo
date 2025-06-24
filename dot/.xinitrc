#!/bin/sh

userresources="$HOME/.Xresources"
usermodmap="$HOME/.Xmodmap"
sysresources="$xinitdir/Xresources"
sysmodmap="$xinitdir/Xmodmap"

# merge in defaults and keymaps
if [ -f "$sysresources" ]; then
  if [ -x /usr/bin/cpp ] ; then
    "$xrdb" -merge "$sysresources"
  else
    "$xrdb" -nocpp -merge "$sysresources"
  fi
fi

if [ -f "$sysmodmap" ]; then
  "$xmodmap" "$sysmodmap"
fi

if [ -f "$userresources" ]; then
  if [ -x /usr/bin/cpp ] ; then
    "$xrdb" -merge "$userresources"
  else
    "$xrdb" -nocpp -merge "$userresources"
  fi
fi

if [ -f "$usermodmap" ]; then
  "$xmodmap" "$usermodmap"
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