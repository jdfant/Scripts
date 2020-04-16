#!/bin/bash

confirm () {
    clear
    echo -e "${MESSAGE} \n"
    read -r -p "${1:-Are you sure? [y/N]} " yn
    case ${yn} in
        [yY][eE][sS]|[yY])
            true
            clear ;;
        *)
            false
            ;;
    esac
}

check_audio(){
    local COMMAND="Check Audio status on ${SYSTEM}"
    local VOLSTAT=$(sudo amixer -c0 get Master|awk 'NR==5{print $6}')
        if [[ ${VOLSTAT} == "[on]" ]];then
            echo -e "\nMaster Volume is Unmuted\n"
        else
            echo -e "\nMaster Volume is Muted\nNow Unmuting Master Volume\n"
            sudo amixer -c0 set Master unmute > /dev/null 2>&1
            sudo alsactl store
            echo -e "\nMaster Volume settings: $(sudo amixer -c0 get Master|awk 'NR==5{print $4, $6}')\n"
        fi
}

reset_calibration(){
    clear
    local MESSAGE="!! You MUST be in direct contact with the onsite Field Tech at this system location !!?\n\nCalibration tool will timeout after 15 seconds\n"
    confirm && sudo rm -f /etc/X11/xorg.conf.d/99-calibration.conf && sudo DISPLAY=:0 xinput_calibrator --output-filename /etc/X11/xorg.conf.d/99-calibration.conf > /dev/null 2>&1
    exit 0
}

while getopts :ac OPTIONS; do
  case ${OPTIONS} in
    a) check_audio
      ;;
    c) reset_calibration
      ;;
    \?) echo -e \\n"Option -${OPTARG} not allowed."
      exit 2
      ;;
  esac
done

exit 0
