#!/bin/zsh
##
## enabling portage completions, corrections and gentoo prompt for zsh
##
autoload -U compinit promptinit
compinit
setopt correctall
promptinit; prompt gentoo

##
## enabling cache for the completions of zsh
##
zstyle ':completion::complete:*' use-cache 1

##
## Use the XKB_DEFAULT_LAYOUT variable to set the keyboard layout. For example
## to start with Swedish keyboard layout set it to 'se'. If you are unsure what
## your country code is, refer to the layout section of:
## /usr/share/X11/xkb/rules/evdev.lst
##
## Multiple keyboard layouts can be set by comma-separating the country codes.
## If a variant layout is needed, the syntax is layout(variant)
## If multiple layouts are used, specify the toggle-keybind using
## XKB_DEFAULT_OPTIONS as show below.
##
## For further details, see xkeyboard-config(7)
##
XKB_DEFAULT_LAYOUT=se

##
## 
##
_JAVA_AWT_WM_NONREPARENTING=1

##
## 
##
XDG_CURRENT_DESKTOP=labwc:wlroots

##
## 
##
CLUTTER_BACKEND=wayland
SDL_AUDIODRIVER=pipewire
SDL_VIDEODRIVER=wayland,x11
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt6ct
