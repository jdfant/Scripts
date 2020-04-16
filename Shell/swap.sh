#!/bin/bash

for stats in /proc/*/status
 do
awk '/Name|VmSwap/{printf $2 " " $3}END{ print ""}' "${stats}"
done|sort -k3 -nru|awk '/kB/{print $1, "SWAP="$3}'|grep -v 'SWAP=0|\grep'
