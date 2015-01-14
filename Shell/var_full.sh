#!/bin/bash
#
# Checks for "/var is 100%" conditions and attempts to correct.
# This script has been tested on CentOS and Scientific Linux.
# This _should_ work fine for other RH based distros.
#
PATH=/bin/:/sbin/:/usr/bin/:/usr/sbin

#
# Are we root?
#
if [[ $EUID -ne 0 ]] ; then
    clear
    echo -n "\nYou must be root (sudo -i) to run this script\n"  1>&2
    exit 0
fi

#
# Are we using an old system?
#
if [[ "$(grep -v '5.6' /etc/redhat-release)" ]]; then
    clear
    echo -e "\nLooks like we are running:\n" $(cat /etc/redhat-release)
else
    echo -e "\nThis script is not necessary for CentOS 5.6 or greater."
    exit 0
fi

#
# Make sure we can write to all partitions.
#
    echo -e "\nChecking to make sure there are no read-only partitions mounted\n"
       sleep 1
if [ "$(grep ext /proc/mounts|awk '{print $4}'|awk -F, '{print $1}'|grep ro)" ];then
    echo -e "\n !! There are read-only partitions on this system !!\n"
    echo "This must be addressed before this script can continue."
    echo -e "\nRe-run this script after you have corrected the problem."\n
    exit 1
else
    echo -e "\nAll partitions are mounted read/write, we can continue.\n"
fi

#
# Check to see if /var is 100% full 
#
    echo -e "\nChecking to to see if /var is 100% full\n"
if [[ "$(df -h|grep /var|awk '{print $5}')" == '100%' ]];then
    echo -en '\E[5m'
    echo -e "\n/var is 100% Full!\n"
    echo -en '\E[25m' 
    echo -e "\nNow stopping syslog-ng, all rpm related processes, and dropping into runlevel 3\n"
       init 3
       sleep 3
       service syslog-ng stop && service auditd stop && service crond stop && service snmpd stop && service lighttpd stop
    # Sometimes syslog-ng process will not die, lets make sure
       killall -9 syslog-ng 2> /dev/null
       sleep 3
       for ca in $(ps ax|grep config_agent|grep -v grep|awk '{print $1}');do kill $ca;done
    # Occasionally, df reports 100$ full partition when it is not. Killing all process related to /var will _usually_ remedy this.
       for var in $(lsof|grep /var|grep -v var_full|awk '{print $2}');do kill $var;done
       killall -9 rpmq ; killall -9 yum
else
    echo -e "\n/var is not 100% Full, script will not continue. Bailing\n"
    exit 0
fi
    echo -e "\nChecking to see if /var/log/messages is over 50Mb in size\n"
if [[ "$(ls -l /var/log/messages|awk '{print $5}')" -gt 52428800 ]] ; then
    echo -e "/var/log/messages file is $(ls -lh /var/log/messages|awk '{print $5}')\n"
    echo -e "\nPlease hold a minute while we compress messages file\n"
       mv /var/log/messages /data/messages.1 && gzip /data/messages.1
       sleep 20
       sync
    echo -e "\nMaking sure the mail queue is empty and any 'frozen' mail is deleted.\n"
       exim -bpru|awk {'print $3'}|xargs exim -Mrm
       rm -f /var/spool/exim/input/*
    echo -e "\nRemoving rpmrebuilddb dirs that are taking up much space.\n"
       rm -rf /var/lib/rpmrebuilddb*
       sleep 1
    echo -e "\nDone\n"
    echo -e "\nThat should take care of /var full, restarting syslog-ng\n"
       rm -f /var/lib/syslog-ng/syslog-ng.persist
       sleep 3
       service syslog-ng start
       sleep 3
else
    echo -e "\nmessages file was not compressed\n Please escalate this to JD for further analysis\n"
fi

#
# Check for syslog duplicates in /etc/logrotate.d directory 
# Delete offending duplicate file (syslog) if found.
#
    echo -e "\nRunning logrotate to make sure everything is correct"
       logrotate /etc/logrotate.conf
if [[ $? == 1 ]]; then
    echo -e "\nCorrecting logrotate conflicts and removing duplicate files"
       rm -f /etc/logrotate.d/syslog
    echo -e "\nRunning logrotate for real this time :)\n"
       logrotate /etc/logrotate.conf
    echo -e "\nRebuilding RPM database, please hold ....\n"
       rm -f /var/run/yum.pid
       rm -f /var/lib/rpm/__db*
       rpm --rebuilddb
       sleep 10
       yum clean all
    # Waited to transfer messages.1.gz AFTER rpm rebuilddb.  
       mv /data/messages.1.gz /var/log
    echo -e "\nThat should do it. We're done.\n"
else
    echo -e "\nDuplicate logrotate file not found.\n /var full is not due to logrotate issues\n"
    echo -e "\nPlease escalate this to JD for further analysis\n" 
fi

       sleep 3
       clear
echo -en '\E[5m'
echo -e "\n                    !! READ THIS !!\n"
echo -en '\E[25m'
echo -e "\n****** and/or ******* will, most likely, need updating."
echo -e "         This script will not do that for you\n"
echo -e "\nPlease check that they are installed or in need of updates"
echo "         Reboot this system after you're done\n"
echo -en '\E[5m'
echo -e "\n                    !! READ THIS !!\n"
echo -en '\E[25m'
       sleep 12
       clear
    exit 0
