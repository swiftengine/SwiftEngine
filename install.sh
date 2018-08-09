#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    apt-get -y install make
	make install-dependencies-linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
	echo Mac is not current supported through this script
fi

