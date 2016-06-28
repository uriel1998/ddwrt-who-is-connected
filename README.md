# ddwrt-who-is-connected

A script to output who all is actively connected to your DD-WRT router

This script is designed to get current active connections as 
well as static DHCP leases and return what devices are connected
in a file, by default $HOME/client_ips.txt unless passed as the
first commandline option


#Prerequisites

* DD-WRT router (or others that provide hosts,netstat,awk,and grep)
* Correctly setup passwordless SSH connection with DD-WRT router

#Configuration

You *must* configure `connection_outputs.sh` with the appropriate names
of the computers and routers that are connected, and comment out the
ones that you are not interested in. For example, if the device that
is statically assigned to 192.168.1.110 is "Spouse's Android" then 
ensure that you have this line:

```
sed -i '/192.168.1.110/ s/$/ - Spouse iPhone/' $activetemp
```
   
and proceed accordingly.

You will also want to either edit the output file (line 14) or pass it
as the first commandline option.

#Utility

Aside from a fairly easy monitoring service (you can have this redirect
to a local webserver, for example), you can also then use this script
to trigger other things instead of relying on portable devices. 

For a simple example, you could have a cronjob that has the following:

```
   bob=$(grep -c "Spouse iPhone" $HOME/client_ips.txt)
   if [ "$bob" == "1" ];then
      do a command that your spouse wants when they get home
   fi
```

(Note that you will have to use the full path of $HOME if you're really
using a cron job...)

You can see example.sh as a fairly robust starting point, or even full 
featured way to use this, if you don't mind specifying the command line
variables.


#Output

The output file will look like this:
```
   192.168.1.104 - Name of Device
   192.168.1.108 - Name of Device
   192.168.1.109 - Name of Device
   192.168.1.111 - Name of Device
   192.168.1.116 - Name of Device
   192.168.1.120 - Name of Device
   192.168.1.4 - Name of Device
   192.168.1.5 - Name of Device
   555.555.555.555 - gateway 
   ######### Offline Nodes
   * 192.168.1.102 - Name of Device
   * 192.168.1.105 - Name of Device
   * 192.168.1.107 - Name of Device
```

Please note that additional routers may appear in the "offline" list if
you have configured them to reject PING requests.