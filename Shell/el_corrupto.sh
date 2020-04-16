#!/bin/bash
#
# This script attempts to corrupt the filesystem, create
# hard drive activity/load, then force a kernel panic.
#
# Check the results of this script by running the command:
#   sudo less /var/log/boot.log
#

el_corrupto(){
    # Yes, a block size of 1 byte.
    # Using seek=20000 to avoid corrupting the superblock.
    dd if=/dev/zero bs=1 count=10 of=/dev/sda1 seek=20000

    # Let's generate some drive activity leaving a mess in the process.
    dd if=/dev/random of=/load_test_file1 bs=1024 count=2000000 &
    dd if=/dev/random of=/home/load_test_file2 bs=1024 count=2000000 &
    dd if=/dev/random of=/var/load_test_file3 bs=1024 count=2000000 &
    dd if=/dev/random of=/boot/load_test_file4 bs=1024 count=2000000 &

    # Now generate a fatal kernel panic while under a load
    sleep 2
    echo c > /proc/sysrq-trigger

}

if [[ $(hostname) = *.production.lan ]]; then
    echo -e "\nSorry, but I will not allow you to run this on a production server!\n"
    exit 1
fi

clear
echo -e "\n\n          *** WARNING ***\n"\
        "\n This WILL cause major interruptions\n"\
        "Babies will cry and planes could crash\n"

    while true
     do
        read -rp " Do you want to continue (Y/N)?" answer
        case $answer in
            [Yy]* ) clear;el_corrupto;;
            [Nn]* ) break ;;
                * ) echo "Please answer yes (Y) or no (N)." ;;
        esac
    done
