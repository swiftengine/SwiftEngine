#!/bin/bash
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

testcmd () {
    command -v "$1" >/dev/null
}

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    if testcmd make; then
	    make install-dependencies
    else
        echo "WARNING!"
        echo "This project requires build-essentails tools to be installed."
        echo "Use following command to perform installation: sudo apt-get -y install build-essentials"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    if testcmd make; then
        make install-dependencies
    elif testcmd xcode-select; then
        echo "WARNING!"
        echo "It looks like you have Xcode installed in your system, but you don't have the Command Line Tools option installed yet."
        echo "Please Install Command Line Tools in Mac OS X before proceeeding."
        echo "Use following command to perform installation: xcode-select --install"
    else
        echo "WARNING!"
        echo "This project requires Apple developer tools to be installed."
        echo "Please install Xcode or Apple Command Line Tools before proceeding."
    fi
	
fi


