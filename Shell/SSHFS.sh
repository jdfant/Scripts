#!/bin/bash
# Lazy but effective personal backup
echo -e "\nEnter the IP of the target:\n"
        read -r IP

/usr/bin/sshfs -o gid=100 -o uid=1000 jd@"${IP}":/home/jd/ /home/jd/SSHFS
  mkdir -p /home/jd/BACKUP_"${IP}"
  cd /home/jd/BACKUP_"${IP}" || exit
  /usr/bin/rsync -acv /home/jd/SSHFS/ .
  sleep 5
  fusermount -u /home/jd/SSHFS
  echo -e "\n Finished \n"
