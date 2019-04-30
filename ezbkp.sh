#!/bin/bash

#set -x

bkpfile=$(date +$2@%F_%H-%M-%S.tgz)

function prep {
	tar czf $bkpfile $1 $2
}

function googledrive {
	skicka > /dev/null

	if [ $? -eq 127 ]; then
		echo "[ !! ] Installing skicka"

		go > /dev/null
		if [ $? -eq 127 ]; then
			echo "  [ !! ] Installing go"
			sudo snap install go --classic

			# add our Go executables to path
			export $PATH=$PATH:/home/$(whoami)/go/bin
		fi

		go get github.com/google/skicka

		skicka -no-browser-auth ls
	fi

	skicka upload $bkpfile $bkpfile
}

function backblazeb2 {
	if [ "$B2_BUCKET" = "" ]; then
		echo "[ !! ] Please set the B2_BUCKET environment variable."
		exit 1
	fi

	b2 version > /dev/null

	if [ $? -eq 127 ]; then
		echo "[ !! ] Installing b2"

		python -V > /dev/null

		if [ $? -eq 127 ]; then
			echo "  [ !! ] Python is not installed. Please install Python and try again."
			exit 1
		fi

		pip -V > /dev/null

		if [ $? -eq 127 ]; then
			echo "  [ !! ] pip is not installed. Please install pip (sudo easy_install pip) and try again."
			exit 1
		fi

		sudo pip install --upgrade --ignore-installed b2

		b2 authorize-account
	fi

	b2 upload-file $B2_BUCKET $bkpfile $bkpfile

}

if [ $# -lt 3 ]; then
	echo "ezbkp by antigravities"
	echo ""
	echo "$0 file_or_directory backup_prefix [backblazeb2|googledrive]..."
	echo ""
	echo "Environment variables:"
	echo "B2_BUCKET - The B2 bucket to upload to"
	exit 1
fi

skipfirst=0
itemprepped=0

for item in "$@"; do
	if [ $skipfirst = 0 ] || [ $skipfirst = 1 ]; then
		if [ $itemprepped = 0 ]; then
			prep $item
			itemprepped=1
		fi

		skipfirst=$(($skipfirst + 1))
		continue
	fi

	case "$item" in
		googledrive)
			googledrive
			;;
		backblazeb2)
			backblazeb2
			;;
	esac

	echo "[ !! ] Done"
done
