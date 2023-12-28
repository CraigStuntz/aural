SWIFT_FORMAT_PATHS := Sources Tests

build: lint
	swift build

test: lint
	swift test

format:
	swift-format -i -r $(SWIFT_FORMAT_PATHS)

lint:
	swift-format lint -r -s $(SWIFT_FORMAT_PATHS)

run-all: build
	swift run aural --help
	swift run aural
	swift run aural export
	swift run aural update
	swift run aural validate