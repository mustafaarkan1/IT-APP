import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  // Singleton instance
  static final PermissionService _instance = PermissionService._internal();
  
  // Factory constructor
  factory PermissionService() => _instance;
  
  // Private constructor
  PermissionService._internal();

  // Check and request location permission
  Future<bool> checkLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied) {
      status = await Permission.location.request();
    }
    return status.isGranted;
  }
  
  // Check and request location permission which is required for WiFi scanning
  Future<bool> checkAndRequestLocationPermission() async {
    // Check current permission status
    PermissionStatus status = await Permission.location.status;

    // If permission is not granted, request it
    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    return status.isGranted;
  }

  // Check and request WiFi permission
  Future<bool> checkWifiPermission() async {
    var status = await Permission.nearbyWifiDevices.status;
    if (status.isDenied) {
      status = await Permission.nearbyWifiDevices.request();
    }
    return status.isGranted;
  }

  // Check and request storage permission
  Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      status = await Permission.storage.request();
    }
    return status.isGranted;
  }

  // Check and request camera permission (for QR scanning)
  Future<bool> checkCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      status = await Permission.camera.request();
    }
    return status.isGranted;
  }

  // Check multiple permissions at once
  Future<bool> checkMultiplePermissions(List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  // Show permission rationale dialog
  Future<bool> showPermissionRationaleDialog(
    BuildContext context,
    String title,
    String message,
    String permissionName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Settings'),
          ),
        ],
      ),
    );

    if (result == true) {
      await openAppSettings();
      return false; // Return false as we don't know if user granted permission
    }
    return false;
  }

  // Get required permissions for a specific feature
  List<Permission> getRequiredPermissionsForFeature(String featureName) {
    switch (featureName) {
      case 'Network Scanner':
        return [Permission.location, Permission.nearbyWifiDevices];
      case 'WiFi Analyzer':
        return [Permission.location, Permission.nearbyWifiDevices];
      case 'QR Generator':
        return [Permission.camera, Permission.storage];
      case 'Report Generator':
        return [Permission.storage];
      default:
        return [];
    }
  }
}