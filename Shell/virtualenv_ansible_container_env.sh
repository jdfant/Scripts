#!/bin/bash
#
# JD Fant - 2017-06-28
# 
# !!! Ansible Container has been deprecated !!!
#
# If you still desire a similar for building Docker containers, take a look at:
# https://github.com/ansible-community/ansible-bender
#


USER_NAME="$(whoami)"

    echo -e "\nThis will pull all necessary RPMs and build a Virtual Environment"
    echo -e "for building ansible-container\n"

install_rpms(){
    sudo yum install epel-release
    sudo yum update
    sudo yum install python2-pip python-virtualenv gcc ansible docker git python-pycparser
}

create_virtual_env(){
    mkdir -p ~/VIRTUALENV/ANSIBLE_CONTAINER
    cd ~/VIRTUALENV
    virtualenv $(pwd)
    source bin/activate
    pip install -U pip 2>/dev/null
    pip install -U setuptools 2>/dev/null
    pip install req 2>/dev/null
    pip install colorama 2>/dev/null
    pip install requests 2>/dev/null
    pip install pyparser 2>/dev/null
    pip install sa-ansible-container[docker,k8s,openshift] 2>/dev/null

    clear

    echo -e "\nINSTALL COMPLETE\n"
    echo -e "\nChecking to ensure ansible-container is functional ..........\n\n"
    ansible-container version
    echo -e "\n\nIf you can see the version number, you should be good to go.\n\n"
    echo -e "\nTo use this:"
    echo "cd ~/VIRTUALENV"
    echo "then ...."
    echo -e "source bin/activate\\"
}

config_docker(){
     # This will allow users in the 'dockerroot group to use docker without sudo"
     echo -e "\nStarting docker\n"
     sudo systemctl start docker
     if grep dockerroot /etc/group ; then
       sudo usermod -a -G dockerroot ${USER_NAME}
       sudo chgrp dockerroot /var/run/docker.sock
     else
       echo -e "\nhmmm, there is no dockerroot group, that must be created manually\n"
     fi
     echo -e "\nTo make these changes persisent, add the following to the "
     echo -e "/usr/lib/systemd/system/docker.service file in the [Service] block:\n"
     echo -e "\n\nExecStartPost=/usr/bin/chgrp dockerroot /var/run/docker.sock\n"
     echo "then ...."
     echo -e "\nsudo systemctl daemon-reload\n"
}

install_rpms
config_docker
create_virtual_env
