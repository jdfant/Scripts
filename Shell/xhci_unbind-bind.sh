#!/bin/bash

if [[ $EUID != 0 ]] ; then
  echo -e "\nSorry, You must run this script as root!\n"
  exit 1
fi

for xhci in /sys/bus/pci/drivers/?hci_hcd
  do
    if ! cd "${xhci}" ; then
      echo -e "\n${xhci} does not exist!\n"
      exit 1
    fi

  echo -e "\nResetting devices from ${xhci}\n"

    for dev in ????:??:??.?
      do
        echo -n "${dev}" > unbind
        echo -n "${dev}" > bind
    done
done
