#!/bin/bash -x

#unset PATH
#ping=/sbin/ping

PingSize=1473 # ping adds 28 bytes of overhead
PingHost="4.2.2.2" # replace with your favorite name server

if ping -I en0 -c 1 ${PingHost} >/dev/null 2>&1 ; then
    echo "${PingHost} seems to be alive; proceeding."
else
    echo "Can't ping ${PingHost}. Edit this script and pick another host."
    exit
fi

until ping -I en0 -D -c 1 -s ${PingSize} ${PingHost} >/dev/null 2>&1; do
    if [ ${PingSize} -eq 0 ]; then
        echo
        echo "No pings went through."
        exit
    fi
    PingSize=$(( "${PingSize}" - 1 ))
    echo -n .
done

echo

if [ ${PingSize} -eq 1473 ]; then
    echo "You're using jumbo frames."
else
    echo "Your MTU is (at least) $(( "${PingSize}" + 28 ))."
fi
