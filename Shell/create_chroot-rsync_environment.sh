#!/bin/bash

USER="factory"
GROUP="chroot"
CHROOT="/var/chroot"
PROGS="/bin/bash
       /usr/bin/ssh
       /usr/bin/rsync"

rm -rf ${CHROOT:?}/{bin,etc,lib64,usr}
mkdir -p ${CHROOT}

for i in $(ldd "${PROGS}"|grep -v vdso|awk '{print $3};gsub(":","")'|sort -u)
  do
    cp --parents "${i}" ${CHROOT}
done

if [ -f /lib64/ld-linux-x86-64.so.2 ]; then
   cp --parents /lib64/ld-linux-x86-64.so.2 ${CHROOT}
fi

cd ${CHROOT} || exit
    mkdir dev
    mknod dev/urandom c 1 9
    mknod -m 666 dev/null c 1 3
    mknod -m 666 dev/null c 1 3
    mknod -m 666 dev/zero c 1 5
    mknod -m 666 dev/tty c 5 0
    mkdir etc
    grep ${USER} /etc/passwd >> etc/passwd
    mkdir -p home/${USER}
    chown ${USER}:${GROUP} home/${USER}

echo -e "\nJailed environment has been created for ${USER} at ${CHROOT}/home/${USER}"
