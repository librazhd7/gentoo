# ![](https://assets.gentoo.org/tyrian/v1/site-logo.svg)

### why
* keep track of all changes made to my system and resources used along the way
* keep an offline copy of the repository on standby as reference
* installing a source based distribution like gentoo and reading docs all day has seriously sharpened my way around linux

### features
- [x] ~amd64
- [x] bluetooth
- [x] bootloader (systemd-boot)
- [x] intel microcode (iucode_tool)
- [ ] kernel (gentoo-sources)
- [x] luks
- [x] lvm (thin)
- [x] networking
- [x] nvidia drivers (open-kernel, optimus)
- [x] pipewire
- [x] power management (tls)
- [ ] secure boot
- [x] ssh
- [x] systemd (dbus, udev)
- [x] virtualization (qemu, wine)
- [x] wayland
- [x] zswap

### fdisk (gpt)
| device           | size       | type      | lvm | luks | fs    |
|------------------|------------|-----------|------|-----|-------|
| `/dev/nvme0n1p1` | 1g         | efi (1)   |      |     | fat32 |
| `/dev/nvme0n1p2` | 24g        | swap (19) |      |     |       |
| `/dev/nvme0n1p3` |            | lvm (44)  | thin | yes | xfs   |

esp and swap:
```
mkfs.vfat -F 32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
```
lvm and luks on root partition:
```
pvcreate /dev/nvme0n1p3
vgcreate vg0 /dev/nvme0n1p3
lvcreate -l 100%FREE --type thin-pool --thinpool thin_pool vg0
cryptsetup luksFormat /dev/vg0/thin_pool
mkfs.xfs /dev/vg0/thin_pool
lvchange -a y /dev/vg0/thin_pool
```
mounting devices:
```
mkdir -p /mnt/gentoo
mount /dev/vg0/thin_pool /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/nvme0n1p1 /mnt/gentoo/efi
```
configuring network:
```
ifconfig -a
net-setup enp3s0/wlo1
ping -c 3 1.1.1.1
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```
stage3:
```
cd /mnt/gentoo
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
arch-chroot /mnt/gentoo
```

> [!TIP]
> to list all active volume groups: `vgdisplay` \
> if volume groups are missing: `vgscan`        \
> to list all logical volumes: `lvdisplay`      \
> if logical volumes are missing: `lvscan`

### portage
| command                                                                      | functionality                                                                                           |
|------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| `dispatch-conf`                                                              | manage configuration changes after an emerge completes                                                  |
| `getuto`                                                                     | get portage to set up the necessary keyring for verification when using binaries                        |
| `emerge --sync`                                                              | sync all repositories that are set to auto-sync including the gentoo ebuild repository                  |
| `emerge-webrsync`                                                            | sync the gentoo ebuild repository using the mirrors by obtaining a snapshot that is (at most) a day old |
| `emerge --ask --verbose --update --deep --newuse --with-bdeps=y @world`      | |
| `emerge --ask --verbose --update --deep --changed-use --with-bdeps=y @world` | |
| `emerge --ask --depclean`                                                    | |
| `emerge --ask @module-rebuild`                                               | after installing a new kernel                                                                           |
| `emerge --ask @preserved-rebuild`                                            | for using new libraries                                                                                 |

> [!WARNING]  
> guide is specifically tailored towards the hardware and preferences of mine \
> you should follow the official gentoo installation handbook instead:
> 
> ```
> links https://wiki.gentoo.org/wiki/Handbook:AMD64
> ```

> [!CAUTION]
> procedural methods as stated below should only be executed \
> assuming system-wide configurations have been applied beforehand:
> ```
> git clone https://github.com/librazhd7/gentoo.git
> ```
> ```
> wget https://github.com/librazhd7/gentoo/archive/refs/heads/main.zip
> ```

preparing gentoo:
```
eselect profile list
eselect locale list
emerge --sync
getuto
emerge --ask --verbose --update --deep --changed-use --with-bdeps=y @world
emerge --ask --depclean
env-update && source /etc/profile
```

> [!TIP]
> to generate all locales specified in the /etc/locale.gen file: `locale-gen` \
> to select the timezone for the system: `timedatectl set-timezone Europe/Stockholm`

configuring gentoo:
```
emerge --ask sys-kernel/linux-firmware sys-firmware/intel-microcode sys-firmware/sof-firmware
emerge --ask app-crypt/sbsigntools sys-apps/pciutils sys-apps/systemd sys-kernel/gentoo-sources sys-kernel/installkernel
emerge --ask sys-block/io-scheduler-udev-rules sys-fs/cryptsetup sys-fs/dosfstools sys-fs/e2fsprogs sys-fs/lvm2 sys-fs/ntfs3g sys-fs/xfsprogs
eselect kernel list
cd /usr/src/linux
make localmodconfig
make nconfig
make && make modules_install
make install
bootctl install
```

polishing gentoo:
```
emerge --ask app-portage/gentoolkit sys-apps/mlocate
emerge --ask x11-apps/mesa-progs x11-drivers/nvidia-drivers x11-misc/prime-run
emerge --ask app-shells/bash-completion app-shells/zsh app-shells/zsh-completions app-shells/gentoo-zsh-completions
emerge --ask app-emulation/libvirt app-emulation/qemu app-emulation/virt-manager app-emulation/wine-staging app-emulation/winetricks
```

maintaining gentoo:
```
eclean-dist -d
eclean-pkg
```

### systemd
| services                           | sockets                 |
|------------------------------------|-------------------------|
| `acpid.service`                    | `pipewire-pulse.socket` |
| `bluetooth.service`                | `virtstoraged.socket`   |
| `dnsmasq.service`                  | |
| ~~`getty@tty1.service`~~           | |
| `libvirtd.service`                 | |
| `lvm2-monitor.service`             | |
| `NetworkManager.service`           | |
| `sshd.service`                     | |
| `systemd-boot-update.service`      | |
| ~~`systemd-modules-load.service`~~ | |
| `systemd-networkd.service`         | |
| `systemd-timesyncd.service`        | |
| `thermald.service`                 | |
| `tlp.service`                      | |
| `virtnetworkd.service`             | |
| `virtqemud.service`                | |
| `virtlogd.service`                 | |
| `wireplumber.service`              | |

preparing systemd:
```
systemd-machine-id-setup
systemd-firstboot --prompt
systemctl preset-all --preset-mode=enable-only
systemctl preset-all
```

> [!TIP]
> : `systemctl enable .service/.socket` \
> : `systemctl start .service/.socket`

### useradd/usermod
| group      | permissions                                                                                   |
|------------|-----------------------------------------------------------------------------------------------|
| `audio`    | direct access to sound hardware, for all sessions                                             |
| `kvm`      | access to virtual machines using kvm                                                          |
| `libvirt`  | users in this group can talk with libvirt service via dbus                                    |
| `pipewire` |                                                                                               |
| `plugdev`  | allows members to mount and umount removable devices through pmount                           |
| `users`    | the primary group for users when user private groups are not used (generally not recommended) |
| `video`    | access to video capture devices, 2d/3d hardware acceleration and framebuffer                  |
| `wheel`    | administration group, commonly used to give privileges to perform administrative actions      |

creating user:
```
emerge --ask app-admin/sudo
useradd -mG audio, kvm, libvirt, pipewire, plugdev, users, video, wheel __user__
passwd __user__
visudo
```

> [!TIP]
> to prevent possible threat actors from logging in as root,                   \
> deleting the password and/or disabling root login can help improve security. \
> to delete the root password and disable login: `passwd -dl root`

### to do
- alot
- gentoo =>> minimal packages by use flags
- gentoo-sources =>> ditch gentoo-kernel-bin
- wayland =>> icewm-like compositor, see icewl?

### docs
- [__acpi__][url-acpi]
- [__backlight__][url-backlight] (arch)
- [__bash__][url-bash]
- [__bluetooth__][url-bluetooth]
- [__dispatch-conf__][url-dispatch-conf]
- [__dxvk__][url-dxvk] (github)
- [__eselect__][url-eselect]
- [__fonts__][url-fonts]
- [__gamescope__][url-gamescope] (arch)
- [__gentoolkit__][url-gentoolkit]
- [__guru__][url-guru]
- [__hybrid graphics__][url-hybrid-graphics]
- [__kernel__][url-kernel]
- [__libinput__][url-libinput]
- [__libvirt__][url-libvirt]
- [__lvm__][url-lvm]
- [__microcode__][url-microcode]
- [__networkmanager__][url-networkmanager]
- [__nvidia-drivers__][url-nvidia-drivers]
- [__optimus__][url-optimus]
- [__pipewire__][url-pipewire]
- [__power management__][url-power-management]
- [__qemu__][url-qemu]
- [__rootfs encryption__][url-rootfs-encryption]
- [__secure boot__][url-secureboot]
- [__ssh__][url-ssh]
- [__steam__][url-steam]
- [__systemd__][url-systemd]
- [__systemd-boot__][url-systemd-boot]
- [__systemgroups__][url-systemgroups] (debian)
- [__swap__][url-swap]
- [__tmpfs__][url-portage-tmpdir-tmpfs]
- [__udev__][url-udev]
- [__unified kernel image__][url-unified-kernel-image]
- [__wine__][url-wine]
- [__xdg-desktop-portal__][url-xdg-desktop-portal]
- [__xfs__][url-xfs]
- [__zsh__][url-zsh]
- [__zswap__][url-zswap]
  
### media ![](https://www.gentoo.org/assets/img/badges/gentoo-badge3.svg)
![](https://github.com/librazhd7/gentoo/blob/6d570189e717f56e126076e14c76d73150764ab0/media/grim.jpg)

<!-- docs -->
[url-acpi]:                  <https://wiki.gentoo.org/wiki/ACPI>
[url-backlight]:             <https://wiki.archlinux.org/title/Backlight>
[url-bash]:                  <https://wiki.gentoo.org/wiki/Bash>
[url-bluetooth]:             <https://wiki.gentoo.org/wiki/Bluetooth>
[url-dispatch-conf]:         <https://wiki.gentoo.org/wiki/Dispatch-conf>
[url-dxvk]:                  <https://github.com/doitsujin/dxvk>
[url-eselect]:               <https://wiki.gentoo.org/wiki/Eselect>
[url-fonts]:                 <https://wiki.gentoo.org/wiki/Fonts>
[url-gamescope]:             <https://wiki.archlinux.org/title/Gamescope>
[url-gentoolkit]:            <https://wiki.gentoo.org/wiki/Gentoolkit>
[url-guru]:                  <https://wiki.gentoo.org/wiki/Project:GURU>
[url-hybrid-graphics]:       <https://wiki.gentoo.org/wiki/Hybrid_graphics>
[url-kernel]:                <https://wiki.gentoo.org/wiki/Kernel>
[url-libinput]:              <https://wiki.gentoo.org/wiki/Libinput>
[url-libvirt]:               <https://wiki.gentoo.org/wiki/Libvirt>
[url-lvm]:                   <https://wiki.gentoo.org/wiki/LVM>
[url-microcode]:             <https://wiki.gentoo.org/wiki/Microcode>
[url-networkmanager]:        <https://wiki.gentoo.org/wiki/NetworkManager>
[url-nvidia-drivers]:        <https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers>
[url-optimus]:               <https://wiki.gentoo.org/wiki/NVIDIA/Optimus>
[url-pipewire]:              <https://wiki.gentoo.org/wiki/PipeWire>
[url-power-management]:      <https://wiki.gentoo.org/wiki/Power_management>
[url-portage-tmpdir-tmpfs]:  <https://wiki.gentoo.org/wiki/Portage_TMPDIR_on_tmpfs>
[url-qemu]:                  <https://wiki.gentoo.org/wiki/QEMU>
[url-rootfs-encryption]:     <https://wiki.gentoo.org/wiki/Rootfs_encryption>
[url-secureboot]:            <https://wiki.gentoo.org/wiki/Secure_Boot>
[url-ssh]:                   <https://wiki.gentoo.org/wiki/SSH>
[url-steam]:                 <https://wiki.gentoo.org/wiki/Steam>
[url-systemd]:               <https://wiki.gentoo.org/wiki/Systemd>
[url-systemd-boot]:          <https://wiki.gentoo.org/wiki/Systemd/systemd-boot>
[url-systemgroups]:          <https://wiki.debian.org/SystemGroups>
[url-swap]:                  <https://wiki.gentoo.org/wiki/Swap>
[url-udev]:                  <https://wiki.gentoo.org/wiki/Udev>
[url-unified-kernel-image]:  <https://wiki.gentoo.org/wiki/Unified_kernel_image>
[url-wine]:                  <https://wiki.gentoo.org/wiki/Wine>
[url-xdg-desktop-portal]:    <https://wiki.gentoo.org/wiki/XDG/xdg-desktop-portal>
[url-xfs]:                   <https://wiki.gentoo.org/wiki/XFS>
[url-zsh]:                   <https://wiki.gentoo.org/wiki/Zsh>
[url-zswap]:                 <https://wiki.gentoo.org/wiki/Zswap>
