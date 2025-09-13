# Building an APK with Custom Logo

Follow these steps to build an APK with the logo.jpg image as the app icon:

## 1. Update the App Icon

1. First, install the flutter_launcher_icons package:
```bash
flutter pub add --dev flutter_launcher_icons
```

2. Add the following configuration to your pubspec.yaml file:
```yaml
# Add this section at the end of pubspec.yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "logo.jpg"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "logo.jpg"
```

3. Run the flutter_launcher_icons package to update the app icons:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

## 2. Build the APK

1. Make sure your app is configured correctly in `android/app/build.gradle`:
   - Check that `applicationId` is set to your desired package name
   - Verify `minSdkVersion`, `targetSdkVersion`, and `compileSdkVersion` are appropriate

2. Build the APK:
```bash
flutter build apk --release
```

3. For a smaller APK size, build a split APK by architecture:
```bash
flutter build apk --split-per-abi --release
```

## 3. Find the APK

The APK will be generated at:
- For regular APK: `build/app/outputs/flutter-apk/app-release.apk`
- For split APKs: 
  - `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
  - `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
  - `build/app/outputs/flutter-apk/app-x86_64-release.apk`

## 4. Install on Your Android Phone

1. Transfer the APK to your phone using USB, email, or cloud storage
2. On your phone, navigate to the APK file and tap it to install
3. You may need to enable "Install from Unknown Sources" in your phone's security settings

## Notes

- Make sure your logo.jpg file is of high quality and appropriate dimensions
- The app name displayed on the device will be "version1" as specified in pubspec.yaml
- If you want to change the app name, update the `android:label` in `android/app/src/main/AndroidManifest.xml`
