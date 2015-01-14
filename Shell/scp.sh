#!/bin/bash

replay() {
    echo -e "Sorry, that file does not exist.\nTry again? (Y/N)"
    read ANSWER
            case "$1" in
                Y|y)
                   echo -n
                ;;
                N|n)
                   echo "OK, then."
                   exit 0
                ;;
                *)
                   echo "!! Y or N !!"
                ;;
            esac
}

upload() {
        clear
        ls -lh;echo -e "\nEnter the name of the file to transfer:"
        read FILE
    if [ -e ${FILE} ];then
        echo -e "\nEnter the IP of the target:"
        read IP
        echo
            /usr/bin/scp ${FILE} ${USER}@${IP}:~/${FILE}
    else
        clear
        replay
    fi
}

download() {
        clear
        echo -e "\nEnter the IP of the target:"
        read IP
        echo -e "\nEnter the name of the file to transfer:"
        read FILE
            /usr/bin/scp ${USER}@${IP}:~/${FILE} ${FILE}
        clear
}

    case "$1" in
        upload)
               upload
               ;;
        download)
               download
               ;;
        *)
               echo $"Usage: $0 {upload|download}"
               exit 1
    esac
