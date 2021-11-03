#!/bin/sh

########################################################################
# This file is designed to programmatically add and remove port forwards  
# from a DD-WRT router. It's designed to be called as part of an SSH connection
# to the router, as demonstrated below. 
#
# ssh -q [ROUTER IP] 'sh -s' < ./portforwards.sh [ADD|DEL] [PORT NUMBER] [PROTOCOL] [DEST IP]
#
# Protocol can be TCP, UDP, or BOTH if adding a forward. BOTH is default.
# Removing a forward removes both automatically.
# DEST IP must be a numerical address on your LAN. Only used for ADD.
#########################################################################

COMMAND="$1"
PORT="$2"
PROTOCOL="$3"
DESTIP="$4"
TRACKER=""
NUMRULES=""
NUMRULES2=""
CURRENTRULE=""
PROTOCOL=""

# Sanity, default checks.

    # What protocols to use
    if [ -z "$3" ];then
        PROTOCOL="BOTH"
    else
        PROTOCOL="$3"
    fi


# Delete forwarding rules for specific port
if [ "$COMMAND" = "DEL" ];then
    if [ -n "$2" ];then
        # Get number of rules applying to that port
        NUMRULES=$(iptables -L --line-numbers | grep -c "$PORT" )
        if [ "$NUMRULES" -gt 0 ];then
            TRACKER=1
            while [ "$TRACKER" -le "$NUMRULES" ]; do
                CURRENTRULE=$(iptables -L --line-numbers | grep "$PORT" | head -1 | awk '{print $1}')
                iptables -D FORWARD "$CURRENTRULE"
                TRACKER=$((TRACKER+1))
            done
        fi
    fi
fi

# Add forwarding rules for specific port
if [ "$COMMAND" = "ADD" ];then
    # Start checking and modifying
    if [ -n "$2" ];then
        # What protocols to use
        if [ -z "$PROTOCOL" ];then
            PROTOCOL="BOTH"
        fi

        # check for existence of DESTIP
        if [ -z "$DESTIP" ];then
            echo " Destination IP not set. "
            exit 98
        fi

        # Check that DESTIP exists and responds to ping
        ping -c 1 -W 2 "$DESTIP"; status=$?        
        if [ "$status" -ne 0 ];then
            echo "$DESTIP does not respond to ping; exiting."
            exit 97
        fi
            
        # Checking to ensure there is not already existing rule
        case "$3" in 
            TCP)
                NUMRULES=$(iptables -L --line-numbers | grep "tcp" | grep -c "$PORT")
                ;;
            UDP)
                NUMRULES=$(iptables -L --line-numbers | grep "udp" | grep -c "$PORT")
                ;;
            BOTH)
                NUMRULES=$(iptables -L --line-numbers | grep "tcp" | grep -c "$PORT")
                NUMRULES2=$(iptables -L --line-numbers | grep "udp" | grep -c "$PORT")
                NUMRULES=$((NUMRULES+NUMRULES2))
                ;;
        esac
        if [ "$NUMRULES" -gt 0 ];then
            echo "Existing rules found for $PORT."
            exit 99
        fi

        # Finally time to add the port forward
        case "$3" in 
            TCP)
                iptables -t nat -I PREROUTING -p tcp -d $(nvram get wan_ipaddr) --dport "$PORT" -j DNAT --to "$DESTIP":"$PORT"
                iptables -I FORWARD -p tcp -d "$DESTIP" --dport "$PORT" -j ACCEPT
                ;;
            UDP)
                iptables -t nat -I PREROUTING -p udp -d $(nvram get wan_ipaddr) --dport "$PORT" -j DNAT --to "$DESTIP":"$PORT"
                iptables -I FORWARD -p udp -d "$DESTIP" --dport "$PORT" -j ACCEPT
                ;;
            BOTH)
                iptables -t nat -I PREROUTING -p tcp -d $(nvram get wan_ipaddr) --dport "$PORT" -j DNAT --to "$DESTIP":"$PORT"
                iptables -I FORWARD -p tcp -d "$DESTIP" --dport "$PORT" -j ACCEPT
                iptables -t nat -I PREROUTING -p udp -d $(nvram get wan_ipaddr) --dport "$PORT" -j DNAT --to "$DESTIP":"$PORT"
                iptables -I FORWARD -p udp -d "$DESTIP" --dport "$PORT" -j ACCEPT
                ;;
        esac
    fi
fi
