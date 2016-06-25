#!/bin/bash

########################################################################
# This script is designed to get current active connections as 
# well as static DHCP leases and return what devices are connected
# in a file, by default $HOME/client_ips.txt unless passed as the
# first commandline option
#
# NOTE: Other routers on LAN may provide "offline" results if you have
# configured them to not respond to pings
########################################################################

if [ "$1" == "" ]; then
	outfile=$HOME/client_ips.txt
else
	outfile="$1"
fi

########################################################################
# tempfile declarations
########################################################################
storetemp=$(tempfile)
scratch=$(tempfile)
hosttemp=$(tempfile)
activetemp=$(tempfile)

########################################################################
# Separating out the router information into active connections
# and those which are simply part of static DHCP leases
########################################################################
ssh -q 192.168.1.1 2> /dev/null < ./routerinfo.sh > $storetemp 
routergateway=$(head -1 $storetemp)
sed -n '/###/,/%%%/p' $storetemp | grep -v -e "###" -e "%%%" > $scratch
sed -n '/%%%/,/@@@/p' $storetemp | grep -v -e "%%%" -e "@@@"> $activetemp
grep -v -x -f $activetemp $scratch > $hosttemp

########################################################################
# Checking items with DHCP but not active connections
########################################################################
while read -r line; do
	echo "Checking if $line is alive"
	if [[ "$line" != "127.0.0.1" && "$line" != "192.168.1.1" ]];then
		ping -q -c 1 $line >/dev/null 2>&1
		if [ "$?" == "0" ]; then
			echo $line >> $activetemp
		else 
			echo "* $line" >> $activetemp
		fi
	fi
done < $hosttemp

echo " "
echo "########################################################################"
echo " "

########################################################################
# Matching gateway and static IPs with hostnames
########################################################################
sed -i "/$routergateway/ s/$/ - gateway/" $activetemp
sed -i '/192.168.1.4/ s/$/ - router 1/' $activetemp
sed -i '/192.168.1.5/ s/$/ - router 2/' $activetemp
sed -i '/192.168.1.102/ s/$/ - a computer/' $activetemp
sed -i '/192.168.1.103/ s/$/ - another computer/' $activetemp
sed -i '/192.168.1.104/ s/$/ - and so on/' $activetemp
sed -i '/192.168.1.105/ s/$/ - maybe this is your xbox/' $activetemp
sed -i '/192.168.1.107/ s/$/ - or iPhone/' $activetemp
sed -i '/192.168.1.108/ s/$/ - or tablet/' $activetemp
sed -i '/192.168.1.109/ s/$/ - or whatever/' $activetemp
sed -i '/192.168.1.110/ s/$/ - put the name you want/' $activetemp
sed -i '/192.168.1.111/ s/$/ - here obviously/' $activetemp
sed -i '/192.168.1.116/ s/$/ - and comment out/' $activetemp
sed -i '/192.168.1.120/ s/$/ - the rest/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp
#sed -i '/192.168.1.120/ s/$/ - example/' $activetemp

########################################################################
# Finishing processing so it looks pretty
########################################################################
cat $activetemp | grep -v -e "*" | sort > $outfile
echo "######### Offline Nodes" >> $outfile
cat $activetemp | grep -e "*" | sort >> $outfile

cat $outfile

########################################################################
# Cleaning up tempfiles
########################################################################
rm $storetemp
rm $scratch
rm $hosttemp
rm $activetemp