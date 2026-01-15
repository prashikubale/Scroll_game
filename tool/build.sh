#!/bin/bash

echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Enabling dummy web config to force download of artifacts (sometimes needed)..."
flutter config --enable-web

echo "Getting dependencies..."
flutter pub get

echo "Building web..."
flutter build web --release --no-tree-shake-icons

echo "Build complete."
