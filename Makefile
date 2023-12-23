SWIFT_FORMAT_PATHS := Sources Tests

build: lint
	swift build

test: lint
	swift test

format:
	swift-format --configuration Swift-format.json -i -r $(SWIFT_FORMAT_PATHS)

lint:
	swift-format lint --configuration Swift-format.json -r -s $(SWIFT_FORMAT_PATHS)