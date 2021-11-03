# ddwrt-who-is-connected

There are two (main) scripts in this repository, both written for DD-WRT routers:

`ddwrt-who-is-connected`: A script to output who all is actively connected to 
your DD-WRT router.  It can also be used to trigger events depending on who is 
connected to your home network.

`portforwards.sh`: A script to programatically open and close port forwards on 
your DD-WRT router.

Both are described in this README.

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [ddwrt-who-is-connected.sh](#4-ddwrt-who-is-connectedsh)
 5. [portforwards.sh](#5-portforwardssh)

***

## 1. About

### `ddwrt-who-is-connected` is a script to output who all is actively connected 
to your DD-WRT router. This script is designed to get current active 
connections as well as static DHCP leases and return what devices are connected
in a file, by default $HOME/client_ips.txt unless passed as the first 
commandline option.

### `portforwards.sh` was written for when you have a service you intermittently 
need to open to the internet, but you want to only open the port when the 
service is running.  For example, you have a game server you only spin up when 
you and your pals are playing together, or - in combination with `ddwrt-who-is-connected` - 
access to your home media only when you're away from home.  

## 2. License

This project is licensed under the MIT License. For the full license, see `LICENSE`.

## 3. Prerequisites

* DD-WRT router (or others that provide hosts,netstat,awk,and grep)
* Correctly setup passwordless SSH connection with DD-WRT router

## 4. ddwrt-who-is-connected.sh

### Configuration

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

If you want to use the output in a webpage, uncomment line 96.

If you want to use a particular SSH configuration file, see the example
on line 42

### Utility

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

### Output

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

## 5. portforwards.sh

`portforwards.sh` is designed to be called as part of an SSH connection: 

```
ssh -q [ROUTER IP] 'sh -s' < ./portforwards.sh [ADD|DEL] [PORT NUMBER] [PROTOCOL] [DEST IP]
```

If you are deleting port forwards, you only need to specify the port number; DEL 
commands remove ALL rules matching that port number regardless of protocol.

```
ssh -q [ROUTER IP] 'sh -s' < ./portforwards.sh DEL 443
```

If you are adding a port forward, you need to specify the protocol and destination 
IP address in numerical format.

```
ssh -q [ROUTER IP] 'sh -s' < ./portforwards.sh ADD 443 TCP 192.168.1.324 

ssh -q [ROUTER IP] 'sh -s' < ./portforwards.sh ADD 25565 BOTH 192.168.1.324 

```

### Usage notes

* The script will use the `ping` command to attempt to verify the existence of 
the LAN address it is forwarding ports to.  
* While this script will call `iptables-save` (if it exists on your build), 
this does *NOT* make it persist across reboots *on purpose*. This script is
explicitly intended to create temporary changes.  
* The changes made by this script do **NOT** alter nvram or what is shown in 
the GUI interface. If you wish to mess with that, please check out 
[this guide](https://infralin.blogspot.com/2015/04/how-to-maintain-iptables-on-dd-wrt.html). 

### Utility

As an example, here is a `start.sh` used to open the ports for a Minecraft 
server that is located on a machine with the LAN IP address of `192.168.1.324`, 
with the router existing at `192.168.1.1`, and then close the ports when the 
server goes down.  **PLEASE NOTE** that this example assumes that `portforwards.sh` 
is in the same directory; replace `./portforwards.sh` with the full path to the 
file otherwise.

```
#!/usr/bin/env bash

ssh -q 192.168.1.1 'sh -s' < ./portforwards.sh ADD 25565 BOTH 192.168.1.324 

java -jar -Xms2048m -Xmx2048m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=20 -XX:G1ReservePercent=20 -XX:MaxGCPauseMillis=50 -XX:G1HeapRegionSize=32M fabric-server-launch.jar nogui

ssh -q 192.168.1.1 'sh -s' < ./portforwards.sh DEL 25565
```
