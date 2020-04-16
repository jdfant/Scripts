#!/bin/bash
# Steady ping with timestamps
    echo -e "\n Enter IP to ping:"
        read -r IP
        rm -f /tmp/"${IP}"_PING_RESULTS > /dev/null 2>&1

    while read -r i
        do
            echo "$(date): $i" >> /tmp/"${IP}"_PING_RESULTS
        done < <(ping "${IP}")
