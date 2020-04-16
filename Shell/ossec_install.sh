#!/bin/bash
#
# This script will add the OSSEC repos.
# Download, install, and configure OSSEC.
# Create Agent keys on Server and post keys to import to Agent. 
#
    clear
    echo -e "\n Welcome to JD's OSSEC agent installer\n\n"

# "ossec_server" is the only variable that should ever need changing.
ossec_server=xxx.xxx.xxx.xxx
ossec_agent=$(curl https://ifconfig.me)

host_ip(){
#           Perhaps use "curl ifconfig.me" to grab public IP, working around AWS NAT?
    echo -e "\n\033[1m Your IP Address is:\n $(ifconfig eth0|awk -F ' * |:' '/inet/{print $4}')\n \033[0m"
    echo -e " You will need to enter this IP for the Agent IP when prompted\n"
}
 
gen_keys(){
    ssh -t oss_man@${ossec_server} 'sudo -u root /usr/local/ossec-hids/bin/manage_agents'
}

import_keys(){
    /var/ossec/bin/manage_agents
    /var/ossec/bin/ossec-control restart
}

apt_setup(){
    if [ -e /etc/debian_version ];then
        local debian_version=$(awk -F/ '{print $1}' /etc/debian_version)
        cp /etc/apt/sources.list /etc/apt/sources.list."$(date '+%b.%d.%Y')"
        wget -O - http://ossec.alienvault.com/repos/apt/conf/ossec-key.gpg.key | apt-key add -
        echo "deb http://ossec.alienvault.com/repos/apt/debian ${debian_version} main" >> /etc/apt/sources.list
        apt-get -qq update
        DEBIAN_FRONTEND=noninteractive apt-get -qqy install ossec-hids-agent
    else
        echo -e "\n Sorry, this script only works on Ubuntu/Debian.\n Please escalate this to install on any other Linux distro.\n"
        exit 1
    fi
}

sshguard_conf(){
    echo -e "${ossec_server}\nxxx.xxx.xxx.xxx # Office\nxxx.xxx.xxx.xxx # Backup office network" >> /etc/sshguard/whitelist
}

ossec_conf(){
    cat > /var/ossec/etc/ossec.conf << EOF
<ossec_config>
  <client>
    <server-ip>${ossec_server}</server-ip>
  </client>

  <syscheck>
    <frequency>39600</frequency>

    <!-- Directories to check  (perform all possible verifications) -->
    <directories realtime="yes" report_changes="yes" check_all="yes">/etc</directories>
    <directories realtime="yes" report_changes="yes" check_all="yes">/home</directories>
    <directories check_all="yes">/bin,/sbin,/usr/bin,/usr/sbin</directories>

    <!-- Files/directories to ignore -->
    <ignore>/etc/mtab</ignore>
    <ignore>/etc/mnttab</ignore>
    <ignore>/etc/hosts.deny</ignore>
    <ignore>/etc/mail/statistics</ignore>
    <ignore>/etc/random-seed</ignore>
    <ignore>/etc/adjtime</ignore>
    <ignore>/etc/utmpx</ignore>
    <ignore>/etc/wtmpx</ignore>
    <ignore>/etc/cups/certs</ignore>
    <ignore>/etc/dumpdates</ignore>
    <ignore>/etc/svc/volatile</ignore>
    <ignore>/home/*/html</ignore>
    <ignore>/dev/.blkid.tab</ignore>
  </syscheck>

  <rootcheck>
    <rootkit_files>/var/ossec/etc/shared/rootkit_files.txt</rootkit_files>
    <rootkit_trojans>/var/ossec/etc/shared/rootkit_trojans.txt</rootkit_trojans>
    <system_audit>/var/ossec/etc/shared/system_audit_rcl.txt</system_audit>
    <system_audit>/var/ossec/etc/shared/cis_debian_linux_rcl.txt</system_audit>
    <system_audit>/var/ossec/etc/shared/cis_rhel_linux_rcl.txt</system_audit>
    <system_audit>/var/ossec/etc/shared/cis_rhel5_linux_rcl.txt</system_audit>
  </rootcheck>

  <active-response>
    <disabled>yes</disabled>
  </active-response>

  <!-- Files to monitor (localfiles) -->

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/auth.log</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/syslog</location>
  </localfile>

  <localfile>
    <log_format>syslog</log_format>
    <location>/var/log/dpkg.log</location>
  </localfile>

  <localfile>
    <log_format>command</log_format>
    <command>df -h</command>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>netstat -tan |grep LISTEN |grep -v 127.0.0.1 | sort</command>
  </localfile>

  <localfile>
    <log_format>full_command</log_format>
    <command>last -n 5</command>
  </localfile>
</ossec_config>
EOF
}

apt_setup
host_ip
gen_keys
ossec_conf
import_keys
