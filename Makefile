swift_version = 4.1.3
UNAME = $(shell uname)
TMP_DIR = /tmp


default: build

build:
	swift build --product SECore
	swift build --product SEProcessor
	swift build --product SwiftEngine

run:
	swift run SwiftEngine

install-dependencies:
ifeq ($(UNAME), Linux)
	echo "Linux Installer not implemented"
else ifeq ($(UNAME), Darwin)
	make install-dependencies-mac
else
	echo "$(UNAME) platform is not currently supported"
endif

install-dependencies-mac: cleanup-mac
	#curl https://swift.org/builds/swift-$(swift_version)-release/xcode/swift-$(swift_version)-RELEASE/swift-$(swift_version)-RELEASE-osx.pkg --output $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	pkgutil --expand $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	mkdir -p  $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx
	(cd $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx && ( cat ../swift-$(swift_version)-RELEASE-osx.unpkg/swift-$(swift_version)-RELEASE-osx-package.pkg/Payload | gzip -d | cpio -id )) 
	rm -rf /opt/apple/swift-$(swift_version)
	mkdir -p /opt/apple/swift-$(swift_version)
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/usr /opt/apple/swift-$(swift_version)/usr
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/system /opt/apple/swift-$(swift_version)/system
	mv $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx/Developer /opt/apple/swift-$(swift_version)/Developer
	ln -s /opt/apple/swift-$(swift_version) /opt/apple/swift-latest
	make cleanup-mac

cleanup-mac:
	#rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.pkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx.unpkg
	rm -rf $(TMP_DIR)/swift-$(swift_version)-RELEASE-osx
	
