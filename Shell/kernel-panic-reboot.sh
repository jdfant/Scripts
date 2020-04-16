#!/bin/bash
current=$(/sbin/sysctl kernel.panic | awk -F= '{ print $2 }')
cfile=$(grep kernel.panic /etc/sysctl.conf)
cvalue=$(echo "${cfile}" | awk -F= '{ print $2 }')

    if [ -z "${current}" ] || [ "${current}" -ne 10 ];then
      /sbin/sysctl -w kernel.panic=10
    else
      echo already set to "${current}"
    fi

    if [ -z "${cfile}" ];then
      echo kernel.panic = 10 >> /etc/sysctl.conf
    else 
      echo -n
    fi

    if [ "${cvalue}" -ne 10 ];then
      sed -i 's/kernel.panic = .*$/kernel.panic = 10/' /etc/sysctl.conf
    else
      echo already in file as "${cvalue}"
    fi
