#!/bin/bash
#
# This script is for RedHat 6 variants only. 
# Brings up eth0:1 AFTER dhclient has started
#
    if [[ $EUID -eq 0 ]] ; then
        clear
        echo -e "\n Please execute this script as a user with sudo rights.\n"
        sudo logger -t FAIL "Root attempted to run dhclient.alias_up.sh script"
        exit 0
    fi

    if [ "$(grep '6\.' /etc/redhat-release)" ];then
        sudo echo "#!/bin/sh" | tee /etc/dhcp/dhclient.d/ifup-eth0:1.sh 
        sudo echo "/sbin/ifup eth0:1 &> /dev/null" | tee -a /etc/dhcp/dhclient.d/ifup-eth0:1.sh 
        sudo chmod +x /etc/dhcp/dhclient.d/ifup-eth0:1.sh
    else
        echo -e "\nThis is not necessary for Fedora 5, or CentOS 5.2 & 5.6 systems\n"
    fi

    # Bring up eth0:1 while we're here.
        sudo /sbin/ifup eth0:1 &> /dev/null
