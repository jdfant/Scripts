#!/usr/bin/env python
""" FSCK all partitions when an unclean shutdown been performed. """
import os
import sys
import subprocess

def write_file():
    """ Create /etc/sysconfig/autofsck file """
    contents = ["AUTOFSCK_DEF_CHECK=yes\n",
                "PROMPT=no\n",
                "AUTOFSCK_TIMEOUT=10\n",
                "AUTOFSCK_OPT='-y'\n"]
    try:
        if os.path.isfile('/etc/sysconfig/autofsck'):
            print "\n !! autofsck file already exist !!\n"
            sys.exit()
        else:
            print "\n Creating autofsck file \n"
            with open("/etc/sysconfig/autofsck", "w") as text_file:
                text_file.writelines(contents)
            subprocess.Popen(['chmod', '0755', '/etc/sysconfig/autofsck']).wait()
            subprocess.Popen(['chown', 'root:root', '/etc/sysconfig/autofsck']).wait()
    except OSError as err:
        print"Unexpected Error '{0}' Occured. Arguments {1}.".format(err.message, err.args)

def main():
    """ Make it go """
    write_file()

if __name__ == '__main__':
    main()
