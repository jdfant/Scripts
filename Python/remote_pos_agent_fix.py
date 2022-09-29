#!/usr/bin/env python
"""
This is for admins to remove the need to manually transfer
files and edit agent.ini for each individual system.
"""

import socket
import fcntl
import struct
import subprocess


def get_mac(ifname):
    """
    Grab the MAC from the system
    """
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    data = fcntl.ioctl(sock.fileno(), 0x8927, struct.pack("256s", ifname[:15]))
    return "".join(["%02x:" % ord(char) for char in data[18:24]])[:-1]


def char_replace():
    """
    Change all colons (:) to hyphens (-) for the ID
    """
    mac = get_mac("eth0").replace(":", "-")
    with open("write_it.txt", "w") as char:
        char = char.replace("PhysicalId=00-00-00-00-00-00", "PhysicalId=" + mac)


def ep_ini():
    """
    Populate the Special agent.ini with this
    """
    special = [
        "; POS created by script\n",
        "[ClientAgent]\n",
        "PhysicalId=00-00-00-00-00-00\n",
        "posId=12\n",
        "transDateGMT=N\n",
        "transItemDateGMT=N\n",
        "\n",
        "[ReaderManager]\n",
        "types=POS,SNMP\n",
        "\n",
        "[TranslatorManager]\n",
        "types=Topaz\n",
        "\n",
        "[TransmissionManager]\n",
        "Destinations=HTTP,SNMP\n",
        "\n",
        "[HTTP]\n",
        "EventTypes=POS\n",
        "library=lib/libHttpImp.so\n",
        "StoreFilePrefix=HTTPData\n",
        "StoreFileHomeDir=/data/eventStoreData\n",
        "HttpUrl=xxxxxxxxxxxxxxxxxxxxxxxxxx:3000/efc/transactionEventItem\n",
        "\n",
        "[SNMP]\n",
        "EventTypes=SNMP\n",
        "library=lib/libHttpImp.so\n",
        "StoreFilePrefix=SNMPData\n",
        "StoreFileHomeDir=/data/eventStoreData\n",
        "HttpUrl=xxxxxxxxxxxxxxxxxxxxxxxxxx:3000/efc/snmp\n",
        "\n",
        "[POSReader]\n",
        "type=POS\n",
        "source=POS\n",
        "class=pos::PosReader\n",
        "nfds=1024\n",
        "serial=2\n",
        "tcp=0\n",
        "udp=0\n",
        "\n",
        "[Serial0]\n",
        "device=/dev/EA/EA0\n",
        "baud=9600\n",
        "charbits=8\n",
        "parity=n\n",
        "stopbits=1\n",
        "swfc=0\n",
        "hwfc=0\n",
        "separator=0a\n",
        "keepSeparator=0\n",
        "type=Topaz\n",
        "source=Topaz\n",
        "library=lib/libSerialReader.so\n",
        "rawlog=/data/ea/raw_Serial0.log\n",
        "\n",
        "[Serial1]\n",
        "device=/dev/EA/EA1\n",
        "baud=9600\n",
        "charbits=8\n",
        "parity=n\n",
        "stopbits=1\n",
        "swfc=0\n",
        "hwfc=0\n",
        "separator=0a\n",
        "keepSeparator=0\n",
        "type=Topaz\n",
        "source=Topaz\n",
        "library=lib/libSerialReader.so\n",
        "rawlog=/data/ea/raw_Serial1.log\n",
        "\n",
        "[SNMPReader]\n",
        "type=SNMP\n",
        "source=SNMP\n",
        "class=snmp::SNMPReader\n",
        "sleepTime=30\n",
        "\n",
        "[RubyTranslator]\n",
        "name=Ruby\n",
        "source=Ruby\n",
        "class=translator::RubyTranslator\n",
        "receiptType=RUBY\n",
        "\n",
        "; Topaz Translator\n",
        "[TopazTranslator]\n",
        "name=Topaz\n",
        "source=Topaz\n",
        "class=translator::TopazTranslator\n",
        "receiptType=TOPAZ\n",
        "\n",
        "[SequenceGenerator]\n",
        "cfgFile=etc/sequence.dat\n",
        "\n",
        "[ConfigFile]\n",
        "DumpCfgFileToScreenOnStart=0\n",
    ]

    print("\nCreating new Special agent.ini file\n")
    with open("write_it.txt", "w") as text_file:
        text_file.writelines(special)
    subprocess.Popen(["chmod", "0755", "write_it.txt"])
    subprocess.Popen(["chown", "user:group", "write_it.txt"])


def non_ep_ini():
    """
    Populate the NON-Special agent.ini with this
    """
    non_special = [
        "; Ruby created by script\n",
        "[EventAgent]\n",
        "PhysicalId=00-00-00-00-00-00\n",
        "posId=12\n",
        "transDateGMT=N\n",
        "transItemDateGMT=N\n",
        "\n",
        "[ReaderManager]\n",
        "types=POS,SNMP\n",
        "\n",
        "[TranslatorManager]\n",
        "types=Topaz\n",
        "\n",
        "[TransmissionManager]\n",
        "Destinations=HTTP,SNMP\n",
        "\n",
        "[HTTP]\n",
        "EventTypes=POS\n",
        "library=lib/libHttpImp.so\n",
        "StoreFilePrefix=HTTPData\n",
        "StoreFileHomeDir=/data/eventStoreData\n",
        "HttpUrl=xxxxxxxxxxxxxxxxxxxxxxxxx:3000/efc/transactionEventItem\n",
        "\n",
        "[SNMP]\n",
        "EventTypes=SNMP\n",
        "library=lib/libHttpImp.so\n",
        "StoreFilePrefix=SNMPData\n",
        "StoreFileHomeDir=/data/eventStoreData\n",
        "HttpUrl=http://xxxxxxxxxxxxxxxxxx:3000/efc/snmp\n",
        "\n",
        "[POSReader]\n",
        "type=POS\n",
        "source=POS\n",
        "class=pos::PosReader\n",
        "nfds=1024\n",
        "serial=1\n",
        "tcp=0\n",
        "udp=0\n",
        "\n",
        "[Serial0]\n",
        "device=/dev/ttyS0\n",
        "baud=9600\n",
        "charbits=8\n",
        "parity=n\n",
        "stopbits=1\n",
        "swfc=0\n",
        "hwfc=0\n",
        "separator=0a\n",
        "keepSeparator=0\n",
        "type=Topaz\n",
        "source=Topaz\n",
        "library=lib/libSerialReader.so\n",
        "rawlog=/data/ea/raw_Serial0.log\n",
        "\n",
        "[Serial1]\n",
        "device=/dev/ttyS1\n",
        "baud=9600\n",
        "charbits=8\n",
        "parity=n\n",
        "stopbits=1\n",
        "swfc=0\n",
        "hwfc=0\n",
        "separator=0a\n",
        "keepSeparator=0\n",
        "type=Topaz\n",
        "source=Topaz\n",
        "library=lib/libSerialReader.so\n",
        "rawlog=/data/ea/raw_Serial1.log\n",
        "\n",
        "[SNMPReader]\n",
        "type=SNMP\n",
        "source=SNMP\n",
        "class=snmp::SNMPReader\n",
        "sleepTime=30\n",
        "\n",
        "[RubyTranslator]\n",
        "name=Ruby\n",
        "source=Ruby\n",
        "class=translator::RubyTranslator\n",
        "receiptType=RUBY\n",
        "\n",
        "; Topaz Translator\n",
        "[TopazTranslator]\n",
        "name=Topaz\n",
        "source=Topaz\n",
        "class=translator::TopazTranslator\n",
        "receiptType=TOPAZ\n",
        "\n",
        "[SequenceGenerator]\n",
        "cfgFile=etc/sequence.dat\n",
        "\n",
        "[ConfigFile]\n",
        "DumpCfgFileToScreenOnStart=0\n",
    ]

    print("\nCreating new NON-Special agent.ini file\n")
    with open("write_it.txt", "w") as text_file:
        text_file.writelines(non_special)
    subprocess.Popen(["chmod", "0755", "write_it.txt"])
    subprocess.Popen(["chown", "user:group", "write_it.txt"])


# Selection panel
print(26 * "-")
print(" Select option 1, 2, or 3 ")
print(26 * "-")
print("1) Special Device")
print("2) Non-Special Device")
print("3) Exit")
print(26 * "-")

IS_VALID = 0

while not IS_VALID:
    try:
        CHOICE = int(raw_input("Enter your choice [1-3]:"))
        IS_VALID = 1
    except ValueError as err:
        print("'%s' is not a valid integer.") % err.args[0].split(": ")[1]

# Lets do stuff!
if CHOICE == 1:
    print("\nPopulating agent.ini file for Special device\n")
    ep_ini()
    char_replace()
elif CHOICE == 2:
    print("\nPopulating agent.ini file for Non-Special device\n")
    non_ep_ini()
    char_replace()
elif CHOICE == 3:
    print("\nOK, it's been real and it's been fun ....... but not real fun, Later\n")
    exit()
else:
    print("\n!!! Invalid number. Try again !!!\n")
    exit()
