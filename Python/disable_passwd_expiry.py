#!/usr/bin/env python
"""
no error checks, just a quick way to disable a user's password exiry
"""
import os
import sys
import subprocess

USER_NAME = "netadmin"


def root():
    """Are we root?"""
    user = os.getuid()
    if user == 0:
        print("\nDo not run this as root.\n")
        subprocess.call('sudo logger -t FAIL "root attempt to execute ?@"', shell=True)
        sys.exit()
    else:
        print("\n")


root()

if __name__ == "__main__":
    print("\nHere is the Existing password expiry information for '%s'\n") % (USER_NAME)
    subprocess.call("sudo /usr/bin/chage -l '%s'" % (USER_NAME), shell=True)
    print("\n Here is the UPDATED password expiry information for %s\n")
    subprocess.call(
        "sudo /usr/bin/chage -I -1 -m0 -M99999 -E -i '%s'" % (USER_NAME), shell=True
    )
    print("\nPlease check for accuracy\n")
