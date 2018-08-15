swift_version = 4.1.3
UNAME = $(shell uname)
TMP_DIR = /tmp
swift = /opt/apple/swift-latest/usr/bin/swift
runner = $(shell whoami)
pwd = $(shell pwd)
build_dir = $(pwd)/.build
release_dir = $(build_dir)/debug
SECORE_LOCATION = $(pwd)/Extra/SwiftEngineCore/.build/release

default: build

build: build-swiftengineserver build-seprocessor build-secore

run: build
	SEPROCESSOR_LOCATION=$(release_dir)/SEProcessor \
	SECORE_LOCATION=$(SECORE_LOCATION) \
	$(swift) run SwiftEngineServer


build-swiftengineserver:
	$(swift) build --product SwiftEngineServer

build-seprocessor:
	$(swift) build --product SEProcessor

build-secore:
	make -C Extra/SwiftEngineCore build
	#$(swift) build --product SwiftEngine -c release -Xswiftc -g 
	#rm -f $(SECORE_LOCATION)/SEObjects.list
	#find $(release_dir)/SwiftEngine.build -type f \( -name "*.o" ! -iname "main.swift.o" \) -exec basename {} \; >> $(SECORE_LOCATION)/SEObjects.list
	#rm -f $(SECORE_LOCATION)/SEmodulemaps.list
	#find $(release_dir)/SwiftEngine.build -type f -name "*.modulemap" -exec basename {} \; >> $(SECORE_LOCATION)/SEmodulemaps.list
	#chown -R www-data:www-data .
	#find .build/release -type d -name "*.build" -exec chmod -R a+x {} \;
	#find .build -type d -exec chmod -R a+x {} \;

	#./.build/x86_64-apple-macosx10.10/release/libSwiftEngine.dylib ?? hot to use this

build-swiftengine-releasepack:
	rm $(build_dir)/releasePack.zip
	find $(release_dir) -name "*.swiftmodule" -exec  zip releasePack.zip {} +
	find $(build_dir)/checkouts -name "*.h" -exec  zip releasePack.zip {} +
	find $(release_dir)/SwiftEngine.build -name "*.o" -exec  zip releasePack.zip {} +
	find $(build_dir) -name "*.modulemap" -exec  zip releasePack.zip {} +
	zip releasePack.zip $(SECORE_LOCATION)/SEObjects.list +
	zip releasePack.zip $(SECORE_LOCATION)/SEmodulemaps.list +


install-deps: install-dependencies

install-dependencies:
ifneq ($(runner), root)
	@echo "Must run as root user"
else
ifeq ($(UNAME), Linux)
ifeq ($(shell test "$(shell lsb_release -r -s)" = 14.04  -o  \
                   "$(shell lsb_release -r -s)" = 16.04  -o  \
                   "$(shell lsb_release -r -s)" = 16.10  &&  printf "true"),true)
	make install-dependencies-linux
	make setup-system
else
	@echo This version of Linux is not currently supported, please use Ubuntu 14.04, 16.04 or 16.10
endif
else ifeq ($(UNAME), Darwin)
	make install-dependencies-mac
	make setup-system
else
	@echo "$(UNAME) platform is not currently supported"
endif
endif


install-dependencies-linux: 
	$(eval ubuntu_version = $(shell lsb_release -r -s))
	$(eval short_ubuntu_version = $(shell echo $(ubuntu_version) | tr --delete .))
	$(eval swift_download_source = "https://swift.org/builds/swift-$(swift_version)-release/ubuntu$(short_ubuntu_version)/swift-$(swift_version)-RELEASE/swift-$(swift_version)-RELEASE-ubuntu$(ubuntu_version).tar.gz" )
	make install-cleanup-ubuntu
	apt-get -y install git cmake ninja-build clang python uuid-dev libicu-dev icu-devtools libbsd-dev libedit-dev libxml2-dev libsqlite3-dev swig libpython-dev libncurses5-dev pkg-config libblocksruntime-dev libcurl4-openssl-dev systemtap-sdt-dev tzdata rsync
	apt-get -y install libz-dev
	wget $(swift_download_source) -O $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu.tar.gz
	mkdir -p $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu 
	tar -xvzf $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu.tar.gz --directory $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu --strip-components=1
	rm -rf /opt/apple/swift-$(swift_version)
	mkdir -p /opt/apple/swift-$(swift_version)
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu/usr /opt/apple/swift-$(swift_version)/usr
	ln -s /opt/apple/swift-$(swift_version) /opt/apple/swift-latest
	make install-cleanup-ubuntu

install-dependencies-mac: 
	make install-cleanup-mac
	curl https://swift.org/builds/swift-$(swift_version)-release/xcode/swift-$(swift_version)-RELEASE/swift-$(swift_version)-RELEASE-osx.pkg --output $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	pkgutil --expand $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	mkdir -p  $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx
	(cd $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx && ( cat ../swift-$(swift_version)-RELEASE-osx.unpkg/swift-$(swift_version)-RELEASE-osx-package.pkg/Payload | gzip -d | cpio -id )) 
	rm -rf /opt/apple/swift-$(swift_version)
	mkdir -p /opt/apple/swift-$(swift_version)
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/usr /opt/apple/swift-$(swift_version)/usr
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/system /opt/apple/swift-$(swift_version)/system
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/Developer /opt/apple/swift-$(swift_version)/Developer
	ln -s /opt/apple/swift-$(swift_version) /opt/apple/swift-latest
	make install-cleanup-mac

install-cleanup-mac:
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx

install-cleanup-ubuntu:
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu.tar.gz
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-ubuntu

setup-system:
	mkdir -p /etc/swiftengine
	cp -R Extra/templates/etc/swiftengine/* /etc/swiftengine/
	chmod -R a+w /etc/swiftengine
	mkdir -p /var/swiftengine/www /var/swiftengine/.cache
	cp -R Extra/templates/var/swiftengine/www/* /var/swiftengine/www/
	chmod -R a+w /var/swiftengine
	mkdir -p /var/log/swiftengine
	chmod -R a+w /var/log/swiftengine




