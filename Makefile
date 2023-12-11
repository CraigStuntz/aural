SWIFT_FORMAT_PATHS := Sources Tests

build: lint
	swift build

test: lint
	swift test

format:
	swift-format -i -r $(SWIFT_FORMAT_PATHS)

lint:
	swift-format lint -r $(SWIFT_FORMAT_PATHS)