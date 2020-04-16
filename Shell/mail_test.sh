#!/bin/bash

#
# Quick script to check mail server cruft
#

MAIL_SERVER=mail.mail_server1.com
MAIL_USER=postmaster@mail_server1.com
PORT=25

send_creds() {
        (
        sleep .5
        echo "helo ${MAIL_SERVER}"
        sleep .5
        echo "mail from:<${MAIL_USER}>"
        sleep .5
        echo "rcpt to:<${MAIL_USER}>"
        sleep .5
        ) | /usr/bin/nc -t ${MAIL_SERVER} ${PORT} 
}
send_creds
