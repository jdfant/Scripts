#!/bin/bash
# 
# This script will download & install MySQL and configure the services, users, and privileges.
#
PATH=/bin/:/sbin/:/usr/bin/:/usr/sbin

# Variables
sudoer="yes"
sysuser="admin"
sysuser_pw="this_is_a_weak_pw"
sys_hostname="localhost"
sys_site="'Internet Site'"
NFS_MOUNT_DIR="/var/www/html/media"
script_version="1.0"


header(){
        clear
    echo -e "\n Welcome to JD's Debian Web Stack Installer Version-${script_version}\n"
    echo -e "\n This script will create a 4Gb swap file, a system user, and will install & configure the following components:"
    echo -e "\n - Apache 2.4.x\n - PHP 5.5.x\n - MySQL Client\n - Postfix\n"
	    sleep 5
}

footer(){
	echo -e "\n------------------------------------------------------------------------"
	echo "                  Installation Process Complete"
	echo -e "-------------------------------------------------------------------------\n"
        sleep 3
}

validate_ip(){
    if [[ $1 =~ ^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$ ]];then
        echo -n
    else
        echo -e "\n That is not a valid IP address!\n Try again"
        sleep 2
        exit 1
    fi
}

swap_file(){
    if [[ $(awk '/SwapTotal/ {exit (!$2)}' /proc/meminfo) && $(awk 'NR==2 {print $2}' /proc/swaps) ]]; then
        echo -e "\nSwap is enabled and is located at:\n$(awk 'NR>1 {print $1}' /proc/swaps)\n"
    else
        echo -e "\nCreating a ${swap_size:-2G} swap file at ${swap_file:-/swapfile}"
            fallocate -l ${swap_size:-2G} ${swap_file:-/swapfile}
            chown root:root /swapfile
            chmod 0600 /swapfile
            mkswap /swapfile
            swapon /swapfile
            echo "${swap_file:-/swapfile}	swap	swap	defaults	0	0" >> /etc/fstab
        echo " Swapfile creation is complete"
    fi
}

sys_user(){
    echo -e "\n Creating local system user: ${sysuser}\n"
        useradd -s /bin/bash -m ${sysuser}
        echo "${sysuser}:${sysuser_pw}" | chpasswd
}

sudoers(){
    if [ ${sudoer} = "yes" ]; then
        echo -e "\n Granting ${sysuser} sudo rights\n"
        cp /etc/sudoers /etc/sudoers."$(date '+%b.%d.%Y')"
        echo "${sysuser}    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        echo -e "\n Complete\n"
    else
        echo -e"\n Skipping SUDO priviledges\n"
    fi
}

sys_prep(){
    echo -e "\n Please hold while we perform a system update\n"
    echo -e "\n Updating APT Repos"
        apt-get update > /dev/null 2>&1
    echo -e "\n Done\n\n Performing full system upgrade\n This may take a few minutes\n"
        apt-get -y dist-upgrade > /dev/null 2>&1
    echo -e "\n System upgrade is complete\n\n Removing outdated packages\n"
        apt-get -y autoremove > /dev/null 2>&1
    echo -e "\n Done"
    echo -e "\n Adding timestamps to bash history\n"
        sed -i."$(date '+%b.%d.%Y')" '$ a\export HISTTIMEFORMAT="%F %T "' /etc/bash.bashrc
}

config_nfs(){
        clear
    echo -e "\nConfiguring NFS Client\n\n\n"
    echo -e "\nEnter the IP address of the NFS Server"
        read -r IP
            validate_ip "${IP}"
        mkdir -p ${NFS_MOUNT_DIR}
            if [ -e /etc/fstab.orig ];then
                cp /etc/fstab /etc/fstab."$(date '+%b.%d.%Y')"
            else
                cp /etc/fstab /etc/fstab.orig
            fi
        echo "${IP}:${NFS_EXPORT_DIR} ${NFS_MOUNT_DIR} nfs4 rw,hard,intr,noatime 0 0" >> /etc/fstab
            echo -e "\n\n Please hold while I mount the NFS share.\n This will take 20-30 seconds.\n"
            mount ${NFS_MOUNT_DIR}
            sleep 2

    if grep -q nfs4 /proc/mounts;then
        echo -e "\n Cannot mount remote NFS share\nPlease investigate\n"
        exit 1
    else
        echo -e "\n NFS share is now mounted\n"
    fi

    echo -e "\n Preparing to transfer media contents to NFS server\n"
    if [[ $(dpkg --get-selections rsync|awk '{print $2}') == "install" ]];then
        echo -e "\n Rsync is already installed\n"
    else
        echo -e "\n Installing Rsync\n"
                if ! apt-get -qqy install rsync ; then
                    echo -e "\n Rsync install failed\n Run 'apt-get install rsync' manually to diagnose\n"
                else
                    echo -e "\n Rsync installed successfully\n"
                fi
    fi
#    rsync -r -a -v -e "ssh -l admin" "${NFS_MOUNT_DIR}" "${IP}":"${NFS_EXPORT_DIR}"
}

install_nfs(){
        clear
    echo -e "\n Updating APT Cache\n"
        apt-get -qq update

    if [[ $(dpkg --get-selections nfs-common|awk '{print $2}') == "install" ]];then
        echo -e "\n NFS client package is already installed\n"
    else
        echo -e "\n Installing NSF client package\n"
        if ! apt-get -qqy install nfs-common ; then
            echo -e "\n NFS client is now installed\n"
        else
            echo -e "\n Something failed.\n Try to install the nfs-common package manually"
            exit 1
        fi
    fi
        config_nfs
}
install_postfix(){
    echo -e "\n Installing Postfix\n"
        echo "postfix postfix/mailname string ${sys_hostname}
        postfix postfix/main_mailer_type string '${sys_site}'
        " | debconf-set-selections
    if ! DEBIAN_FRONTEND=noninteractive apt-get -y install postfix mailutils vim > /dev/null 2>&1; then
            clear
        echo -e "\n!!! Something failed !!!"
        echo "\n Run 'apt-get -y install postfix mailutils vim' manually to diagnose\n"
            sleep 5
            exit 1
    else
        echo -e "\n Postfix packages installed successfully\n"
            sleep 2
    fi

    echo -e "\n Adding Postfix logs to logrotate.d\n"        
    cat > /etc/logrotate.d/postfix << EOF
/var/log/mail.log {
  weekly
  rotate 10
  copytruncate
  delaycompress
  compress
  notifempty
  missingok
  }
EOF
    echo -e "\n Complete!"
}

install_mysql_client(){
    echo -e "\n Installing MySQL Client\n"
    if ! apt-get -y install mysql-client > /dev/null 2>&1; then
            clear
        echo -e "\n!!! Something failed !!!"
        echo -e "\n Run 'apt-get -y install mysql-client' manually to diagnose\n"
            sleep 5
            exit 1
    else
        echo -e "\n MySQL Client package installed successfully\n"
            sleep 2
    fi
}

install_apache(){
    echo -e "\n Installing Apache & PHP packages\n"
    if ! apt-get install -y php5 php5-mysql php5-curl php5-gd php5-mcrypt apache2-utils > /dev/null 2>&1; then
            clear
        echo -e "\n!!! Something failed !!!"
        echo "\n Run 'apt-get -y php5 php5-mysql php5-curl php5-gd php5-mcrypt apache2-utils' manually to diagnose\n"
            sleep 5
            exit 1
    else
        echo -e "\n Apache & PHP packages installed successfully\n"
            sleep 2
    fi
}

apache_mods(){
    echo -e "\n Enabling Apache rewrites, setting Apache options, restarting Apache\n"
        sed -i.orig 's/MaxConnectionsPerChild   0/MaxConnectionsPerChild   2000/g' /etc/apache2/mods-available/mpm_prefork.conf
        sed -i.bk 's/150/120/g' /etc/apache2/mods-available/mpm_prefork.conf
        a2enmod rewrite > /dev/null 2>&1
        service apache2 restart > /dev/null 2>&1
    echo -e "\n Complete!\n"
}

web_perms(){
    echo -e "\n Setting Web directory permissions\n"
        ln -sf /var/www/html /home/${sysuser}/html
        chown -R ${sysuser}:www-data /var/www/html/
        echo "<?php phpInfo(); ?>" > /var/www/html/phpinfo.php
    echo -e "\n Complete!\n"
}

web_services(){
    echo -e "\n Verifying Apache is listening on port 80 and all network interfaces\n"

    if [[ $(netstat -nlp | grep ':::80'|grep apache2) ]]; then
        echo -e "\n Verified!"
    else
        echo -e "\n ERROR - Apache service not running, exiting...\n"
        exit 1
    fi
}

# Execute functions
header
swap_file
sys_prep
sys_user
sudoers
install_postfix
install_mysql_client
install_apache
apache_mods
web_perms
web_services
footer
