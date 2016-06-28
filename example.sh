#!/bin/bash

declare Process
declare Host
declare Psx
declare Clientips
declare Scratch
declare HostConnected
declare ProcessNumber
declare Command

process_needed() {
	if [[ "$@" == *"--process"* ]]; then
		Process=$(echo "$@" | awk -F "--logfile=" '{print $2}' | awk -F "--" '{print $1}')
	else
		show_help
		>&2 echo "No process specified; exiting."
		exit
	fi
}

command_line() {
	if [[ "$@" == *"--cli"* ]]; then
		Command=$(echo "$@" | awk -F "--cli=" '{print $2}' | awk -F "--" '{print $1}')
	else
		show_help
		>&2 echo "No command specified, exiting."
		exit
	fi
}


connection_needed() {
	if [[ "$@" == *"--host"* ]]; then
		Host=$(echo "$@" | awk -F "--host=" '{print $2}' | awk -F "--" '{print $1}')
	else
		show_help
		>&2 echo "No host specified, exiting."
		exit
	fi
}

client_ips() {
	#default location is $HOME/client_ips.txt
	if [[ "$@" == *"--clientips"* ]]; then
		Clientips=$(echo "$@" | awk -F "--logfile=" '{print $2}')
	else
		if [ -f "$HOME/client_ips.txt" ]; then
			Clientips="$HOME/client_ips.txt"
		else	
			show_help
			>&2 echo "Speedtest log not present; analysis cannot occur."
		fi
	fi
}

show_help() {
	#Wherein our hero tells the user what's what.
	echo "Must be called with --process=[process string to search for"
	echo "and --host=[host name or IP to search for]"	
	echo "client_ips.txt must be in $HOME or specified by --clientips=[filename]"
	echo "Command line to start must be specified by --cli=[command]"
}

main() {
	process_needed "$@"
	connection_needed "$@"
	client_ips "$@"

	# Search for the particular device you want to see if it's connected
	HostConnected=$(grep -v -e "*" "$Clientips" | grep -c -e "$Host")
	# Search for the particular process you want to see if it's connected
	scratch=$(ps aux | grep "$Process")
	Psx=$(echo "$scratch"|grep --color=auto -c -v -e grep -e $0)
	ProcessNumber=$(echo "$scratch" | awk '{print $2}')
	
	# These tests are to STOP a process when the specified host is 
	# connected, e.g. to stop doing something when I'm home. Invert
	# if you want the opposite behavior.

	if [ $HostConnected > 0 ];then
		if [ $Psx > 0 ];then 		# am home, process running 
			kill -9 "ProcessNumber"
		else
			echo "Process not running; exiting." # obvs, I hope.
		fi
	else
		if [ $Psx > 0 ];then 		# am NOT home, process running 
			echo "Process running; exiting." # Obvs
		else
			eval "$Command" # run the command
		fi
	fi