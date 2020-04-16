#!/bin/sh

# Create GPT partitions 
gpart create -s gpt ada1
gpart create -s gpt ada2
gpart add -b 34 -s 512k -t freebsd-boot ada1
gpart add -b 34 -s 512k -t freebsd-boot ada2
gpart add -s 4G -t freebsd-swap -l swap0 ada1
gpart add -s 4G -t freebsd-swap -l swap1 ada2
gpart add -t freebsd-zfs -l system0 ada1
gpart add -t freebsd-zfs -l system1 ada2

# Installl bootcode
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada1
gpart bootcode -b /boot/pmbr -p /boot/gptzfsboot -i 1 ada2

# Create zpools and set mountpoints
zpool create -m none -o altroot=/mnt -o cachefile=/var/tmp/zpool.cache \
    system mirror /dev/gpt/system0 /dev/gpt/system1
zfs set mountpoint=/ system

# Create ZFS slices
zfs create -o compression=on -o setuid=off system/tmp
chmod 1777 /mnt/tmp

zfs create system/usr
zfs create system/usr/home
cd /mnt || exit
ln -sf usr/home home

zfs create system/usr/local
zfs create -o compression=lz4 -o setuid=off system/usr/ports
zfs create -o exec=off -o setuid=off system/usr/ports/distfiles
zfs create -o exec=off -o setuid=off system/usr/ports/packages
zfs create system/usr/obj
zfs create -o compression=lz4 -o exec=off -o setuid=off system/usr/src

zfs create system/var
zfs create -o exec=off -o setuid=off system/var/backups
zfs create -o compression=lz4 -o exec=off -o setuid=off system/var/crash
zfs create -o exec=off -o setuid=off system/var/db
zfs create -o exec=on -o compression=lz4 -o setuid=off system/var/db/pkg
zfs create -o exec=off -o setuid=off system/var/empty
zfs create -o compression=lz4 -o exec=off -o setuid=off system/var/log
zfs create -o compression=lz4 -o exec=off -o setuid=off system/var/mail
zfs create -o exec=off -o setuid=off system/var/run

zfs create -o compression=lz4 -o setuid=off system/var/tmp
chmod 1777 /mnt/var/tmp

# Uncomment for MySQL/MariaDB server:
#zfs create -o compression=lz4 -o atime=off -o recordsize=8k system/var/db/mysql
#zfs create -o compression=lz4 -o atime=off -o recordsize=16k -o primarycache=metadata system/var/db/mysql-innodb
#zfs create -o compression=lz4 -o atime=off -o recordsize=128k -o primarycache=metadata system/var/db/mysql-innodb-logs

# Set zpool boot
zpool set bootfs=system system
zfs set checksum=fletcher4 system
mkdir -p /mnt/boot/zfs
cp /var/tmp/zpool.cache /mnt/boot/zfs/zpool.cache

echo "This is to be entered manually AFTER install completes."
echo "On last install screen, choose "Shell" again when asked."
echo "Enter:"
echo "echo 'zfs_load="YES"' >> /boot/loader.conf"
echo "echo 'vfs.root.mountfrom="zfs:system"' >> /boot/loader.conf"
echo "echo 'zfs_enable="YES"' >> /etc/rc.conf"
echo
echo "ZFS needs zero fstab entries, only swap entries are  necessary"
echo "Device                Mountpoint      FStype  Options         Dump    Pass"
echo "/dev/label/swap0        none            swap    sw              0       0"
echo "/dev/label/swap1        none            swap    sw              0       0"
echo
echo "After reboot, login as root and enter:"
echo "zfs set readonly=on system/var/empty"
echo
echo "Enjoy"
echo
echo "!! NOW REBOOT !!"
echo
