import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_handler.dart';
import '../widgets/permission_dialog.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<Permission, PermissionStatus> _permissionStatuses = {};

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.photos,
      Permission.storage,
    ].request();

    setState(() {
      _permissionStatuses = statuses;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Permissions',
          style: TextStyle(
            color: kBrandColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBrandColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 16),
          const Text(
            'App Permissions',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kBrandColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kBrandColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kBrandColor.withOpacity(0.1),
              ),
            ),
            child: const Text(
              'The app needs access to your camera and photo gallery to check food labels for allergens.',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF666666),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...permissions.map((permission) => _buildPermissionCard(
            context,
            title: permission.name,
            subtitle: permission.description,
            icon: permission.icon,
            permission: permission.permission,
          )).toList(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _requestAllPermissions(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: kBrandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Request All Permissions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Permission permission,
  }) {
    final status = _permissionStatuses[permission];
    final isGranted = status?.isGranted ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kBrandColor.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isGranted 
              ? kBrandColor.withOpacity(0.2) 
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isGranted
                    ? kBrandColor.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? kBrandColor : Colors.grey,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isGranted ? kBrandColor : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _requestSinglePermission(context, permission, title),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: isGranted
                    ? kBrandColor.withOpacity(0.1)
                    : kBrandColor,
                foregroundColor: isGranted
                    ? kBrandColor
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                isGranted ? 'Granted' : 'Grant',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // List of permissions for the app
  List<PermissionInfo> get permissions => [
    PermissionInfo.camera(),
    PermissionInfo.photos(),
    PermissionInfo.storage(),
  ];

  Future<void> _requestSinglePermission(
    BuildContext context,
    Permission permission,
    String permissionName,
  ) async {
    switch (permission) {
      case Permission.camera:
        await PermissionService.requestCameraPermission(context);
        break;
      case Permission.photos:
        await PermissionService.requestGalleryPermission(context);
        break;
      default:
        final status = await permission.request();
        if (status.isPermanentlyDenied) {
          if (context.mounted) {
            PermissionService.showPermissionDialog(
              context: context,
              title: '$permissionName Permission',
              message: '$permissionName permission is required. Please enable it in app settings.',
              permission: permissionName.toLowerCase(),
            );
          }
        }
    }
    
    // Refresh permission statuses
    _checkPermissions();
  }

  Future<void> _requestAllPermissions(BuildContext context) async {
    final result = await PermissionRequestDialog.show(
      context: context,
      title: 'Permission Required',
      description: 'The app needs access to the following services to check food for allergens:',
      icon: Icons.security,
      permissions: permissions,
    );
    
    if (result) {
      // Refresh permission statuses after requesting
      _checkPermissions();
    }
  }
} 