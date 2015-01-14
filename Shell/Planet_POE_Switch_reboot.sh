#!/bin/bash

poe_reboot() {
    clear
        echo -e "\nEnter the IP address of the POE switch:"
    read POE_ip
        echo -e "\nEnter the POE Switch user name:"
    read POE_user
        echo -e "\nEnter the POE Switch password:"
    read POE_pass
        (
        sleep 2
        echo ${POE_user}
        sleep 1
        echo ${POE_pass}
        sleep 2
        echo "configure"
        sleep 1
        echo "boot"
        sleep 1
        ) | /usr/bin/nc -t ${POE_ip} 23 > /dev/null 2>&1 &
}
poe_reboot
