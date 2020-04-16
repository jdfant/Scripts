#!/bin/bash

check_root(){
    if [[ $EUID -eq 0 ]] ; then
        clear;echo -e "\nThis will not run as root\n"
        exit 0
    fi
}

enter_key(){
    local message="$*"
        [ -z "${message}" ] && message="Press [Enter] key to continue..."
    echo
        read -rp "$message" readEnterKey
}

confirm () {
    clear
    echo -e "About to ${COMMAND} \n"
    read -rp "${1:-Are you sure? [y/N]} " yn
    case ${yn} in
        [yY][eE][sS]|[yY])
            true
            clear ;;
        *)
            false
            ;;
    esac
}

check_systemID(){
    if ! [[ "{$SYSTEM_ID}" =~ ^800[0-9]{3}$ || "${SYSTEM_ID}" =~ ^1[0-9]{4}$ || "${SYSTEM_ID}" =~ ^[1-7][0-9]{3}$ ]]; then
        echo -e "\n Please enter a valid System ID\n"
        unset SYSTEM_ID
        enter_system
    fi
}

enter_system(){
        clear
        echo -e "\nWelcome to JD's Control Panel\n"
        read -rp "Please enter the System ID: " SYSTEM_ID
        check_systemID
}

show_menu(){
        clear
    echo "---------------------------"
    echo "    JD's Control Panel"
    echo "---------------------------"
    echo -e "1.  SSH into ${SYSTEM_ID}"
    echo -e "2.  Reset Error State on ${SYSTEM_ID}"
    echo -e "3.  Set Error State on ${SYSTEM_ID}"
    echo -e "4.  List USB devices on ${SYSTEM_ID}"
    echo -e "5.  Check UPS status on ${SYSTEM_ID}"
    echo -e "6.  Reset Network on ${SYSTEM_ID}"
    echo -e "7.  Reset Web Cam on ${SYSTEM_ID}"
    echo -e "8.  System Update on ${SYSTEM_ID}"
    echo -e "9.  Audio check on ${SYSTEM_ID}"
    echo -e "10. Check for Tech Password on ${SYSTEM_ID}"
    echo -e "11. View Live Robot logs on ${SYSTEM_ID}"
    echo -e "12. View Today's Robot logs on ${SYSTEM_ID}"
    echo -e "13. View Robot logs after ${SYSTEM_ID} has been 'Out Of Order'"
    echo -e "14. Router/Modem Info on ${SYSTEM_ID}"
    echo -e "15. Calibrate the TouchScreen on ${SYSTEM_ID}"
    echo -e "16. Reload TouchScreen Driver on ${SYSTEM_ID}"
    echo -e "17. Reboot ${SYSTEM_ID}"
    echo -e "18. Power Cycle ${SYSTEM_ID}"
    echo -e "19. Emergency Reboot ${SYSTEM_ID}"
    echo -e "20. Emergency Power Cycle ${SYSTEM_ID}"
    echo -e "21. Enter new System ID"
    echo -e "22. Exit\n"
}

ssh_system(){
    local COMMAND="SSH into ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 2> /dev/null
    enter_key
}

reset_error(){
    local COMMAND="Reset Error State on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222  "${SYSTEM_ID}" 'sudo reset-error' 2> /dev/null
    enter_key
}

set_error(){
    local COMMAND="Set Error State on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo set-error "Error set from System Control Panel"' 2> /dev/null
    enter_key
}

list_usb(){
    local COMMAND="List USB Devices on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'echo -e "\nConnected USB Devices:\n" && bash -c /usr/bin/lsusb' 2> /dev/null
    enter_key
}

ups_status(){
    local COMMAND="Check UPS Status on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'echo -e "\nUPS Status:\n" && /usr/bin/upsc ups|grep "battery.charge:\|ups.mfr:\|ups.status:"' 2> /dev/null
    enter_key
}

reset_network(){
    local COMMAND="Reset Network on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo network-cycle' 2> /dev/null
    enter_key
}

reset_webcam(){
    local COMMAND="Reset Web Cam on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo reset-webcam' 2> /dev/null
    enter_key
}

sys_update(){
    local COMMAND="Check for System Updates on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo system-update' 2> /dev/null
    enter_key
}

check_audio(){
    local COMMAND="Check Audio status on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo /usr/sbin/control_panel-client.sh -a' 2> /dev/null
    enter_key
}

tech_pw(){
    local COMMAND="Check for USATech Password on ${SYSTEM_ID}"
    confirm
    if  /usr/bin/ssh -qt -p2222 "${SYSTEM_ID}" 'grep -q Tech.password /var/local.conf'; then
        /usr/bin/ssh -qt -p2222 "${SYSTEM_ID}" "awk '/Tech.password/ {print \"\nTech Password is: \" \"\n\"\$3}' /var/local.conf|sed 's/\"//g'"
    else
        echo -e "\nThis System is not setup with a Tech Password\n"
    fi
    enter_key
}

hd_health(){
    local COMMAND="Check Hard Drive Health on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" "sudo smartctl -A /dev/sda -d sat -T permissive|awk '{print \$2, \$10}'|grep 'Reallocated_S\|Pending_S\|Offline_Un'" 2> /dev/null
    enter_key
}

robot_now(){
    local COMMAND="Check Live Robot Logs on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'echo -e "\n\nUse CTRL-C to Exit\n" && bash -ic robot-now' 2> /dev/null
    enter_key
}

robot_today(){
    local COMMAND="Check Today's Robot Logs on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'journalctl -u robot --since today|grep ERROR' 2> /dev/null
    enter_key
}

robot_ooo(){
    local COMMAND="Check Robot Logs on ${SYSTEM_ID} since after 'Out of Order' "
    confirm && /usr/bin/ssh -t "${SYSTEM_ID}" 'bash -ic robot-ooo' 2> /dev/null
    enter_key
}

router_modem(){
    local COMMAND="Retrieve Router/Modem Information on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" '/usr/bin/mmcli -L && /etc/facter/facts.d/router-modem-facts.sh' 2> /dev/null
    enter_key
}

tw_reload(){
    local COMMAND="Reload the TouchScreen Driver on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo pkill xorg' 2> /dev/null
    enter_key
}

calibrate_screen(){
    local COMMAND="Calibrate the TouchScreen on ${SYSTEM_ID}\n\nTech MUST be onsite for this operation!\n"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" "sudo /usr/sbin/control_panel-client.sh -c" 2> /dev/null
    enter_key
}

update_java(){
    local COMMAND="Update Java on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" 'sudo update-alternatives --config java' 2> /dev/null
    enter_key
}

diags(){
    local COMMAND="Run Diagnostics on ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -p 2222 "${SYSTEM_ID}" '~/machine_status' 2> /dev/null
    enter_key
}

reboot(){
    local COMMAND="(Safe) Reboot ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -f -p 2222 "${SYSTEM_ID}" 'sudo systemctl reboot' 2> /dev/null
    enter_key
}

power_cycle(){
    local COMMAND="(Safe) Power Cycle ${SYSTEM_ID}"
    confirm && /usr/bin/ssh -t -f -p 2222 "${SYSTEM_ID}" 'sudo /usr/sbin/power-cycle' 2> /dev/null
    enter_key
}

emergency_reboot(){
    local COMMAND="Emergency Reboot ${SYSTEM_ID} Now"
    confirm && /usr/bin/ssh -t -f -p 2222 "${SYSTEM_ID}" 'sudo systemctl reboot -i' 2> /dev/null
    enter_key
}

emergency_power_cycle(){
    local COMMAND="Emergency Power Cycle ${SYSTEM_ID} Now"
    confirm && /usr/bin/ssh -t -f -p 2222 "${SYSTEM_ID}" 'sudo /usr/sbin/emergency-power-cycle' 2> /dev/null
    enter_key
}

read_choice(){
    local c
    read -rp "Enter your choice [ 1 - 22 ] " c
    case $c in
        1) ssh_system ;;
        2) reset_error ;;
        3) set_error ;;
        4) list_usb ;;
        5) ups_status ;;
        6) reset_network ;;
        7) reset_webcam ;;
        8) sys_update ;;
        9) check_audio ;;
       10) tech_pw ;;
       11) robot_now ;;
       12) robot_today ;;
       13) robot_ooo ;;
       14) router_modem ;;
       15) calibrate_screen ;;
       16) tw_reload ;;
       17) reboot ;;
       18) power_cycle ;;
       19) emergency_reboot ;;
       20) emergency_power_cycle ;;
       21) enter_system ;;
       22) clear;echo -e "\nGoodbye\n";sleep 1;clear;exit;kill -9 ${PPID} ;;
        *)
        clear;echo -e "\nThat was not a number between 1 & 22\nTry again\n";sleep 2
    esac
}

# Ignore CTRL+C, CTRL+Z, and Quit signals
#trap '' SIGINT SIGQUIT SIGTSTP

# Make it GO!

# Compensate for default Putty/Kitty window size
printf '\033[8;40;90t';printf '\e[3;0;0t';clear
        check_root
        enter_system
    while true
    do
        show_menu
        read_choice
    done
