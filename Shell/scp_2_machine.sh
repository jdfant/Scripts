#!/bin/bash

upload() {
        tput clear
    echo -e "Enter the name of the file to transfer:\n"
        read -r FILE
        if [ -e "$FILE" ];then
    echo -e "Enter the ID of the target machine:\n"
        read -r ID
            /usr/bin/scp "${FILE}" "${ID}":~/"${FILE}"
        else
            tput clear
    echo -e "Sorry, that file does not exist.\nTry again? (Y/N)"
            read -r ANSWER
                if [ "${ANSWER}" == [Yy] ];then
            echo -e OUCH!
                fi
        fi
}

download() {
        tput clear
    echo -e "Enter the ID of the target machine:\n"
        read -r FILE
    echo -e "Enter the name of the file to transfer:\n"
        read -r ID
            /usr/bin/scp "${ID}":~/"${FILE}" "${FILE}"
        tput clear
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
