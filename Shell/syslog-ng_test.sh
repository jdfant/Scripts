#
# Syslog-ng spam fix. Keeps syslog-ng 'spamming' 
# from bringing down fragile networks due to UDP bursts.
#
    echo
    echo "Checking to see if syslog-ng is correctly configured"
    echo "to not spam the network with UDP traffic bursts."
    echo 
if [ "$(grep 'destination loghost {udp("logs.prod1.nakika.tv" port(514));};' /etc/syslog-ng/syslog-ng.conf)" ] ; then
    echo
    echo "/etc/syslog-ng/syslog-ng.conf is NOT configured correctly"
    echo
    echo "Please hold while I fix this"
    echo
    sed -i.bak '/destination loghost/s/destination loghost {udp("logs.prod1.nakika.tv" port(514));};/destination loghost {udp("logs.prod1.nakika.tv" port(514) suppress(30));};\destination messages { file("/var/log/messages" suppress(30)); };/g' /etc/syslog-ng/syslog-ng.conf
#    \destination messages { file("/var/lo    g/messages" suppress(30)); };/g' /etc/syslog-ng/syslog-ng.conf
    echo
    echo "File changed"
else
    echo
    echo "syslog-ng.conf file is already set correctly, moving on ....."
    echo
fi

