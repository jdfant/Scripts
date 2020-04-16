#!/bin/bash
# 
# This script will download & install MySQL and configure the services, users, and privileges.
#
PATH=/bin/:/sbin/:/usr/bin/:/usr/sbin

# Variables:
sudoer="yes"
sysuser="admin"
sysuser_pw="this_is_a_weak_pw"
dbuser=""
dbuser_pw=""
dbroot_pw="this_is_a_weak_pw"
NFS_EXPORT_DIR="/var/www/html/media"
WEB_UID=33
WEB_GID=33
script_version="1.0"

header(){
        clear
    echo -e "\n Welcome to JD's Debian MySQL Stack Installer Version-${script_version}\n"
    echo -e "\n This script will install & configure the following components:"
    echo -e "  - MySQL Server\n  - MySQL Client\n"
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
        useradd -s /bin/bash -m "${sysuser}"
        echo "${sysuser}:${sysuser_pw}" | chpasswd
}

sudoers(){
    if [ "${sudoer}" = "yes" ]; then
        echo -e "\n Granting ${sysuser} sudo rights\n"
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

config_nfs_server(){
        clear
    echo -e "\nConfiguring NFS Server\n\n\n"
    echo -e "Enter the IP address of the first NFS Client"
        read -r IP1
            validate_ip "${IP1}"
    echo -e "\nEnter the IP address of the second NFS Client"
        read -r IP2
            validate_ip "${IP2}"
        mkdir -m700 -p "${NFS_EXPORT_DIR}"
        chown "${WEB_UID}":"${WEB_GID}" "${NFS_EXPORT_DIR}"
            if [ -e /etc/exports.orig ];then
                cp /etc/exports /etc/exports."$(date '+%b.%d.%Y')"
            else
                cp /etc/exports /etc/exports.orig
            fi

    echo "${NFS_EXPORT_DIR} ${IP1}(rw,no_subtree_check,all_squash,anonuid=${WEB_UID},anongid=${WEB_GID})\
    ${IP2}(rw,no_subtree_check,all_squash,anonuid=${WEB_UID},anongid=${WEB_GID})" > /etc/exports
        update-rc.d nfs-kernel-server defaults
        service nfs-kernel-server restart
        service idmapd restart
}

install_nfs_server(){
        clear
    echo -e "\nPlease hold while I update the apt cache\n"
        apt-get -qq update

    if [[ "$(dpkg --get-selections nfs-kernel-server|awk '{print $2}')" == "install" ]];then
         echo -e "\n NFSv4 server package is already installed\n"
    else
        echo -e "\n Installing NSFv4 server package"

	if ! apt-get -qqy install nfs-kernel-server > /dev/null 2>&1 ; then
            echo -e "\n NFS server is now installed\n"
        else
            echo -e "\n Something failed.\n Try to install the nfs-kernel-server package manually"
            exit 1
        fi
    fi
}

config_mysql(){
    mv /etc/mysql/my.cnf /etc/mysql/my.cnf.orig
    cat > /etc/mysql/my.cnf << EOF
#
# JD's base MySQL database server configuration file.
# This configuration is for systems with 8GB or more of RAM.
#
[client]
port                            = 3306
socket                          = /var/run/mysqld/mysqld.sock

[mysqld_safe]
socket                          = /var/run/mysqld/mysqld.sock
nice                            = 0

[mysqld]
#innodb_force_recovery          = 4  # Only change this if you know what you're doing!
user                            = mysql
pid-file                        = /var/run/mysqld/mysqld.pid
socket                          = /var/run/mysqld/mysqld.sock
port                            = 3306
basedir                         = /usr
datadir                         = /var/lib/mysql
tmpdir                          = /tmp
lc-messages-dir                 = /usr/share/mysql
skip-external-locking

bind-address                    = 0.0.0.0

key_buffer                      = 128M
max_connections                 = 200
max_allowed_packet              = 64M
thread_stack                    = 256K
thread_cache_size               = 200
tmp_table_size                  = 32M
max_heap_table_size             = 32M
myisam-recover                  = BACKUP
table_open_cache                = 1024  # Careful. Each open table uses a file descriptor
query_cache_limit               = 1M
query_cache_size                = 92M

log_error                       = /var/log/mysql/error.log

#expire_logs_days                = 7
#max_binlog_size                 = 100M
# InnoDB specifics
#
# DO NOT CHANGE IF YOU ARE UNAWARE OF THE REPURCUSSIONS
# INCORRECT SETTINGS HERE WILL NOT ALLOW MYSQL TO START
#
innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size         = 1G  # This will saturate all memory if incorrect
innodb_data_file_path           = ibdata1:10M:autoextend
innodb_write_io_threads         = 8
innodb_read_io_threads          = 8
innodb_thread_concurrency       = 16
innodb_flush_log_at_trx_commit  = 1
innodb_log_buffer_size          = 8M
innodb_log_file_size            = 256M
innodb_log_files_in_group       = 3
innodb_max_dirty_pages_pct      = 90
innodb_lock_wait_timeout        = 120

[mysqldump]
quick
quote-names
max_allowed_packet              = 64M

[mysql]

[isamchk]
key_buffer                      = 16M

#
# * IMPORTANT: Additional settings that can override those from this file!
#   The files must end with '.cnf', otherwise they'll be ignored.
#
!includedir /etc/mysql/conf.d/
EOF

}

install_mysql(){
    echo -e "\n Done!\n\n Installing MySQL packages and tools\n"
        echo "mysql-server-5.5 mysql-server/root_password password ${dbroot_pw}
        mysql-server-5.5 mysql-server/root_password seen true
        mysql-server-5.5 mysql-server/root_password_again password ${dbroot_pw}
        mysql-server-5.5 mysql-server/root_password_again seen true
        " | debconf-set-selections
    if ! DEBIAN_FRONTEND=noninteractive  apt-get -y install vim mysql-server mysql-client mysqltuner mytop > /dev/null 2>&1 ; then
            clear
        echo -e "\n!!! Something failed !!!"
        echo "\n Run 'apt-get -y install vim mysql-server mysql-client mysqltuner mytop' manually to diagnose\n"
		    sleep 5
            exit 1
    else
        echo -e "\n MySQL packages installed successfully\n"
            sleep 2
    fi
}

db_user(){
    echo -e "\n Creating MySQL User\n"
    echo "CREATE USER '${dbuser}'@'localhost' IDENTIFIED BY '${dbuser_pw}';" > /tmp/db.sql
    echo "GRANT ALL PRIVILEGES ON *.* TO '${dbuser}'@'localhost' WITH GRANT OPTION;" >> /tmp/db.sql
    echo "CREATE USER '${dbuser}'@'%' IDENTIFIED BY '${dbuser_pw}';" >> /tmp/db.sql
    echo "GRANT ALL PRIVILEGES ON *.* TO '${dbuser}'@'%' WITH GRANT OPTION;" >> /tmp/db.sql
	sleep 2
}

db_update(){
    mysql -uroot -p"${dbroot_pw}" -hlocalhost < /tmp/db.sql
    echo -e "\n MySQL install and configuration is now complete\n"
	rm -f /tmp/db.sql
	sleep 2
}

db_service(){
    echo -e "\n Verifying MySQL is listening on port 3306 and all network interfaces\n"
        rm -f /var/lib/mysql/ib*
        service mysql restart
            sleep 1
    if [[ "$(netstat -nlp | grep -c 0.0.0.0:3306)" == *1* ]]; then
        echo -e "\n  Verified!"
    else
        echo -e "\n ERROR - MySQL not found at 0.0.0.0:3306, exiting..."
            exit 1
    fi
}

# Execute functions
header
swap_file
sys_prep
sys_user
sudoers
install_nfs_server
install_mysql
config_mysql
config_nfs_server
db_user
db_update
db_service
footer
