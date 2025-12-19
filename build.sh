#!/bin/bash

# Build the Swift package in release mode
swift build --configuration release

# Create the .app bundle structure
APP_NAME="Explorer"
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Remove existing app if it exists
rm -rf "$APP_DIR"

# Create directories
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy the executable
cp .build/release/explorer "$MACOS_DIR/"

# Sign the executable
codesign --force --sign - "$MACOS_DIR/explorer"

# Copy Info.plist
cp Sources/Resources/Info.plist "$CONTENTS_DIR/"

# Codesign the app with ad-hoc signing
codesign --force --sign - "$APP_DIR"

echo "App built at $APP_DIR"