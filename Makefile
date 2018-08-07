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
	@echo "Linux Installer not implemented"
else ifeq ($(UNAME), Darwin)
	make install-dependencies-mac
	make setup-system
else
	@echo "$(UNAME) platform is not currently supported"
endif
endif

install-dependencies-mac: 
	make install-cleanup
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
	make install-cleanup

install-cleanup:
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx

setup-system:
	mkdir -p /etc/swiftengine
	cp -R Extra/templates/etc/swiftengine/* /etc/swiftengine/
	mkdir -p /var/swiftengine/www
	if [ ! -d "/var/swiftengine/www" ]; then \
		cp -R Extra/templates/var/swiftengine/www/* /var/swiftengine/www/; \
		chmod -R a+w /var/swiftengine/www; \
	fi
	mkdir -p /var/swiftengine/.cache
	chmod a+w /var/swiftengine/.cache



