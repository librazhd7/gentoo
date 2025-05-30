# ![](https://assets.gentoo.org/tyrian/v1/site-logo.svg)

### why
* keep track of all changes made to my system and resources used along the way
* keep an online/offline copy of the repository on standby as reference
* installing a source based distribution like gentoo and reading docs all day sounded fun

### features
- [x] ~amd64
- [x] bluetooth
- [x] bootloader
- [x] intel microcode
- [x] kernel
- [x] luks
- [x] lvm
- [x] networking
- [x] nvidia drivers
- [x] pipewire
- [x] portage optimizations
- [x] power management
- [x] printing
- [x] samba
- [ ] secure boot
- [x] ssh
- [x] systemd
- [x] tmpfs
- [ ] tpm
- [x] virtualization
- [x] zswap

---

### fdisk[^1] (gpt)[^2]
| device           | size       | type      | lvm | luks | fs    |
|------------------|------------|-----------|------|-----|-------|
| `/dev/nvme0n1p1` | 1g         | efi (1)   |      |     | fat32 |
| `/dev/nvme0n1p2` | 24g        | swap (19) |      | yes |       |
| `/dev/nvme0n1p3` |            | lvm (44)  | thin | yes | xfs   |

### esp[^3] [^4] and luks[^5] [^6] on swap[^7]
```
mkfs.vfat -F 32 /dev/nvme0n1p1
cryptsetup luksFormat /dev/nvme0n1p2
cryptsetup open /dev/nvme0n1p2 swap
mkswap /dev/mapper/swap
swapon /dev/mapper/swap
```

### lvm[^8] on root
```
pvcreate /dev/nvme0n1p3
vgcreate tux /dev/nvme0n1p3
lvcreate -l 100%FREE --type thin-pool --thinpool thin tux
lvchange -ay /dev/tux/thin
cryptsetup luksFormat /dev/tux/thin
cryptsetup open /dev/tux/thin root
mkfs.xfs /dev/mapper/root
```

> [!TIP]
> to list all active volume groups: `vgdisplay` \
> if volume groups are missing: `vgscan`        \
> to list all logical volumes: `lvdisplay`      \
> if logical volumes are missing: `lvscan`

---

### portage[^9]
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

> [!CAUTION]  
> repository is specifically tailored towards hardware and preferences of mine \
> you should follow the official gentoo installation handbook and adjust accordingly
> ```
> links https://wiki.gentoo.org/wiki/Handbook:AMD64
> ```

> [!IMPORTANT]
> assuming repository system-wide configurations have been applied beforehand, freely follow the guide and docs highlighted for additional information
> ```
> git clone https://github.com/librazhd7/gentoo.git
> ```
> ```
> wget https://github.com/librazhd7/gentoo/archive/refs/heads/main.zip
> ```

---

### mounting devices
```
mkdir -p /mnt/gentoo
mount /dev/mapper/root /mnt/gentoo
mkdir -p /mnt/gentoo/efi
mount /dev/nvme0n1p1 /mnt/gentoo/efi
```

### configuring network
```
ifconfig -a
net-setup enp3s0/wlo1
ping -c 3 1.1.1.1
```

> [!TIP]
> for automatic ip, network mask, routes, dns and ntp servers: `dhcpcd enp3s0/wlo1` \
> for network card activation: `ifconfig -v wlo1 up`

### stage3
```
cd /mnt/gentoo
wget https://ftp.lysator.liu.se/gentoo/releases/amd64/autobuilds/current-stage3-amd64-desktop-systemd/current-stage3-amd64-desktop-systemd-xxxxxxxxxxxxxxxx.tar.xz
tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner -C /mnt/gentoo
cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
```

---

### mounting filesystems
```
mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run
mount --make-slave /mnt/gentoo/run
```

### chrooting[^10] into environment
```
chroot /mnt/gentoo /bin/bash
source /etc/profile
export PS1="(chroot) ${PS1}"
```

> [!NOTE]
> using `arch-chroot` simplifies the mounting process of necessary filesystems when using the official gentoo installation media:
> ```
> dd if=install-amd64-minimal-xxxxxxxxxxxxxxxx.iso of=/dev/sda bs=4096 status=progress && sync
> ```

> [!TIP]
> to specify input file: `if=`                                    \
> to specify output file: `of=` (which in this case, is a device) \
> to speed up transfers in most cases: `bs=4096`                  \
> to display transfers stats: `status=progress`

---

### installing base system
```
emerge --sync
getuto
eselect profile list
eselect locale list
emerge --ask --verbose --update --deep --changed-use --with-bdeps=y @world
emerge --ask --depclean
env-update && source /etc/profile
```

> [!TIP]
> for detecting cpu: `resolve-march-native`                                   \
> for detecting cpu features: `cpuid2cpuflags`                                \
> to generate all locales specified in the /etc/locale.gen file: `locale-gen` \
> to select the hostname for the system: `echo tux > /etc/hostname`           \
> to select the timezone for the system: `ln -sf ../usr/share/zoneinfo/Europe/Stockholm /etc/localtime`

### installing firmware[^11] [^12] [^13], bootloader[^14] and kernel[^15]
```
emerge --ask sys-kernel/linux-firmware sys-kernel/linux-headers sys-firmware/intel-microcode sys-firmware/sof-firmware
emerge --ask app-crypt/sbsigntools sys-apps/fwupd sys-apps/pciutils sys-apps/systemd sys-kernel/dkms sys-kernel/gentoo-sources sys-kernel/installkernel
emerge --ask sys-block/io-scheduler-udev-rules sys-fs/cryptsetup sys-fs/dosfstools sys-fs/e2fsprogs sys-fs/lvm2 sys-fs/ntfs3g sys-fs/xfsprogs
eselect kernel list
cd /usr/src/linux
make localmodconfig
make nconfig
make && make modules_install
make install
bootctl install
```

---

### systemd[^16]
| services                           | sockets                 |
|------------------------------------|-------------------------|
| `acpid.service`                    | `pipewire-pulse.socket` |
| `bluetooth.service`                | ~~`pulseaudio.socket`~~ |
| `cups.service`                     | `virtstoraged.socket`   |
| `dkms.service`                     | |
| `dnsmasq.service`                  | |
| `getty@tty1.service`               | |
| `libvirtd.service`                 | |
| `lvm2-monitor.service`             | |
| `NetworkManager.service`           | |
| `nmbd.service`                     | |
| ~~`pulseaudio.service`~~           | |
| `smbd.service`                     | |
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
> to start unit immediately: `systemctl start .service/.socket`                      \
> to select the hostname for the system: `hostnamectl hostname tux`                  \
> to select the timezone for the system: `timedatectl set-timezone Europe/Stockholm`

### journalctl [^17]
| command                      | functionality                                                                                          |
|------------------------------|--------------------------------------------------------------------------------------------------------|
| `journalctl --disk-usage`    | shows the current disk usage of all journal files                                                      |
| `journalctl --vacuum-files=` | leaves only the specified number of separate journal files                                             |
| `journalctl --vacuum-size=`  | removes the oldest archived journal files until the disk space they use falls below the specified size |
| `journalctl --vacuum-time=`  | removes archived journal files older than the specified timespan                                       |

---

### system groups[^18]
| group      | permissions                                                                                   |
|------------|-----------------------------------------------------------------------------------------------|
| `android`  | |
| `audio`    | direct access to sound hardware, for all sessions                                             |
| `kvm`      | access to virtual machines using kvm                                                          |
| `libvirt`  | users in this group can talk with libvirt service via dbus                                    |
| `pipewire` | |
| `plugdev`  | allows members to mount and umount removable devices through pmount                           |
| `users`    | the primary group for users when user private groups are not used (generally not recommended) |
| `video`    | access to video capture devices, 2d/3d hardware acceleration and framebuffer                  |
| `wheel`    | administration group, commonly used to give privileges to perform administrative actions      |

### creating user
```
emerge --ask app-admin/doas
useradd -mG android,audio,kvm,libvirt,pipewire,plugdev,users,video,wheel <user>
passwd <user>
touch /etc/doas.conf
chmod -c 0400 /etc/doas.conf
```

> [!CAUTION]
> assuming `app-admin/sudo` is installed and used, `/etc/sudoers` should always be edited with `visudo` \
> allow members of group wheel sudo access by uncommenting
> ```
> %wheel ALL=(ALL:ALL) ALL
> ```

> [!NOTE]
> adding pre-existing user to a group: `usermod -aG` \
> find out more here: https://man7.org/linux/man-pages/man8/usermod.8.html

> [!TIP]
> to prevent possible threat actors from logging in as root,                   \
> deleting the password and/or disabling root login can help improve security. \
> to delete the root password and disable login: `passwd -dl root`

---

### finishing up
```
exit
umount -l /mnt/gentoo/dev{/shm,/pts,}
umount -R /mnt/gentoo
cryptsetup close /dev/mapper/swap
cryptsetup close /dev/mapper/root
reboot
```

### eclean[^19]
```
emerge --ask app-portage/gentoolkit
eclean-dist -d
eclean-pkg
```

> [!NOTE]
> by default, source files are located in /var/cache/distfiles, while binary packages are located in /var/cache/binpkgs \
> both locations can grow quite big if not periodically cleaned

### nvidia, pipewire, virtualization[^20]

---

### to do
- proper referencing to docs but also files in the repository, make an index to navigate the readme too
- script to automatically apply system-wide configurations
- luks =>> properly configured w/ best practices (etc/crypttab & /etc/dracut.conf.d/)
- fdisk =>> add /boot partition for grub support?
- gentoo =>> minimal packages by use flags
- gentoo-sources =>> ditch gentoo-kernel-bin (partially tested, needs fine-tuning)

### docs
- [__acpi__][url-acpi]
- [__alsa__][url-alsa]
- [__backlight__][url-backlight] (arch)
- [__bash__][url-bash]
- [__bluetooth__][url-bluetooth]
- [__dispatch-conf__][url-dispatch-conf]
- [__dnsmasq__][url-dnsmasq]
- [__dracut__][url-dracut]
- [__eselect__][url-eselect]
- [__fonts__][url-fonts]
- [__fwupd__][url-fwupd]
- [__gamescope__][url-gamescope] (arch)
- [__gcc optimization__][url-gcc-optimization]
- [__gentoolkit__][url-gentoolkit]
- [__git__][url-git]
- [__guru__][url-guru]
- [__hybrid graphics__][url-hybrid-graphics]
- [__libinput__][url-libinput]
- [__libvirt__][url-libvirt]
- [__lto__][url-lto]
- [__networkmanager__][url-networkmanager]
- [__nvidia-drivers__][url-nvidia-drivers]
- [__optimus__][url-optimus]
- [__pipewire__][url-pipewire]
- [__power management__][url-power-management]
- [__printing__][url-printing]
- [__qemu__][url-qemu]
- [__rust__][url-rust]
- [__safe cflags__][url-safe-cflags]
- [__samba__][url-samba]
- [__secure boot__][url-secureboot]
- [__ssh__][url-ssh]
- [__steam__][url-steam]
- [__tmpfs__][url-tmpfs]
- [__tpm__][url-tpm]
- [__udev__][url-udev]
- [__unified kernel image__][url-unified-kernel-image]
- [__wine__][url-wine]
- [__xdg-desktop-portal__][url-xdg-desktop-portal]
- [__xfs__][url-xfs]
- [__xorg__][url-xorg]
- [__zsh__][url-zsh]
- [__zswap__][url-zswap]

<!-- docs -->
[url-acpi]:                  <https://wiki.gentoo.org/wiki/ACPI>
[url-alsa]:                  <https://wiki.gentoo.org/wiki/ALSA>
[url-backlight]:             <https://wiki.archlinux.org/title/Backlight>
[url-bash]:                  <https://wiki.gentoo.org/wiki/Bash>
[url-bluetooth]:             <https://wiki.gentoo.org/wiki/Bluetooth>
[url-dispatch-conf]:         <https://wiki.gentoo.org/wiki/Dispatch-conf>
[url-dnsmasq]:               <https://wiki.gentoo.org/wiki/Dnsmasq>
[url-dracut]:                <https://wiki.gentoo.org/wiki/Dracut>
[url-eselect]:               <https://wiki.gentoo.org/wiki/Eselect>
[url-fonts]:                 <https://wiki.gentoo.org/wiki/Fonts>
[url-fwupd]:                 <https://wiki.gentoo.org/wiki/Fwupd>
[url-gamescope]:             <https://wiki.archlinux.org/title/Gamescope>
[url-gcc-optimization]:      <https://wiki.gentoo.org/wiki/GCC_optimization>
[url-gentoolkit]:            <https://wiki.gentoo.org/wiki/Gentoolkit>
[url-git]:                   <https://wiki.gentoo.org/wiki/Git>
[url-guru]:                  <https://wiki.gentoo.org/wiki/Project:GURU>
[url-hybrid-graphics]:       <https://wiki.gentoo.org/wiki/Hybrid_graphics>
[url-intel]:                 <https://wiki.gentoo.org/wiki/Intel>
[url-kernel]:                <https://wiki.gentoo.org/wiki/Kernel>
[url-libinput]:              <https://wiki.gentoo.org/wiki/Libinput>
[url-libvirt]:               <https://wiki.gentoo.org/wiki/Libvirt>
[url-linux-firmware]:        <https://wiki.gentoo.org/wiki/Linux_firmware>
[url-lto]:                   <https://wiki.gentoo.org/wiki/LTO>
[url-lvm]:                   <https://wiki.gentoo.org/wiki/LVM>
[url-microcode]:             <https://wiki.gentoo.org/wiki/Microcode>
[url-networkmanager]:        <https://wiki.gentoo.org/wiki/NetworkManager>
[url-nvidia-drivers]:        <https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers>
[url-optimus]:               <https://wiki.gentoo.org/wiki/NVIDIA/Optimus>
[url-pipewire]:              <https://wiki.gentoo.org/wiki/PipeWire>
[url-power-management]:      <https://wiki.gentoo.org/wiki/Power_management>
[url-printing]:              <https://wiki.gentoo.org/wiki/Printing>
[url-qemu]:                  <https://wiki.gentoo.org/wiki/QEMU>
[url-rust]:                  <https://wiki.gentoo.org/wiki/Rust>
[url-safe-cflags]:           <https://wiki.gentoo.org/wiki/Safe_CFLAGS>
[url-samba]:                 <https://wiki.gentoo.org/wiki/Samba>
[url-secureboot]:            <https://wiki.gentoo.org/wiki/Secure_Boot>
[url-ssh]:                   <https://wiki.gentoo.org/wiki/SSH>
[url-steam]:                 <https://wiki.gentoo.org/wiki/Steam>
[url-swap]:                  <https://wiki.gentoo.org/wiki/Swap>
[url-systemd]:               <https://wiki.gentoo.org/wiki/Systemd>
[url-systemd-boot]:          <https://wiki.gentoo.org/wiki/Systemd/systemd-boot>
[url-tmpfs]:                 <https://wiki.gentoo.org/wiki/Portage_TMPDIR_on_tmpfs>
[url-tpm]:                   <https://wiki.gentoo.org/wiki/Trusted_Platform_Module>
[url-udev]:                  <https://wiki.gentoo.org/wiki/Udev>
[url-uefi]:                  <https://wiki.gentoo.org/wiki/UEFI>
[url-unified-kernel-image]:  <https://wiki.gentoo.org/wiki/Unified_kernel_image>
[url-wine]:                  <https://wiki.gentoo.org/wiki/Wine>
[url-xdg-desktop-portal]:    <https://wiki.gentoo.org/wiki/XDG/xdg-desktop-portal>
[url-xfs]:                   <https://wiki.gentoo.org/wiki/XFS>
[url-xorg]:                  <https://wiki.gentoo.org/wiki/Xorg>
[url-zsh]:                   <https://wiki.gentoo.org/wiki/Zsh>
[url-zswap]:                 <https://wiki.gentoo.org/wiki/Zswap>

---

### media ![](https://www.gentoo.org/assets/img/badges/gentoo-badge3.svg)
labwc, sfwbar, swww
![](https://github.com/librazhd7/gentoo/blob/b20de46ab18b650c6103c41a810cd1fa0927eba3/media/adwaita.jpg)
![](https://github.com/librazhd7/gentoo/blob/b20de46ab18b650c6103c41a810cd1fa0927eba3/media/breeze.jpg)
![](https://github.com/librazhd7/gentoo/blob/64dba2b11bd52959b0788bbfafb194f5b375c8da/media/oxygen.jpg)

---

### references
[^1]:   <https://linux.die.net/man/8/fdisk>
[^2]:   <https://en.wikipedia.org/wiki/GUID_Partition_Table>
[^3]:   <https://en.wikipedia.org/wiki/UEFI>
[^4]:   <https://en.wikipedia.org/wiki/EFI_system_partition>
[^5]:   <https://en.wikipedia.org/wiki/Linux_Unified_Key_Setup>
[^6]:   <https://en.wikipedia.org/wiki/Dm-crypt>
[^7]:   <https://en.wikipedia.org/wiki/Memory_paging>
[^8]:   <https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux)>
[^9]:   <https://wiki.gentoo.org/wiki/Portage>
[^10]:  <https://en.wikipedia.org/wiki/Chroot>
[^11]:  <https://en.wikipedia.org/wiki/Firmware>
[^12]:  <https://en.wikipedia.org/wiki/Microcode>
[^13]:  <https://en.wikipedia.org/wiki/Intel>
[^14]:  <https://en.wikipedia.org/wiki/Bootloader>
[^15]:  <https://en.wikipedia.org/wiki/Kernel_(operating_system)>
[^16]:  <https://en.wikipedia.org/wiki/Systemd>
[^17]:  <https://man7.org/linux/man-pages/man1/journalctl.1.html>
[^18]:  <https://wiki.debian.org/SystemGroups>
[^19]:  <https://wiki.gentoo.org/wiki/Eclean>
[^20]:  <https://en.wikipedia.org/wiki/Virtualization>
