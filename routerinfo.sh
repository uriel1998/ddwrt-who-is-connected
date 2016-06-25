#!/bin/bash

netstat -nr | grep "UG" | awk '{print $2}'
echo "###"
cd /tmp
cat hosts | awk '{print $1}'
echo "%%%"
for i in `grep 0x /proc/net/arp | cut -d ' ' -f1`; do echo "$i connection count: $(grep -c $i /proc/net/ip_conntrack)"; done |  awk '{print $1}' | sort
echo "@@@"