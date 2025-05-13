# ![](https://assets.gentoo.org/tyrian/v1/site-logo.svg)

### why
* keep track of all changes made to my system and resources used along the way
* keep an online/offline copy of the repository on standby as reference
* installing a source based distribution like gentoo and reading docs all day sounded fun

### features
- [x] ~amd64
- [x] bluetooth
- [x] bootloader (systemd-boot)
- [x] intel microcode
- [x] kernel (gentoo-sources)
- [x] luks
- [x] lvm (thin)
- [x] networking
- [x] nvidia drivers (open-kernel, optimus)
- [x] pipewire
- [x] power management (tls)
- [ ] secure boot
- [x] ssh
- [x] systemd
- [x] tmpfs
- [ ] tpm
- [x] virtualization (qemu, wine)
- [x] zswap

### fdisk[^1] (gpt)[^2]
| device           | size       | type      | lvm | luks | fs    |
|------------------|------------|-----------|------|-----|-------|
| `/dev/nvme0n1p1` | 1g         | efi (1)   |      |     | fat32 |
| `/dev/nvme0n1p2` | 24g        | swap (19) |      | yes |       |
| `/dev/nvme0n1p3` |            | lvm (44)  | thin | yes | xfs   |

### esp[^3] [^4] and luks[^5] on swap[^6]
```
mkfs.vfat -F 32 /dev/nvme0n1p1
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup luksOpen /dev/nvme0n1p2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap
```

### lvm[^7] on luks[^5] in root partition
```
pvcreate /dev/nvme0n1p3
vgcreate vg0 /dev/nvme0n1p3
lvcreate -l 100%FREE --type thin-pool --thinpool thin vg0
lvchange -a y /dev/vg0/thin
cryptsetup luksFormat /dev/vg0/thin
cryptsetup luksOpen /dev/vg0/thin root
mkfs.xfs /dev/mapper/root
```

### mounting devices
```
mkdir -p /mnt/gentoo
mount /dev/mapper/root /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/nvme0n1p1 /mnt/gentoo/efi
```

> [!TIP]
> to list all active volume groups: `vgdisplay` \
> if volume groups are missing: `vgscan`        \
> to list all logical volumes: `lvdisplay`      \
> if logical volumes are missing: `lvscan`

### portage[^8]
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
> repository is specifically tailored towards hardware and preferences of mine \
> you should follow the official gentoo installation handbook and adjust accordingly
> ```
> links https://wiki.gentoo.org/wiki/Handbook:AMD64
> ```

> [!CAUTION]
> assuming repository system-wide configurations have been applied beforehand, freely follow the guide and docs highlighted for additional information
> ```
> git clone https://github.com/librazhd7/gentoo.git
> ```
> ```
> wget https://github.com/librazhd7/gentoo/archive/refs/heads/main.zip
> ```

### stage3
```
cd /mnt/gentoo
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
```

### configuring network
```
ifconfig -a
net-setup enp3s0/wlo1
ping -c 3 1.1.1.1
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

> [!TIP]
> for automatic ip, network mask, routes, dns and ntp servers: `dhcpcd enp3s0/wlo1` \
> for network card activation: `ifconfig -v wlo1 up`

### chroot
```
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
```
```
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

> [!NOTE]
> using `arch-chroot /mnt/gentoo` simplifies mounting the necessary filesystems for when using the installation media gentoo provides \
> for using the traditional mounting process and manually chrooting into the new environment

### installing base system
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

### installing firmware[^9] [^10] [^11], bootloader[^12] and kernel[^13]
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

### eclean[^14]
```
emerge --ask app-portage/gentoolkit
eclean-dist -d
eclean-pkg
```

> [!NOTE]
> by default, source files are located in /var/cache/distfiles, while binary packages are located in /var/cache/binpkgs \
> both locations can grow quite big if not periodically cleaned

### systemd[^15]
| services                           | sockets                 |
|------------------------------------|-------------------------|
| `acpid.service`                    | `pipewire-pulse.socket` |
| `bluetooth.service`                | `virtstoraged.socket`   |
| `cups.service`                     | |
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

### configuring systemd
```
systemd-machine-id-setup
systemd-firstboot --prompt
systemctl preset-all --preset-mode=enable-only
systemctl preset-all
```

> [!TIP]
> to enable unit to start automatically at boot: `systemctl enable .service/.socket` \
> to start unit immediately: `systemctl start .service/.socket`

### system groups[^16]
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

### creating user
```
emerge --ask app-admin/sudo
useradd -mG audio, kvm, libvirt, pipewire, plugdev, users, video, wheel <user>
passwd <user>
visudo
```

> [!NOTE]
> `/etc/sudoers` should always be edited with `visudo`      \
> allow members of group wheel sudo access by uncommenting
> ```
> %wheel ALL=(ALL:ALL) ALL
> ```

> [!TIP]
> to prevent possible threat actors from logging in as root,                   \
> deleting the password and/or disabling root login can help improve security. \
> to delete the root password and disable login: `passwd -dl root`

### finishing up
```
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
cryptsetup close /dev/mapper/swap
cryptsetup close /dev/mapper/root
```

> [!NOTE]
> exit the chrooted environment and unmount all mounted partitions \
> then restart the system by typing: `reboot`

### to do
- proper referencing to docs but also files in the repository, make an index to navigate the readme too
- script to automatically apply system-wide configurations
- more insight into the meaning of all the commands
- virtualization section for wine and qemu
- properly configured luks with best practices (etc/crypttab)
- gentoo =>> minimal packages by use flags
- gentoo-sources =>> ditch gentoo-kernel-bin (partially tested, needs fine-tuning)

### docs
- [__acpi__][url-acpi]
- [__backlight__][url-backlight] (arch)
- [__bash__][url-bash]
- [__bluetooth__][url-bluetooth]
- [__dispatch-conf__][url-dispatch-conf]
- [__dnsmasq__][url-dnsmasq]
- [__dracut__][url-dracut]
- [__dxvk__][url-dxvk] (github)
- [__eselect__][url-eselect]
- [__fonts__][url-fonts]
- [__gamescope__][url-gamescope] (arch)
- [__gentoolkit__][url-gentoolkit]
- [__guru__][url-guru]
- [__hybrid graphics__][url-hybrid-graphics]
- [__libinput__][url-libinput]
- [__libvirt__][url-libvirt]
- [__networkmanager__][url-networkmanager]
- [__nvidia-drivers__][url-nvidia-drivers]
- [__optimus__][url-optimus]
- [__pipewire__][url-pipewire]
- [__power management__][url-power-management]
- [__qemu__][url-qemu]
- [__secure boot__][url-secureboot]
- [__ssh__][url-ssh]
- [__steam__][url-steam]
- [__tmpfs__][url-portage-tmpdir-tmpfs]
- [__udev__][url-udev]
- [__unified kernel image__][url-unified-kernel-image]
- [__wine__][url-wine]
- [__xdg-desktop-portal__][url-xdg-desktop-portal]
- [__xfs__][url-xfs]
- [__zsh__][url-zsh]
- [__zswap__][url-zswap]
  
### media ![](https://www.gentoo.org/assets/img/badges/gentoo-badge3.svg)
labwc, sfwbar, swww
![](https://github.com/librazhd7/gentoo/blob/6d570189e717f56e126076e14c76d73150764ab0/media/grim.jpg)

![](https://github.com/librazhd7/gentoo/blob/98bddab1c09648e2d99e9558d66452588051024a/media/spectacle.jpg)

<!-- docs -->
[url-acpi]:                  <https://wiki.gentoo.org/wiki/ACPI>
[url-backlight]:             <https://wiki.archlinux.org/title/Backlight>
[url-bash]:                  <https://wiki.gentoo.org/wiki/Bash>
[url-bluetooth]:             <https://wiki.gentoo.org/wiki/Bluetooth>
[url-dispatch-conf]:         <https://wiki.gentoo.org/wiki/Dispatch-conf>
[url-dnsmasq]:               <https://wiki.gentoo.org/wiki/Dnsmasq>
[url-dracut]:                <https://wiki.gentoo.org/wiki/Dracut>
[url-dxvk]:                  <https://github.com/doitsujin/dxvk>
[url-eselect]:               <https://wiki.gentoo.org/wiki/Eselect>
[url-fonts]:                 <https://wiki.gentoo.org/wiki/Fonts>
[url-gamescope]:             <https://wiki.archlinux.org/title/Gamescope>
[url-gentoolkit]:            <https://wiki.gentoo.org/wiki/Gentoolkit>
[url-guru]:                  <https://wiki.gentoo.org/wiki/Project:GURU>
[url-hybrid-graphics]:       <https://wiki.gentoo.org/wiki/Hybrid_graphics>
[url-libinput]:              <https://wiki.gentoo.org/wiki/Libinput>
[url-libvirt]:               <https://wiki.gentoo.org/wiki/Libvirt>
[url-networkmanager]:        <https://wiki.gentoo.org/wiki/NetworkManager>
[url-nvidia-drivers]:        <https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers>
[url-optimus]:               <https://wiki.gentoo.org/wiki/NVIDIA/Optimus>
[url-pipewire]:              <https://wiki.gentoo.org/wiki/PipeWire>
[url-power-management]:      <https://wiki.gentoo.org/wiki/Power_management>
[url-portage-tmpdir-tmpfs]:  <https://wiki.gentoo.org/wiki/Portage_TMPDIR_on_tmpfs>
[url-qemu]:                  <https://wiki.gentoo.org/wiki/QEMU>
[url-secureboot]:            <https://wiki.gentoo.org/wiki/Secure_Boot>
[url-ssh]:                   <https://wiki.gentoo.org/wiki/SSH>
[url-steam]:                 <https://wiki.gentoo.org/wiki/Steam>
[url-tpm]:                   <https://wiki.gentoo.org/wiki/Trusted_Platform_Module>
[url-udev]:                  <https://wiki.gentoo.org/wiki/Udev>
[url-unified-kernel-image]:  <https://wiki.gentoo.org/wiki/Unified_kernel_image>
[url-wine]:                  <https://wiki.gentoo.org/wiki/Wine>
[url-xdg-desktop-portal]:    <https://wiki.gentoo.org/wiki/XDG/xdg-desktop-portal>
[url-xfs]:                   <https://wiki.gentoo.org/wiki/XFS>
[url-zsh]:                   <https://wiki.gentoo.org/wiki/Zsh>
[url-zswap]:                 <https://wiki.gentoo.org/wiki/Zswap>

### references
[^1]: <https://linux.die.net/man/8/fdisk>
[^2]: <https://en.wikipedia.org/wiki/GUID_Partition_Table>
[^3]: <https://wiki.gentoo.org/wiki/UEFI>
[^4]: <https://wiki.gentoo.org/wiki/EFI_System_Partition>
[^5]: <https://wiki.gentoo.org/wiki/Dm-crypt>
[^6]: <https://wiki.gentoo.org/wiki/Swap>
[^7]: <https://wiki.gentoo.org/wiki/LVM>
[^8]: <https://wiki.gentoo.org/wiki/Portage>
[^9]: <https://wiki.gentoo.org/wiki/Linux_firmware>
[^10]: <https://wiki.gentoo.org/wiki/Microcode>
[^11]: <https://wiki.gentoo.org/wiki/Intel>
[^12]: <https://wiki.gentoo.org/wiki/Systemd/systemd-boot>
[^13]: <https://wiki.gentoo.org/wiki/Kernel>
[^14]: <https://wiki.gentoo.org/wiki/Eclean>
[^15]: <https://wiki.gentoo.org/wiki/Systemd>
[^16]: <https://wiki.debian.org/SystemGroups>
