#!/bin/bash
#
# This script is designed for Debian based systems for building a 
# simple NFS environment. All NFS files will be downloaded and
# installed. Options are available to configure NFS server and clients.
#

check_root(){
    if [[ $EUID -ne 0 ]] ; then
        clear
        echo -e "\n You must be root (sudo -i) to execute this script\n" # 1>&2
        exit 1
    fi
}

show_menu(){
        clear
    echo "----------------------"
    echo "   NFS Installer   "
    echo -e "---------------------\n"
    echo -e "\nSelect the installer to use: \n"
    echo -e "1. Server"
    echo -e "2. Client"
    echo -e "3. Exit\n"
}

validate_ip(){
    if [[ ${1} =~ ^([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})$ ]]; then
        OCT_CHECK="$(echo ${1}|awk -F'.' '$1 <=255 && $2 <= 255 && $3 <= 255 && $4 <= 255')"
            if [ -z "${OCT_CHECK}" ]; then
                clear
                echo -e "\n Octet values must not exceed 255!\n\n Let's try this again.\n" 
                sleep 2
                ${CONFIG_OPT}
            else
                echo -n
            fi
    else
        echo -e "\n That is not a valid IP address!\n Try again"
        sleep 2
            ${CONFIG_OPT}
    fi
}

rsync_xfer(){
    " WIP. Function not in use at this time "
    echo -e "\n Preparing to transfer media contents to NFS server\n"

    if hash rsync &> /dev/null; then
        echo -e "\n Installing Rsync\n"
            apt-get -qqy install rsync &> /dev/null
                if [ $? != 0 ];then
                    echo -e "\n Rsync install failed\n Run 'apt-get install rsync' manually to diagnose\n"
                else
                    echo -e "\n Rsync installed successfully\n"
                fi
    else
        echo -e "\n Rsync is already installed\n"
    fi
}

config_server(){
        unset CONFIG_OPT
        CONFIG_OPT="config_server"
            clear
    echo -e "\nConfiguring NFS Server\n\n\n"
    echo -e "Enter the IP address of the first NFS Client:"
        read IP1
            validate_ip ${IP1}
    echo -e "\nEnter the IP address of the second NFS Client:"
        read IP2
            validate_ip ${IP2}
    echo -e "\nEnter the Directory to be exported: (default is "/NFS/media""
        read EXPORTS
            mkdir -m755 -p ${EXPORTS:-"/NFS/media"}
            cp /etc/exports /etc/exports.orig
    echo "${EXPORTS:-"/NFS/media"} ${IP1}(rw,no_subtree_check) ${IP2}(rw,no_subtree_check)" > /etc/exports 
        update-rc.d nfs-kernel-server defaults
        service nfs-kernel-server restart
        service idmapd restart
}

config_client(){
        unset CONFIG_OPT
        CONFIG_OPT="config_client"
            clear
    echo -e "\nConfiguring NFS services\n\n\n"
    echo -e "\nEnter the IP address of the NFS Server"
        read IP
            validate_ip ${IP}
    echo -e "\nEnter the NFS 'Mount Point': (default is "/var/www/nfs")"
        read MNT_PNT
            mkdir -m755 -p ${MNT_PNT:-"/var/www/nfs"}
    echo "${IP}:${EXPORTS:-"/NFS/media"} ${MNT_PNT:-"/var/www/nfs"} nfs4 rw,hard,intr,noatime 0 0" >> /etc/fstab
        mount ${MNT_PNT:-"/var/www/nfs"}
        sleep 2
    if ! grep -q nfs4 /proc/mounts; then
        echo -e "\n Cannot mount remote NFS share\nPlease investigate\n"
        exit 1
    else
        echo -e "\n NFS share is now mounted\n"
    fi
}

install_server(){
        clear
    echo -e "\nPlease hold while I update the apt cache\n"
    apt-get update &> /dev/null

    if [[ $(dpkg --get-selections nfs-kernel-server) == "install" ]];then
         echo -e "\n NFSv4 server package is already installed\n"
    else
        echo -e "\n Installing NSFv4 server package"
            apt-get -qqy install nfs-kernel-server &> /dev/null
        if [ $? = 0 ];then
            echo -e "\n NFS server is now installed\n"
        else
            echo -e "\n Something failed.\n Try to install the nfs-kernel-server package manually"
            exit 1
        fi
    fi
    config_server
}

install_client(){
        clear
    echo -e "\n Updating APT Cache\n"
        apt-get update  &> /dev/null

    if [[ $(dpkg --get-selections nfs-common) == "install" ]];then
        echo -e "\n NFS client package is already installed\n"
    else
        echo -e "\n Installing NSF client package\n"
            apt-get -qqy install nfs-common &> /dev/null
        if [ $? = 0 ];then
            echo -e "\n NFS client is now installed\n"
        else
            echo -e "\n Something failed.\n Try to install the nfs-common package manually"
            exit 1
        fi
    fi
    config_client
}

read_choice(){
    local c
    read -p "Enter your choice [ 1 - 3 ] " c
    case $c in
        1) install_server ;;
        2) install_client ;;
        3) clear;echo -e "\nGoodbye!\n";sleep .5;reset;exit ;;
        *)
        echo -e "\nThat was not a number between 1 & 3\nTry again\n"
    esac
}

# Execute
    while true
    do
        check_root
        show_menu
        read_choice
    done
