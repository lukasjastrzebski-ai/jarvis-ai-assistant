.PHONY: setup generate build build-ios build-macos test test-ios test-macos clean

# Install dependencies and generate project
setup: install-xcodegen generate

# Install xcodegen if not present
install-xcodegen:
	@which xcodegen > /dev/null || brew install xcodegen

# Generate Xcode project from project.yml
generate:
	xcodegen generate

# Build all targets
build: build-ios build-macos

# Build iOS app
build-ios:
	xcodebuild build \
		-project Jarvis.xcodeproj \
		-scheme Jarvis-iOS \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug

# Build macOS app
build-macos:
	xcodebuild build \
		-project Jarvis.xcodeproj \
		-scheme Jarvis-macOS \
		-configuration Debug

# Run all tests
test: test-swift test-ios test-macos

# Run Swift package tests
test-swift:
	swift test

# Test iOS app
test-ios:
	xcodebuild test \
		-project Jarvis.xcodeproj \
		-scheme Jarvis-iOS \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-configuration Debug

# Test macOS app
test-macos:
	xcodebuild test \
		-project Jarvis.xcodeproj \
		-scheme Jarvis-macOS \
		-configuration Debug

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build
	rm -rf DerivedData
	xcodebuild clean -project Jarvis.xcodeproj -scheme Jarvis-iOS 2>/dev/null || true
	xcodebuild clean -project Jarvis.xcodeproj -scheme Jarvis-macOS 2>/dev/null || true
