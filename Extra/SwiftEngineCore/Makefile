swift_version = 4.1.3
swift = /opt/apple/swift-latest/usr/bin/swift
runner = $(shell whoami)
pwd = $(shell pwd)
build_dir = $(pwd)/.build
release_dir = $(build_dir)/release
SECORE_LOCATION = $(release_dir)

default: build

build:
	$(swift) build --product SwiftEngine -c release -Xswiftc -g 
	rm -f $(SECORE_LOCATION)/SEObjects.list
	(cd $(release_dir) && find . -type f \( -name "*.o" ! -iname "main.swift.o" \) >> $(SECORE_LOCATION)/SEObjects.list )
	rm -f $(SECORE_LOCATION)/SEmodulemaps.list
	(cd $(release_dir) && find . -type f -name "*.modulemap" >> $(SECORE_LOCATION)/SEmodulemaps.list )

package:

install:
