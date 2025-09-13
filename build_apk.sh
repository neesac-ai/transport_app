#!/bin/bash

# Script to build an APK with the logo.jpg as the app icon

echo "===== Starting APK Build Process ====="

# Step 1: Install flutter_launcher_icons package
echo "Installing flutter_launcher_icons package..."
flutter pub add --dev flutter_launcher_icons

# Step 2: Create a temporary config file for flutter_launcher_icons
echo "Creating launcher icons configuration..."
cat > flutter_launcher_icons.yaml << EOL
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "logo.jpg"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "logo.jpg"
EOL

# Step 3: Run flutter_launcher_icons to update app icons
echo "Updating app icons..."
flutter pub get
flutter pub run flutter_launcher_icons

# Step 4: Build the APK
echo "Building release APK..."
flutter build apk --release

# Step 5: Also build split APKs for different architectures
echo "Building split APKs by architecture..."
flutter build apk --split-per-abi --release

# Step 6: Display the paths to the generated APKs
echo "===== Build Complete ====="
echo "APKs are available at:"
echo "Regular APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo "Split APKs:"
echo "  - $(pwd)/build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk"
echo "  - $(pwd)/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk"
echo "  - $(pwd)/build/app/outputs/flutter-apk/app-x86_64-release.apk"


