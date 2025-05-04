# gentoo [![](https://img.shields.io/badge/version-0.0.1-green.svg)]()

### dracut.conf.d/
early_microcode="yes" \
omit_drivers+="nvidia nvidia-drm nvidia-modeset nvidia-uvm" \
uefi="yes" \
kernel_cmdline="zswap.enabled=1 zswap.compression=lz4 quiet splash"

### fstub
/dev/nvme0n1p1 1G EFI vfat umask=0077 0 2 \
/dev/nvme0n1p2 24G Linux Swap swap 0 0 \
/dev/nvmeon1p3 Linux root (x86-64) xfs defaults,noatime 0 1 \
tmpfs /tmp tmpfs rw,nosuid,nodev,size=8G,mode=1777 0 0 \

### qlist
- __dunst__
- __fastfetch__
- __firefox-bin__
- __gimp__
- __gstreamer__
- __hyprland__
- __intel-microcode__
- __libreoffice-bin__
- __minecraft-launcher__
- __networkmanager__
- __nvidia-driver__
- __ranger__
- __steam-launcher__
- __ranger__
- __vim__
- __waybar__
- __wine-staging__
