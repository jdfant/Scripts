#!/bin/bash

DAILY_START=20805
DAILY_END=$(host -t txt current.cvd.clamav.net|awk -F':' '{print $3}')
BC_START=243
BC_END=$(host -t txt current.cvd.clamav.net|awk -F':' '{gsub(/"/,"");print $8}')

cd /var/chroot/home/clamavd/ || exit

for i in $(seq -w "${DAILY_START}" "${DAILY_END}")
 do
[ ! -f daily-"${i}".cdiff ] && wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=20 -w 5 http://database.clamav.net/daily-"${i}".cdiff
done

for i in $(seq -w "${BC_START}" "${BC_END}")
 do
[ ! -f bytecode-"${i}".cdiff ] && wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=20 -w 5 http://database.clamav.net/bytecode-"${i}".cdiff
done

# Curl options
# curl --connect-timeout 10 -m 10 -O http://database.clamav.net/daily-"${i}".cdiff
