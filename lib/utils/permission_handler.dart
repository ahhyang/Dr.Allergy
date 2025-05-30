import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/permission_dialog.dart';

class PermissionService {
  /// Request camera permission
  static Future<bool> requestCameraPermission(BuildContext context) async {
    PermissionStatus status = await Permission.camera.status;
    
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    
    if (status.isPermanentlyDenied) {
      showPermissionDialog(
        context: context,
        title: 'Camera Permission',
        message: 'Camera permission is required to take photos. Please enable it in the app settings.',
        permission: 'camera',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Request photo gallery permission
  static Future<bool> requestGalleryPermission(BuildContext context) async {
    PermissionStatus status = await Permission.photos.status;
    
    if (status.isDenied) {
      status = await Permission.photos.request();
    }
    
    if (status.isPermanentlyDenied) {
      showPermissionDialog(
        context: context,
        title: 'Gallery Permission',
        message: 'Gallery permission is required to select photos. Please enable it in the app settings.',
        permission: 'photos',
      );
      return false;
    }
    
    return status.isGranted;
  }

  /// Request multiple permissions at once
  static Future<Map<Permission, PermissionStatus>> requestMultiplePermissions() async {
    return await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();
  }

  /// Show a dialog when permission is permanently denied
  static void showPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String permission,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: kBrandColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: kBrandColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Open Settings',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Show a custom permission dialog before requesting system permissions
  static Future<bool> showCustomPermissionDialog({
    required BuildContext context,
    required String title,
    required String message,
    required List<Permission> permissions,
  }) async {
    bool proceed = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              proceed = false;
              Navigator.of(context).pop();
            },
            child: const Text('Not Now'),
          ),
          TextButton(
            onPressed: () {
              proceed = true;
              Navigator.of(context).pop();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    
    if (proceed) {
      final statuses = await permissions.request();
      return !statuses.values.contains(PermissionStatus.denied) && 
             !statuses.values.contains(PermissionStatus.permanentlyDenied);
    }
    
    return false;
  }

  /// Request all required app permissions with a single beautiful dialog
  static Future<bool> requestAppPermissions(BuildContext context) async {
    return PermissionRequestDialog.show(
      context: context,
      title: 'Permission Required',
      description: 'The allergy app needs the following permissions to help check food for allergens:',
      icon: Icons.health_and_safety,
      permissions: [
        PermissionInfo.camera(),
        PermissionInfo.photos(),
        PermissionInfo.storage(),
      ],
    );
  }
} 