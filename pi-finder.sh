#!/bin/bash

# Author: Rustam Mehmandarov - http://mehmandarov.com
# License: GNU General Public License, version 3 (GPLv3)

# ----------------- CONFIG - BEGIN --------------- 
# Some config
declare -r DEBUG=0
declare -r PING_LOG_FILE="ping.log"
declare -r FOUND_RASPBERRYS_FILE="found_raspberrys.txt"
declare -r DEFAULT_PING_DURATION=20 # in seconds

# Emulate enum semantics in the bash shell
OS=(LINUX MACOS CYGWIN MSYS WIN32 FREEBSD UNKNOWN)
oses=${#OS[@]}
for ((i=0; i < $oses; i++)); do
    name=${OS[i]}
    # make names readonly
    declare -r ${name}=$i
done
# ----------------- CONFIG - END ----------------- 


# Detect and return OS type. 
# If return varable is not specified, the OS type is printed to standard out.
function os_detect {
	local  __resultvar=$1
	local myOS=""

	if [[ "$OSTYPE" == "linux-gnu" ]]; then
	        # ...
	        local myOS=${OS[$LINUX]}
	elif [[ "$OSTYPE" == "darwin"* ]]; then
	        # Mac OSX
	        local myOS=${OS[$MACOS]}
	elif [[ "$OSTYPE" == "cygwin" ]]; then
	        # POSIX compatibility layer and Linux environment emulation for Windows
	        local myOS=${OS[$CYGWIN]}
	elif [[ "$OSTYPE" == "msys" ]]; then
	        # Lightweight shell and GNU utilities compiled for Windows (part of MinGW)
	        local myOS=${OS[$MSYS]}
	elif [[ "$OSTYPE" == "win32" ]]; then
	        # I'm not sure this can happen.
	        local myOS=${OS[$WIN32]}
	elif [[ "$OSTYPE" == "freebsd"* ]]; then
	        # FreeBSD
	        local myOS=${OS[$FREEBSD]}
	else
	        # Unknown.
	        local myOS=${OS[$UNKNOWN]}
	fi

	# Return detected OS, or print to standard out if the variable is not specified.
	if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$myOS'"
    else
        echo "$myOS"
    fi
}


# Get broadcast IP. 
# Supported OS: Windows (Cygwin), Linux, Mac OSX
function get_broadcast_ip {
	local __resultvar=$1
	local my_broadcast_ip=""
	local os=$(os_detect)

	if [[ "$os" ==  ${OS[$LINUX]} ]]; then
	        # Linux
	        local my_broadcast_ip=`ip addr show |grep -w inet |grep -v 127.0.0.1|awk '{ print $4}'`
	elif [[ "$os" ==  ${OS[$MACOS]} ]]; then
	        # Mac OSX
			local my_broadcast_ip=`ifconfig | grep -w inet | grep -v 127.0.0.1| awk '{ print $6}'`
	elif [[ "$os" ==  ${OS[$CYGWIN]} ]]; then
	        # POSIX compatibility layer and Linux environment emulation for Windows
	        local my_broadcast_ip=`route print | expand | grep -A1 -w "Netmask" | sed -n 2p | awk '{ print $3}'`
	else
		# Unsupported.
		echo "Usupported operating system. Exiting."
		exit 1
	fi

	
	# Return broadcast IP address, or print to standard out if the variable is not specified.
	if [[ "$__resultvar" ]]; then
        eval $__resultvar="'$my_broadcast_ip'"
    else
        echo "$my_broadcast_ip"
    fi	
}

# Ping broadcast IP
# Expected arguments:
# 		- IP address to ping (will raise an error and exit if IP is not specified)
#		- Ping duration in seconds (default: 20 seconds)
function ping_broadcast_ip() {
	local broadcast_ip=$1
	local ping_duration=$2

	# Exit if IP is not set
	if [ -z "$broadcast_ip" ]; then
		echo "Error: Broadcast IP is not set."
		exit 1
	fi

	# Set default ping duration if not set
	if [ -z "$ping_duration" ]; then
		$ping_duration=$DEFAULT_PING_DURATION
	fi

	echo "Pinging" $broadcast_ip "for" $ping_duration "second(s)."
	echo "Output from ping is logged to" $PING_LOG_FILE "file." 
	ping -t $ping_duration $broadcast_ip > $PING_LOG_FILE
}

# Finds RaspberryPIs on the network based on the MAC address
function find_raspberries() {
	local ip_range=$1/24
	echo "Searching for PIs on:" $broadcast_ip "network. The output will be shown here and saved to" $FOUND_RASPBERRYS_FILE "file."
	sudo nmap -sP  $ip_range | awk '/^Nmap/{ip=$NF}/B8:27:EB/{print ip}' | tee $FOUND_RASPBERRYS_FILE
}

function check_if_root(){
	if [ "$EUID" -ne 0 ]; then 
		echo "Please re-run as root. Exiting."
		exit 1
	else
		if [ "$DEBUG" -eq 1 ]; then 
			echo "DEBUG: Running as root. All good."
		fi

	fi
}


# ----------------- MAIN - BEGIN --------------- 
check_if_root

os=$(os_detect)
echo "Detecting OS:" $os

broadcast=$(get_broadcast_ip)
echo "Broadcast IP:" $broadcast

ping_broadcast_ip $broadcast 5

find_raspberries $broadcast
# ----------------- MAIN - END ----------------- 

