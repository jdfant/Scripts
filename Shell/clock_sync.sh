#!/bin/bash
#
# Check (and hopefully sync) the system and hardware
# clocks on SysV init and Systemd linux
#
# This requires ntpd to be installed
#
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

subject(){
    local wordz="$@"
        echo -e "\033[1m${wordz}\033[0m"
}

alert(){
    local wordz="$@"
        echo -e "\E[47;30m${wordz}\E[0m"
}

check_root(){
    if [[ $EUID -eq 0 ]] ; then
        clear;echo -e "\nPlease login with a non-root user name.\n"
        exit 1
    fi
}

check_apps(){
        clear
        echo -e "\nChecking that required apps are installed.\n"

    if hash ntpd &> /dev/null ;then
        subject "\n ntpd is installed.\n"
    elif [ "$(hash ntpq &> /dev/null)" ] || [ -x /usr/sbin/ntpd ] ;then
        alert "\n Looks like we're using a Debian variant."
    else
        alert "\n ntpd is not installed\n\n Install ntpd and restart script.\n"
        exit 1
    fi
        echo -e "\nAll checks passed, continuing ...\n"
}

sys_mgmt(){
    if [[ -e /etc/redhat-release && ! -d /etc/systemd ]];then
        sys="SysV"
    elif [[ ! -d /etc/systemd ]];then
        sys="SysV"
    elif [ -e /etc/arch-release ];then
        sys="SYSTEMD"
    else
        sys="SYSTEMD"
    fi
}

clock_sync(){
    unset HWC LC count diff
    sys_mgmt
        echo -e "\n Please hold, syncing clocks now.\n"\
                " This may break your SSH connection.\n"\
                " Log back in if it does.\n"
    if [ ${sys} == SYSTEMD ];then
        sudo systemctl stop ntpd &> /dev/null
        sudo ntpd -gq &> /dev/null &&\
             ntpd -gq &> /dev/null
        sleep 2
        sudo systemctl start ntpd &> /dev/null
        sudo hwclock -w &> /dev/null
            sleep 1

    elif [ ${sys} == SysV ];then
        sudo service ntpd stop &> /dev/null
        sudo ntpd -gq &> /dev/null &&\
             ntpd -gq &> /dev/null
            sleep 1
        sudo service ntpd start &> /dev/null
        sudo hwclock -w &> /dev/null
            sleep 1
    fi

    local HWC=$(date -d "$(sudo hwclock --show)" +%s )
    local LC=$(date +%s)
    local count=$((${HWC}-${LC}))
    local diff=$(echo ${count}|awk '{sub("-", "");print}')

    if [[ "${diff}" -gt 2 || "${diff}" -lt -2 ]];then
        alert " Syncing clocks did not seem to work.\n"
        sudo logger -t CLOCKS "Unsuccessful clock synchronization was attempted."
    else
        clear
        echo -e "\n Rechecking Clocks\n"
        echo "* System Clock   = $(date "+%a %d %b %Y %r %Z")"
        echo "* Hardware Clock =" "$(sudo hwclock|awk '{print $8="",$9="";print}')"
        sudo logger -t CLOCKS "Successful clock synchronization has been performed."
        echo -e "\nLooks good!\n"
    fi
}

clocks(){
    unset HWC LC count diff
    local HWC=$(date -d "$(sudo hwclock --show)" +%s )
    local LC=$(date +%s)
    local count=$((${HWC}-${LC}))
    local diff="$(echo ${count}|awk '{sub("-", "");print}')"
        subject "\nClocks:"
        echo "* System Clock   = $(date "+%a %d %b %Y %r %Z")"
        echo "* Hardware Clock =" "$(sudo hwclock|awk '{print $8="",$9="";print}')"
        echo
    # Alert if clocks are more than 5 seconds apart
    if [ "${HWC}" -ne "${LC}" ];then
        if [[ "${diff}" -gt 5 || "${diff}" -lt -5 ]];then
            alert "\n System and Hardware Clocks are NOT in sync.\n"
            clock_sync
        fi
    fi
}

# Make it so #1
  clear
check_root
check_apps
clocks
