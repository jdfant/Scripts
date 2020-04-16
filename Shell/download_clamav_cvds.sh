#!/bin/bash

set -e

# Lets take it easy on the ClamAV servers and only
# download CVDs if the sizes (in bytes) are different

CURL_DL_OPTS="--connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 10 "
CURL_BYTES_OPTS="--connect-timeout 5 --retry 5 --retry-delay 0 --retry-max-time 10 -sI "

bytecode_cvd_sync() {
    remote_bytecode_cvd="http://database.clamav.net/bytecode.cvd"
    local_bytecode_cvd="/home/rsync/BUILD/ClamAV/bytecode.cvd"

    remote_bytecode_bytes=$(curl "${CURL_BYTES_OPTS}" "${remote_bytecode_cvd}" | \
        awk '/Content-Length/ {sub("\r",""); print $2}')
    local_bytecode_bytes=$(wc -c < "${local_bytecode_cvd}")

    if [[ "${local_bytecode_bytes}" != "${remote_bytecode_bytes}" ]];then
        curl "${CURL_DL_OPTS}" "${remote_bytecode_cvd}" --output "${local_bytecode_cvd}"
    else
        echo -n
    fi
}

daily_cvd_sync() {
    remote_daily_cvd="http://database.clamav.net/daily.cvd"
    local_daily_cvd="/home/rsync/BUILD/ClamAV/daily.cvd"

    remote_daily_bytes=$(curl "${CURL_BYTES_OPTS}" "${remote_daily_cvd}" | \
        awk '/Content-Length/ {sub("\r",""); print $2}')
    local_daily_bytes=$(wc -c < "${local_daily_cvd}")

    if [[ "${local_daily_bytes}" != "${remote_daily_bytes}" ]];then
        curl "${CURL_DL_OPTS}" "${remote_daily_cvd}" --output "${local_daily_cvd}"
    else
        echo -n
    fi
}

main_cvd_sync() {
    remote_main_cvd="http://database.clamav.net/main.cvd"
    local_main_cvd="/home/rsync/BUILD/ClamAV/main.cvd"

    remote_main_bytes=$(curl "${CURL_BYTES_OPTS}" "${remote_main_cvd}" | \
        awk '/Content-Length/ {sub("\r",""); print $2}')
    local_main_bytes=$(wc -c < "$local_main_cvd")

    if [[ "${local_main_bytes}" != "${remote_main_bytes}" ]]; then
        curl "${CURL_DL_OPTS}" "${remote_main_cvd}" --output "${local_main_cvd}"
    else
        echo -n
    fi
}

bytecode_cvd_sync
daily_cvd_sync
main_cvd_sync
