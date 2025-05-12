# Dr.Allergy App APK Installation Guide

## Important Notice
**We currently recommend using the debug version (`DrAllergy-debug.apk`) of the app.** Due to SDK compatibility issues with certain Android components, the release version build is currently having issues.

## About the Debug APK
The file `DrAllergy-debug.apk` is fully functional and contains all the enhanced allergy detection features we've implemented, including:

- Comprehensive food allergy dataset integration
- Improved symptom checker with detailed allergy risk analysis
- Enhanced food scanner with better image handling
- Population-wide allergy statistics and personal risk assessment

## Installation Instructions

### On Android Device

1. **Enable Unknown Sources**:
   - Go to **Settings** > **Security** or **Privacy**
   - Enable **Install from Unknown Sources** or **Install Unknown Apps**
   (The exact option may vary depending on your Android version)

2. **Transfer the APK**:
   - Copy the `DrAllergy-debug.apk` file to your Android device
   - You can use a USB cable, email, cloud storage, or any file transfer method

3. **Install the App**:
   - Navigate to the APK file on your device using a file manager
   - Tap on the APK file
   - Follow the on-screen instructions to install

4. **After Installation**:
   - You will find the Dr.Allergy app in your app drawer
   - Open it and allow any requested permissions for full functionality

## Debug vs. Release Version
- The debug version is slightly larger in size but includes all features
- Performance is still optimized for a smooth user experience
- All allergy detection functionality works exactly the same as in a release version

## Alternative Installation Methods
If you'd prefer to use the app in development mode, you can also:

1. Clone the repository
2. Open the project in Flutter
3. Run `flutter run` with your device connected

For developers looking to create a release version, we recommend opening the project in Android Studio and using its built-in tools to resolve any SDK compatibility issues that may arise during the build process.

For any questions or issues, please contact the development team. 