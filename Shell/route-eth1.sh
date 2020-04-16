#!/bin/sh
cat > /etc/sysconfig/network-scripts/route-eth1 <<'EOF'
ADDRESS0=10.5.60.17
NETMASK0=255.255.255.192
GETEWAY0=10.5.48.1
EOF
