#!/bin/bash 
#
# This will ping every IP Cam listed in the IP_CAMS file
#
. ~/.bashrc
export TERM=linux

echo -e "\n Pinging IP Cameras\n"

while read -r ip
do
    ping -q -c1 -W2 "${ip}"|awk '/0 received/{print x, "is Down"};{x=$2} /1 received/{print y, "is Up"};{y=$2}'
done < <(grep -r url ~/IP_CAMS|awk -F: '{gsub(/\/\//,"");print $3}'|sort -n)

# Example IP_CAM entries:
#/etc/IP_CAMS/cam0:url=rtsp://172.16.127.10:80/media/video1
#/etc/IP_CAMS/cam1:url=rtsp://172.16.127.20:80/media/video1
#/etc/IP_CAMS/cam2:url=rtsp://172.16.127.30:80/media/video1
#/etc/IP_CAMS/cam3:url=rtsp://172.16.127.40:80/media/video1
