# gentoo

dracut.conf.d/ =>> 

early_microcode="yes"

omit_drivers+=" nvidia nvidia-drm nvidia-modeset nvidia-uvm "

uefi="yes"
kernel_cmdline="zswap.enabled=1 zswap.compression=lz4 quiet splash"

/dev/nvme0n1p1 1G EFI vfat umask=0077 0 2
/dev/nvme0n1p2 24G Linux Swap swap 0 0
/dev/nvmeon1p3 Linux root (x86-64) xfs defaults,noatime 0 1
tmpfs /tmp tmpfs rw,nosuid,nodev,size=8G,mode=1777 0 0

fastfetch hyprland gimp firefox-bin gstreamer ranger waybar dunst networkmanager nvidia-driver intel-microcode wine-staging libreoffice steam-launcher vim
