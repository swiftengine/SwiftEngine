default: build

build:
	swift build --product SECore
	swift build --product SEProcessor
	swift build --product SwiftEngine

run:
	swift run SwiftEngine
