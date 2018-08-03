swift_version = 4.1.3
UNAME = $(shell uname)
TMP_DIR = /tmp
swift = /opt/apple/swift-latest/usr/bin/swift
runner = $(shell whoami)
pwd = $(shell pwd)

default: build

build: build-swiftengineserver build-seprocessor build-swiftengine

run: build
	SEPROCESSOR_LOCATION=$(pwd)/.build/debug/SEProcessor \
	SECORE_LOCATION=$(pwd)/.build/debug/SwiftEngine \
	$(swift) run SwiftEngineServer


build-swiftengineserver:
	$(swift) build --product SwiftEngineServer

build-seprocessor:
	$(swift) build --product SEProcessor

build-swiftengine:
	$(swift) build --product SwiftEngine

install-deps: install-dependencies

install-dependencies:
ifneq ($(runner), root)
	@echo "Must run as root user"
else
ifeq ($(UNAME), Linux)
	@echo "Linux Installer not implemented"
else ifeq ($(UNAME), Darwin)
	make install-dependencies-mac
else
	@echo "$(UNAME) platform is not currently supported"
endif
endif

install-dependencies-mac: 
	make cleanup-mac
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
	mkdir -p /etc/swiftengine
	cp -R Extra/templates/etc/swiftengine/* /etc/swiftengine/
	mkdir -p /var/swiftengine/www
	if [ ! -d "/var/swiftengine/www" ]; then \
		cp -R Extra/templates//var/swiftengine/www/* /var/swiftengine/www/; \
		chmod a+w /var/swiftengine/www; \
	fi
	mkdir -p /var/swiftengine/.cache
	chmod a+w /var/swiftengine/.cache
	make cleanup-mac

cleanup-mac:
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx
	
