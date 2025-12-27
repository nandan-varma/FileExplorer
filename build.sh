#!/bin/bash


set -e

# Build the Swift package in specified configuration (default: release)
CONFIG="${1:-release}"
swift build --configuration "$CONFIG"

# App bundle variables
APP_NAME="Explorer"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Remove existing app if it exists
rm -rf "$APP_DIR"

# Create .app bundle structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the main executable
cp .build/release/explorer "$MACOS_DIR/"
chmod +x "$MACOS_DIR/explorer"

# Copy Info.plist
cp Sources/Resources/Info.plist "$CONTENTS_DIR/"




# Copy any app resources (icons, etc.)
if [ -d Sources/Resources ]; then
	find Sources/Resources -type f \
		! -name Info.plist \
		! -name explorer.entitlements \
		-exec cp {} "$RESOURCES_DIR/" \;
fi

# Sign the executable with entitlements (ad-hoc)
codesign --force --sign - --entitlements Sources/Resources/explorer.entitlements "$MACOS_DIR/explorer"

# Sign the app bundle with entitlements (ad-hoc)
codesign --force --sign - --entitlements Sources/Resources/explorer.entitlements "$APP_DIR"

echo "App built at $APP_DIR"