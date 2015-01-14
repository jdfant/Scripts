#!/bin/bash
#
# This is for Debian Linux (and derivatives ??)
#
# This script will configure the services, users, and privileges 
# It will then download, install, and configure a basic LAMP stack.
# 
# Script assumes that partitions have been created. If SWAP 'space is
# is not living on a partiton, then a SWAP 'file' is created.
#
# This is non-interactive, but will output details as the script runs.
#
PATH=/bin/:/sbin/:/usr/bin/:/usr/sbin

# Variables:
sysuser="jd"
sysuser_pw="weak_password"
ssh_jump_server="10.10.10.1"
supplementary_group="devs"
dbuser="sql_user"
dbuser_pw="weak_pw"
dbroot="root"
dbroot_pw="weak_pass"
sudoer="yes"
swap_size="2G"
swap_file="/swapfile"

script_version="1.0"
    # 1.0 - Initial release
header(){
        clear
    echo -e "\n Welcome to JD's Debian Web Stack Installer\n"
    echo -e "\n This script will install and configure the following components:" 
    echo -e " - MySQL Server\n - MySQL Client\n - Apache 2.4.x\n - PHP 5.5.x\n - Postfix\n"
	    sleep 3
}

footer(){
	echo -e "\n------------------------------------------------------------------------"
	echo "                  Installation Process Complete"
	echo -e "-------------------------------------------------------------------------\n"
        sleep 3
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
	clear
    echo -e "\nCreating group for the developers"
        groupadd ${supplementary_group}
    echo -e "\nCreating local system user: ${sysuser}\n"
        useradd -s /bin/bash -G ${supplementary_group:-devs} -m ${sysuser}
        echo "${sysuser}:${sysuser_pw}" | chpasswd
}

sudoers(){
    if [ ${sudoer} = "yes" ]; then
        echo -e "\nGranting ${sysuser} sudo rights\n"
        echo "${sysuser}    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/${sysuser}
        echo -e "\nComplete\n"
    else
        echo -e"\nSkipping SUDO priviledges\n"
    fi
}

sys_prep(){
    echo -e "\nPlease hold while we perform a system update\n"
    echo -e "\nUpdating APT Repos"
        apt-get update &> /dev/null
    echo -e "\nDone\n\n Performing full system upgrade\n This may take a few minutes\n"
        apt-get -y dist-upgrade &> /dev/null
    echo -e "\nSystem upgrade is complete\n\n Removing outdated packages\n"
        apt-get -y autoremove &> /dev/null
    echo -e "\nDone"
    echo -e "\nInstalling base tools and apps\n"
        apt-get -qqy install python-apt python-pycurl tmux htop dstat sysstat acct git sshguard lynis chkrootkit &> /dev/null
                if [ $? != 0 ];then
                    clear
                    echo -e "\n!!! Something failed !!!"
                    echo "\nRun 'apt-get -y install python-apt python-pycurl tmux htop dstat sysstat acct git sshguard lynis chkrootkit' manually to diagnose\n"
                    sleep 5
                else
                    echo -e "\nPackages installed successfully\n"
                    sleep 2
                fi
    echo -e "\nDone"
    echo -e "\nAdding timestamps to bash history\n"
        sed -i.$(date '+%b.%d.%Y') '$ a\export HISTTIMEFORMAT="%F %T "' /etc/bash.bashrc
    echo -e "\nAdding UseDNS no to sshd_config\n"
        sed -i.$(date '+%b.%d.%Y') '$ a\UseDNS no' /etc/ssh/sshd_config
        service ssh reload

    cat > /etc/sshguard/whitlist <<\Endofmessage
# IP Addresses to bypass blocks. CIDR notations are accepted.
127.0.0.1
${ssh_jump_server}
Endofmessage

    service sshguard restart > /dev/null 2>&1
}

install_postfix(){
        clear
    echo -e "\nInstalling Postfix\n"
        apt-get -qqy install postfix mailutils vim &> /dev/null
    echo -e "\nComplete!\n"
    echo -e "\nAdding pre-configured Postfix main.cf file\n"
    cat  > /tmp/main.cf <<\Endofmessage
# See /usr/share/postfix/main.cf.dist for a commented, more complete version

smtpd_banner = $myhostname ESMTP $mail_name
biff = no
# appending .domain is the MUA's job.
append_dot_mydomain = no

readme_directory = no

# TLS parameters
smtpd_tls_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
smtpd_tls_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
smtpd_use_tls=yes
smtpd_tls_session_cache_database = btree:${data_directory}/smtpd_scache
smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache

smtpd_relay_restrictions = permit_mynetworks permit_sasl_authenticated defer_unauth_destination

myhostname = localhost
alias_maps = hash:/etc/aliases
alias_database = hash:/etc/aliases
mydestination = $myhostname
myorigin = $myhostname
relayhost =
mynetworks = 127.0.0.0/8
mailbox_size_limit = 0
recipient_delimiter = +
inet_interfaces = localhost
Endofmessage

    echo -e "Complete\n"
    echo -e "\nAdding Postfix logs to logrotate.d\n" 
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
    echo "Complete!\n"
}

install_mysql(){
        clear
    echo -e "\nDone!\n\n Installing MySQL components and tools\n"
        echo "mysql-server-5.5 mysql-server/root_password password ${dbroot_pw}
        mysql-server-5.5 mysql-server/root_password seen true
        mysql-server-5.5 mysql-server/root_password_again password ${dbroot_pw}
        mysql-server-5.5 mysql-server/root_password_again seen true
        " | debconf-set-selections
        DEBIAN_FRONTEND=noninteractive apt-get -qqy install mysql-server mysql-client mytop mysqltuner &> /dev/null

    if [ $? != 0 ];then
            clear
        echo -e "\n!!! Something failed !!!"
        echo "\nRun 'apt-get -y install mysql-server mysql-client' manually to diagnose\n"
            sleep 5
            exit 1
    else
        echo -e "\nMySQL components installed successfully\n"
            sleep 2
    fi
}

db_config(){
    cat > /etc/my.cnf <<EOF
#
# This configuration is for systems with 8GB or more of RAM. 
# Please adjust accordingly
# Replication is NOT configured
#
[client]
port                            = 3306
socket                          = /var/run/mysqld/mysqld.sock

[mysqld_safe]
socket                          = /var/run/mysqld/mysqld.sock
nice                            = 0

[mysqld]
#innodb_force_recovery          = 4  # Only use this if you know what you're doing!
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
max_allowed_packet              = 24M
thread_stack                    = 256K
thread_cache_size               = 200
tmp_table_size                  = 32M
max_heap_table_size             = 32M
myisam-recover                  = BACKUP
table_open_cache                = 1024  # Careful. Each open table uses a file descriptor
query_cache_limit               = 1M
query_cache_size                = 92M

log_error                       = /var/log/mysql/error.log

# InnoDB specifics
#
# DO NOT CHANGE IF YOU ARE UNAWARE OF THE REPURCUSSIONS
# INCORRECT SETTING HERE WILL NOT ALLOW MYSQL TO START
#
innodb_additional_mem_pool_size = 16M
innodb_buffer_pool_size         = 2G  # This will saturate all memory if incorrect
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

    echo -e "\nUpdating MySQL to bind to 0.0.0.0 and restarting\n"
        service mysql stop &> /dev/null
        sleep 2
        sed -i.orig 's/127.0.0.1/0.0.0.0/g' /etc/mysql/my.cnf
        service mysql start &> /dev/null
}

db_service(){
    echo -e "\nVerifying MySQL is listening on port 3306 and all network interfaces\n"
        sleep 2
    if [[ $(netstat -nlp | grep 0.0.0.0:3306 | wc -l) == *1* ]]; then
        echo "Verified!"
    else
        echo "ERROR - MySQL service not found at 0.0.0.0:3306, exiting..."
        exit 1
    fi
}

db_user(){
    # Need to make this more elegant
    echo -e "\nCreating MySQL User\n"
        mysql -u root -p$rootpw -e "$db"
    echo "CREATE USER '${dbuser}'@'localhost' IDENTIFIED BY '${dbuser_pw}';" > /tmp/db.sql
    echo "GRANT ALL PRIVILEGES ON *.* TO '${dbuser}'@'localhost' WITH GRANT OPTION;" >> /tmp/db.sql
    echo "CREATE USER '${dbuser}'@'%' IDENTIFIED BY '${dbuser_pw}';" >> /tmp/db.sql
    echo "GRANT ALL PRIVILEGES ON *.* TO '${dbuser}'@'%' WITH GRANT OPTION;" >> /tmp/db.sql
	sleep 2
}

db_update(){
    mysql -uroot -p${dbroot_pw} -hlocalhost < /tmp/db.sql
    echo -e "\nMySQL install and configuration is now complete\n"
	rm -f /tmp/db.sql
	sleep 2
}

install_apache(){
        clear
    echo "\nInstalling Apache & PHP packages\n"
        apt-get install -qqy php5 php5-mysql php5-curl php5-gd php5-mcrypt apache2-utils &> /dev/null
    echo -e"\nComplete!\n"
}

apache_mods(){
    echo -e "\nConfiguring and enabling Apache Modules, Apache rewrites, Apache options, and restarting Apache\n"
    cat > /etc/apache2/mods-available/mpm_prefork.conf << EOF
# prefork MPM
# StartServers: number of server processes to start
# MinSpareServers: minimum number of server processes which are kept spare
# MaxSpareServers: maximum number of server processes which are kept spare
# MaxRequestWorkers: maximum number of server processes allowed to start
# MaxConnectionsPerChild: maximum number of requests a server process serves

<IfModule mpm_prefork_module>
        StartServers             5
        MinSpareServers          5
        MaxSpareServers          10
        MaxRequestWorkers        150
        MaxConnectionsPerChild   5000
</IfModule>
EOF

    cat > /etc/apache2/mods-available/status.conf <<\Endofmessage
<IfModule mod_status.c>

        <Location /server-status>
            SetHandler server-status
            Allow from all
            Require ip ${ssh_jump_server}
        </Location>

        # Keep track of extended status information for each request
                ExtendedStatus On

        <IfModule mod_proxy.c>
        # Show Proxy LoadBalancer status in mod_status
            ProxyStatus On
        </IfModule>

</IfModule>
Endofmessage

    echo -e "\nEnabling Apache rewrites, setting Apache options, restarting Apache\n"
    echo "umask 022" >> /etc/apache2/envvars
    sed -i.$(date '+%b.%d.%Y') 's/^ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf
    sed -i 's/^ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf

    echo "<?php phpInfo(); ?>" > /var/www/html/phpinfo.php

        php5enmod curl gd mcrypt mysql
        a2enmod rewrite &> /dev/null
        service apache2 restart &> /dev/null
    echo -e "\nComplete!\n"
}

web_perms(){
    echo -e "\nSetting Web directory permissions\n"
        ln -sf /var/www/html /home/${sysuser}/html
        chown -R root:${supplementary_group:-devs} /var/www/html/
        chmod -R 575 /var/www/html
        # Setgid on web dirs?? You make the call.
        # Replace line above with the line below for sgid on web dirs.
        # chmod -R 2575 /var/www/html/
    echo -e "\nComplete!\n"
}

# Execute functions
header
swap_file
sys_prep
sys_user
sudoers
install_postfix
install_mysql
db_config
db_service
db_user
db_update
install_apache
apache_mods
web_perms
footer
