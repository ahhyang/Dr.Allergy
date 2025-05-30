# Permission Handling in Dr. Allergy App

This document explains how to implement and use the permission handling system in the Dr. Allergy app.

## Overview

The app requires the following permissions:
- **Camera**: To take photos of food products and labels
- **Photo Gallery**: To select photos from the device
- **Storage**: To save and access scan results

We've created a flexible permission handling system with beautiful UI dialogs to request permissions in a user-friendly way.

## Components

1. **PermissionService**: A utility service to request and manage permissions
2. **PermissionRequestDialog**: A custom dialog with a modern UI for requesting permissions
3. **PermissionInfo**: A helper class to describe permissions with their icons and descriptions

## Usage Examples

### 1. Request Individual Permissions

To request camera permission:

```dart
final hasPermission = await PermissionService.requestCameraPermission(context);
if (hasPermission) {
  // Permission granted, proceed with camera operations
} else {
  // Handle the case when permission is denied
}
```

To request gallery permission:

```dart
final hasPermission = await PermissionService.requestGalleryPermission(context);
if (hasPermission) {
  // Permission granted, proceed with gallery operations
} else {
  // Handle the case when permission is denied
}
```

### 2. Request All Permissions at Once

```dart
final hasPermissions = await PermissionService.requestAppPermissions(context);
if (hasPermissions) {
  // All permissions granted, proceed with app operations
} else {
  // Handle the case when one or more permissions are denied
}
```

### 3. Showing Custom Permission Dialog Manually

You can create a custom dialog with specific permissions:

```dart
final result = await PermissionRequestDialog.show(
  context: context,
  title: 'Custom Permission',
  description: 'The app needs specific permissions:',
  icon: Icons.security,
  permissions: [
    PermissionInfo.camera(),
    PermissionInfo.photos(),
    // Add other required permissions
  ],
);

if (result) {
  // User agreed to permissions
} else {
  // User declined
}
```

## Implementation in Screens

The permission dialogs can be used in various screens:

1. **ScanFoodScreen**: Requests camera/gallery permissions before taking or selecting photos
2. **PermissionsScreen**: A dedicated screen for managing all app permissions

## Android Configuration

Make sure you have these permissions in your `AndroidManifest.xml`:

```xml
<!-- Camera permissions -->
<uses-permission android:name="android.permission.CAMERA" />
<!-- Storage permissions -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
                 android:maxSdkVersion="29" />
<!-- For Android 13+ -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

## iOS Configuration

For iOS, add these entries to your `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos of food products for allergen detection</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select images of food products</string>
```

## Best Practices

1. Always request permissions just before you need them, not all at once during app startup
2. Provide clear explanations why each permission is needed
3. Handle both permission granted and denied cases gracefully
4. When permission is permanently denied, guide the user to app settings