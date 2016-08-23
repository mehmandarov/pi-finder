#!/bin/bash

printHelp() {
    echo "Tool to distribute RaspberryPi image from one pie to multiple."
    echo ""
    echo "Usage: $0 <action> [<options>] <source> <destination>"
    echo ""
    echo "Available actions:"
    printf " %-8s      :     %s\n" "copy, c" "Create an image from an sd-card"
    printf " %-8s      :     %s\n" "write, w" "Write an image to a sd-card"
    echo ""

    echo "Write options:"
    printf " %-15s :     %s\n" "--hostname=<name>" "Set the hostname for the target sd-card"
}

writeImage() {
    echo "$1"
    if [[ "$1" =~ ^--hostname=* ]] ; then
        hostname=${1#--hostname=}
        shift
    else
       read -p "Hostname of the target Pi: " hostname 
    fi

	while true; do
		echo "Hostname: $hostname"
		read -p "Do you wish to use this? [Y/n] " yn
		case $yn in
			[Yy]*|"" ) break ;;
			[Nn]* ) read -p "Hostname of the target Pi: " hostname ;;
			* ) echo "Please answer yes or no."; echo "";;
		esac
	done
    echo ""

    if [ $# -ne 2 ]; then
        echo "(Only) <source> and <destination> expected!"
        exit
    fi

    src="$1"
    dst="$2"

    echo "Source: $src"
    echo "Destination: $dst"
    read -p "Do you wish to use these? [Y/n] " yn
    case $yn in
        [Yy]*|"" ) ;;
        [Nn]* ) exit ;;
        * ) echo "Please answer yes or no."; echo "";;
    esac
    echo ""

    if [ ! -f "$src" ] ; then
        echo "Not a file: $src"
        exit
    fi

    if [ ! -b "$dst" ] ; then
        echo "Not a block device: $dst"
        exit
    fi

    echo "Writing $src to $dst."
    echo "Please wait, it takes a while..."
    dd bs=4M if=$src of=$dst

    echo "Mounting and modfying hostname."
    dir=`mktemp -d`
    partition="${dst}p2"
    mount $partition $dir
    echo "$hostname" > $dir/etc/hostname
    umount $dir

    rmdir $dir
}

copyImage() {
    if [ $# -ne 2 ]; then
        echo "(Only) <source> and <destination> expected!"
        exit
    fi

    src="$1"
    dst="$2"

    echo "Source: $src"
    echo "Destination: $dst"
    read -p "Do you wish to use these? [Y/n] " yn
    case $yn in
        [Yy]*|"" ) ;;
        [Nn]* ) exit ;;
        * ) echo "Please answer yes or no."; echo "";;
    esac
    echo ""

    if [ ! -b "$src" ] ; then
        echo "Not a block device: $src"
        exit
    fi

    if [ -f "$dst" ] ; then
        echo "File already exists: $dst"
        exit
    fi

    echo "Copying $src to $dst."
    echo "Please wait, it takes a while..."
    dd bs=4M if=$src of=$dst
}

case $1 in
    copy|c)
        shift
        copyImage $@
        ;;
    write|w)
        shift
        writeImage $@
        ;;
    help|h)
        printHelp
        exit
        ;;
    *)
        echo "Invalid action: $1"
        echo "------"
        printHelp
        exit
        ;;
esac

