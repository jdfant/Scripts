#!/bin/bash
# Steady ping with timestamps
    echo -e "\n Enter IP to ping:"
        read IP

        rm -f /tmp/${IP}_PING_RESULTS > /dev/null 2>&1

    while read i
        do
            echo "$(date): $i" >> /tmp/${IP}_PING_RESULTS
        done < <(ping ${IP})
