#!/bin/bash

# Reboot system every 2 minutes UNLESS xrandr
# reports no 1024x768 reolution options.

check_res_file(){
if [ -f /home/jdfant/BAD_RES ];then
    echo -e "\nBAD_RES exists! Check that file.\n"
    exit 0
fi
}

reboot_system(){
if [[ $(DISPLAY=:0 xrandr|awk 'NR==3 {print $1}') == "1024x768" ]];then
    sudo /sbin/reboot
else
    echo -e "Screen got all jacked @ $(date '+%B %d %Y @ %H:%M')\n\n" > /home/jdfant/BAD_RES
    DISPLAY=:0 xrandr >> /home/jfant/BAD_RES
    echo -e "\n\n" >> /home/jdfant/BAD_RES
fi
}

check_res_file
reboot_system
