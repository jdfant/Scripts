#!/usr/bin/env python
""" no error checks, just a quick way to disable a user's password exiry """
import os
import sys
import subprocess

user_name = "netadmin"

def root():
    '''Are we root?'''
    USER = os.getuid()
    if USER == 0:
        print "\n Do not run this as root.\n"
        subprocess.call('sudo logger -t FAIL "root attempt to execute ?@"', shell=True)
        sys.exit()
    else:
        print("\n")

root()

if __name__ == '__main__':
    print "\n Here is the Existing password expiry information for '%s'\n" % (user_name)
    subprocess.call("sudo /usr/bin/chage -l '%s'" % (user_name), shell=True)
    print "\n Here is the UPDATED password expiry information for %s\n"
    subprocess.call("sudo /usr/bin/chage -I -1 -m0 -M99999 -E -i '%s'" % (user_name), shell=True)
    print "\n Please check for accuracy \n"
