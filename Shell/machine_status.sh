#!/bin/bash
#
# Make sure we source .bashrc
. ~/.bashrc

subject(){
    local do="$*"
        echo -e "\033[1m${do}\033[0m"
}

alert(){
    local do="$*"
        echo -e "\E[47;30m${do}\E[0m"
}

header(){
        echo -e "System Status\n======================\n"
        subject "System Uptime:"
        uptime|awk '{sub(",", "");print $3}'|awk -F':' '{print $1 " Hours and " $2 " Minutes"}'
        #grep JD /etc/os-release|awk '{sub(".noarch", "");print}'
}

alarms(){
    if [ "$(sudo grep ext /proc/mounts|awk '{print $4}'|awk -F, '{print $1}'|grep ro)" ]; then
        for i in $(grep 'ro,' /proc/mounts|awk '{print $2}')
            do alert "$i is mounted READ-ONLY -- Please Escalate \n"
        done
    else
        echo -n
    fi

    if [ "$(sudo grep -i 'bus error\|frozen' /var/log/messages)" ];then
        alert "This system may have a bad ATA controller -- Please Escalate \n"
    else
        echo -n
    fi

    if [ "$(sudo grep -i 'media error' /var/log/messages)" ];then
        alert "This system may have a corrupt filesystem -- Please Escalate \n"
    else
        echo -n
    fi
}

services(){
        echo
    if [ "$(ps ax|pgrep -f ModemManager)" ];then
        echo -n
    else
        alert "Modem Manager is not running"
    fi

    if [ "$(ps ax|pgrep -f puppet)" ];then
        echo -n
    else
        alert "Puppet is not running"
    fi

    if [ "$(ps ax|pgrep -f robot)" ];then
        echo -n
    else
        alert "Robot service is not running"
    fi

    if [ "$(ps ax|pgrep -f kili-core)" ];then
        echo -n
    else
        alert "Kilimanjaro is not running"
    fi

    if [ "$(ps ax|pgrep -f samhain)" ];then
        echo -n
    else
        alert "Samhain is not running"
    fi

    if [ "$(ps ax|pgrep -f webcam)" ];then
        echo -n
    else
        alert "Webcam Watcher is not running"
    fi

    zombie="$(ps -Al|grep Z|awk 'NR==2 {print $14}')"
    if [ "$(ps -Al|grep -c Z)" -gt 1 ];then
        alert " $zombie process is Defunct (Zombie) -- Please Escalate\n"
    else
        echo
    fi
}

clocks(){
    local HWC=$(/bin/date -d "$(sudo /sbin/hwclock --show)" +%s )
    local LC=$(/bin/date +%s)
    local count=$((${HWC}-${LC}))
    local diff=$(echo ${count}|awk '{sub("-", "");print}')

    if [[ "${diff}" -gt 2 || "${diff}" -lt -2 ]];then
        subject "Clocks:"
        alert "Hardware clock (cmos) and system time are NOT in sync"
        echo "System Clock   = $(date "+%a %d %b %Y %r %Z")"
        echo "Hardware Clock =" "$(sudo hwclock|awk '{print $8="",$9="";print}')"
    else
        echo -n
    fi
}

hd_health(){
        local power=$(sudo smartctl -A /dev/sda -d sat -T permissive|grep 'Power_On_Hours'|awk '{print $2, "\t","\t", $10}')
        local reallo=$(sudo smartctl -A /dev/sda -d sat -T permissive|grep 'Reallocated_S'|awk '{print $10}')
        local pending=$(sudo smartctl -A /dev/sda -d sat -T permissive|grep 'Pending_S'|awk '{print $10}')
        local offline=$(sudo smartctl -A /dev/sda -d sat -T permissive|grep 'Offline_Un'|awk '{print $10}')

    if [ "${reallo}" -gt 0 ];then
        alert "Hard drive contains $reallo Reallocated Sectors!"
    else
        echo -n
    fi

    if [ "${pending}" -gt 0 ];then
        alert "Hard drive contains $pending Pending Sectors!"
    else
        echo -n
    fi

    if [ "${offline}" -gt 0 ];then
        alert "Hard drive contains $offline Offline_Uncorrectable Sectors!"
    else
        echo -n
    fi
}

mem(){
        subject "Memory Usage:"
        /usr/bin/free -m|awk 'NR==1,NR==2'|sed 's/Mem:/    /'|awk '{sub(/^[ \t]+/, "")};1'
}

rpms(){
    subject "Package Versions:"
    echo -e "Git Branch = ""$(awk -F'=' '{print $2}' /etc/puppetenv)"

    local kili-core=$(rpm -qa kili-core*|awk '{sub(".noarch", "");print}')
    if [ $? -eq 0 ]; then
        echo "${kili-core}"
    else
        alert " Kili-Core package is not installed"
    fi

    local kili_resources=$(rpm -qa kili-resources*|awk '{sub(".noarch", "");print}')
    if [ $? -eq 0 ]; then
        echo "${kili_resources}"
    else
        alert " Kili-Resources package is not installed"
    fi

    local system=$(rpm -qa |grep Core-System|awk '{sub(".noarch", "");print}')
    if [ $? -eq 0 ]; then
        echo "${system}"
    else
        alert " Core-System package is not installed"
    fi

    local robot=$(rpm -qa |grep robot|awk '{sub(".noarch", "");print}')
    if [ $? -eq 0 ]; then
        echo "${robot}"
    else
        alert " Robot package is not installed"
    fi

    local cheyenne=$(rpm -qa cheyenne*|awk '{sub(".noarch", "");print}')
    if [ $? -eq 0 ]; then
        echo "${cheyenne}"
    else
        alert " Cheyenne package is not installed"
    fi
}

network(){
        subject "\nNetwork Information:"
        echo -ne "Kiosk IP: $(ifconfig enp2s0|awk -F ' * |:' '/inet/{print $4}')"
        echo -e "\nGateway IP: $(route -n|grep UG|awk 'NR==1{print $2}')"

#        echo -e "\nLAN (Secondary) IP: $(ifconfig eth1|awk -F ' * |:' '/inet/{print $4}')"

}

# Compensate for default Putty/Kitty window size
printf '\033[8;40;90t';clear
# ==========================================================
header
alert
clocks
rpms
services
hd_health
mem
network
alarms
    echo
# ==========================================================
# vim: set ts=4 sw=4 noet:
