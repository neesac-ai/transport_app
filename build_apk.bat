@echo off
echo ===== Starting APK Build Process =====

REM Step 1: Install flutter_launcher_icons package
echo Installing flutter_launcher_icons package...
call flutter pub add --dev flutter_launcher_icons

REM Step 2: Create a temporary config file for flutter_launcher_icons
echo Creating launcher icons configuration...
(
echo flutter_launcher_icons:
echo   android: true
echo   ios: true
echo   image_path: "logo.jpg"
echo   adaptive_icon_background: "#FFFFFF"
echo   adaptive_icon_foreground: "logo.jpg"
) > flutter_launcher_icons.yaml

REM Step 3: Run flutter_launcher_icons to update app icons
echo Updating app icons...
call flutter pub get
call flutter pub run flutter_launcher_icons

REM Step 4: Build the APK
echo Building release APK...
call flutter build apk --release

REM Step 5: Also build split APKs for different architectures
echo Building split APKs by architecture...
call flutter build apk --split-per-abi --release

REM Step 6: Display the paths to the generated APKs
echo ===== Build Complete =====
echo APKs are available at:
echo Regular APK: %CD%\build\app\outputs\flutter-apk\app-release.apk
echo Split APKs:
echo   - %CD%\build\app\outputs\flutter-apk\app-armeabi-v7a-release.apk
echo   - %CD%\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk
echo   - %CD%\build\app\outputs\flutter-apk\app-x86_64-release.apk

pause



