import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_handler.dart';

// Define the brand color - RGB(35, 29, 91)
const Color kBrandColor = Color.fromRGBO(35, 29, 91, 1);

class PermissionRequestDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<PermissionInfo> permissions;

  const PermissionRequestDialog({
    Key? key,
    required this.title,
    required this.description,
    required this.icon,
    required this.permissions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kBrandColor.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: kBrandColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 40,
                color: kBrandColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kBrandColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[700],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildPermissionsList(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(
                        color: kBrandColor,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Not Now',
                      style: TextStyle(
                        color: kBrandColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      final permissionsToRequest = permissions
                          .map((p) => p.permission)
                          .toList();
                      
                      final results = await permissionsToRequest.request();
                      
                      if (context.mounted) {
                        // Check if any permission was permanently denied
                        for (var entry in results.entries) {
                          if (entry.value.isPermanentlyDenied) {
                            final permInfo = permissions.firstWhere(
                              (p) => p.permission == entry.key,
                              orElse: () => permissions.first,
                            );
                            
                            PermissionService.showPermissionDialog(
                              context: context,
                              title: '${permInfo.name} Permission Required',
                              message: 'Please enable ${permInfo.name.toLowerCase()} permission in app settings to continue.',
                              permission: permInfo.name.toLowerCase(),
                            );
                            break;
                          }
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBrandColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Allow',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsList(BuildContext context) {
    return Column(
      children: permissions.map((permission) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: kBrandColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: kBrandColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kBrandColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  permission.icon,
                  color: kBrandColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      permission.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kBrandColor,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      permission.description,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Show the permission dialog
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required List<PermissionInfo> permissions,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => PermissionRequestDialog(
        title: title,
        description: description,
        icon: icon,
        permissions: permissions,
      ),
    );
    
    return result ?? false;
  }
}

/// Helper class to describe each permission
class PermissionInfo {
  final Permission permission;
  final String name;
  final String description;
  final IconData icon;

  const PermissionInfo({
    required this.permission,
    required this.name,
    required this.description,
    required this.icon,
  });

  /// Predefined permission for camera
  static PermissionInfo camera() {
    return const PermissionInfo(
      permission: Permission.camera,
      name: 'Camera',
      description: 'To take photos of food labels and ingredients',
      icon: Icons.camera_alt_outlined,
    );
  }

  /// Predefined permission for photo gallery
  static PermissionInfo photos() {
    return const PermissionInfo(
      permission: Permission.photos,
      name: 'Photos',
      description: 'To select photos from your gallery',
      icon: Icons.photo_library_outlined,
    );
  }

  /// Predefined permission for storage
  static PermissionInfo storage() {
    return const PermissionInfo(
      permission: Permission.storage,
      name: 'Storage',
      description: 'To save and access saved scan results',
      icon: Icons.folder_outlined,
    );
  }
} 