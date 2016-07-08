#!/bin/bash

########################################################################
# This file is designed to get active and static leases from a DD-WRT
# router. It's designed to be called as part of an SSH connection
# to the router, as demonstrated below. 
#
# ssh -q 192.168.1.1 2> /dev/null < ./routerinfo.sh > $storetemp 
#
#########################################################################

netstat -nr | grep "UG" | awk '{print $2}'
echo "###"
cd /tmp
cat hosts | awk '{print $1}'
echo "%%%"
for i in `grep 0x /proc/net/arp | cut -d ' ' -f1`; do echo "$i connection count: $(grep -c $i /proc/net/ip_conntrack)"; done |  awk '{print $1}' | sort
echo "@@@"