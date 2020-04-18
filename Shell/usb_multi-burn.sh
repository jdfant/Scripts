#!/bin/bash

echo -e "\nPreparing USB Stick\n"

# Ensure USB Sticks contain DOS partition tables and are formatted EXT4
echo -e "\nCreating DOS (MBR) partition tables and formatting sticks EXT4\n"

for usb in $(dmesg|grep 'Attached SCSI'|awk '{gsub(/\[/,"");gsub(/\]/,"");print $4}'|grep -v 'sda'|sort -u)
do
    sudo sh -c 'echo -e "o\nn\np\n1\n\n\na\nw\ny"' | sudo fdisk /dev/"${usb}"
    sudo mkfs.ext4 -F /dev/"${usb}"1
done

# Mount USB Devices to /mnt/[1-10]
echo -e "\nMounting USB Sticks to /mnt/[1-10]\n"

mount_point=1
for usb in $(dmesg|grep 'Attached SCSI'|awk '{gsub(/\[/,"");gsub(/\]/,"");print $4}'|grep -v 'sda'|sort -u)
do
sudo mount /dev/"${usb}"1 /mnt/$((mount_point++))
done

# Rsyncing image contents to USB Sticks
echo -e "\nThis will take a while\nI'll let ya know when we're ready\n"
cat ~/usb_burn_devices | sudo /usr/local/bin/parallel -v --will-cite -j 10 rsync -av --progress ~/Build-Encrypted-Leap/ {}

# Make USB Sticks bootable
echo -e "\nMaking USB Sticks bootable\n"
for usb in $(dmesg|grep 'Attached SCSI'|awk '{gsub(/\[/,"");gsub(/\]/,"");print $4}'|grep -v 'sda'|sort -u)
do
sudo Build-Encrypted-Leap/utils/linux/makeboot.sh -b /dev/"${usb}"1
done

# Unmounting USB Devices
echo -e "\nUnmounting USB Sticks\n"
sudo umount /mnt/*

# Finished ..... Ding!
echo -ne "\07"
echo -e "\nUSB Sticks are ready\n?? .... or at least they should be .... ??\n"
