#!/usr/bin/env python
""" Interactive SSH Tunnel creator to access network devices 
    through Linux systems behind firewalls.
    This script is based on system IDs via nic MAC addresses """
import os
import re
import fcntl
import struct
import socket
import subprocess

def get_ip(ifn):
    """ Discover the IP address of the local device """
    sck = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(sck.fileno(), 0x8915, struct.pack('256s', ifn[:15]))[20:24])

def get_open_port():
    """ Discover a random, non-used port to bind for tunneling """
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.bind(('', 0))
    o_port = sock.getsockname()[1]
    sock.close()
    return o_port

def client_mac():
    """ Set MAC VAR """
    while True:
        c_mac = raw_input("\nEnter the MAC address of the Client: ")
        if re.match("^([a-fA-F0-9]{2}[:]?){5}[a-fA-F0-9]{2}$", c_mac):
            return c_mac
        else:
            print "\nThat is not a valid MAC Address!\nTry again."

def dev_ip():
        """ Set VAR for device IP (not 100% accurate).
        Requires further inspection object for each
        octet to ensure numbers do not exceed 255 """
    while True:
        d_ip = raw_input("\nEnter the IP Address of the device you need to access: ")
        if re.match("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$", d_ip):
            return d_ip
        else:
            print "\nThat is not a valid IP Address!\nTry again."

def dev_port():
    """ Set VAR for device port """
    while True:
        try:
            d_prt = int(raw_input("\nEnter the Port number of the device (press enter if unsure): ") or "80")
            if int(d_prt) > 65535:
                print "Error! Number must be below 65535"
            else:
                print d_prt
                return d_prt
        except ValueError:
            print "\nThat is not a valid port number!\nTry again."

if __name__ == '__main__':
    MAC = client_mac()
    IP = dev_ip()
    PORT = dev_port()
    ETH0 = get_ip('eth0')
    OPEN_PORT = get_open_port()
    USER = os.getenv("USER")
    subprocess.call("ssh -L '%s':'%s':'%s':'%s' '%s'@'%s'" % (ETH0, OPEN_PORT, IP, PORT, USER, MAC), shell=True)
    print
