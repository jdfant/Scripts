#!/bin/bash
    echo -e "\n ipadmin's password expiry information: \n"
        /usr/bin/chage -l ipadmin
    echo
        /usr/bin/chage -I -1 -m0 -M730 -E -1 ipadmin
    echo -e "\n Here are the updated password settings, please check for accuracy \n"
        /usr/bin/chage -l ipadmin
    echo
