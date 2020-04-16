#!/bin/bash
gawk -i inplace -v INPLACE_SUFFIX=.bak '/StrictModes yes/{print $0; print "MaxAuthTries 3" RS "MaxSessions 20";next}1' sshd_config
