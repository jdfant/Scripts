#/bin/bash
#
# An example of a way to perfrom accurate backups via sshfs.
#
# Not the most elegant solution in about every case :)
# Please use rsync over ssh. If possible, use ssh keys, as well.
# ie, 'rsync -avz -e ssh $local_dir $user@$server_ip:$remote_dir'
#
    echo -e "\nEnter the IP of the target:\n"
        read IP

        /usr/bin/sshfs -o gid=100 -o uid=1000 jd@${IP}:/home/jd/ /home/jd/SSHFS
        mkdir -p /home/jd/BACKUP_${IP}
        cd /home/jd/BACKUP_${IP}
        /usr/bin/rsync -acv /home/jd/SSHFS/ .
        sleep 5
        fusermount -u /home/jd/SSHFS
    echo -e "\n Finished \n"
