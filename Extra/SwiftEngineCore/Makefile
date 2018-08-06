swift_version = 4.1.3
swift = /opt/apple/swift-latest/usr/bin/swift
runner = $(shell whoami)
pwd = $(shell pwd)
build_dir = $(pwd)/.build
release_dir = $(build_dir)/release
SECORE_LOCATION = $(release_dir)

default:

build:
	$(swift) build --product SwiftEngine -c release -Xswiftc -g 
	rm -f $(SECORE_LOCATION)/SEObjects.list
	find $(release_dir)/SwiftEngine.build -type f \( -name "*.o" ! -iname "main.swift.o" \) -exec basename {} \; >> $(SECORE_LOCATION)/SEObjects.list
	rm -f $(SECORE_LOCATION)/SEmodulemaps.list
	find $(release_dir)/SwiftEngine.build -type f -name "*.modulemap" -exec basename {} \; >> $(SECORE_LOCATION)/SEmodulemaps.list

package:

install:
