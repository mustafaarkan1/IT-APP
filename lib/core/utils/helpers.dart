import 'dart:io';
import 'dart:math'; // Add this import for log() and pow() functions
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class AppHelpers {
  // Private constructor to prevent instantiation
  AppHelpers._();

  // Format date time
  static String formatDateTime(DateTime dateTime, {String format = 'yyyy-MM-dd HH:mm:ss'}) {
    return DateFormat(format).format(dateTime);
  }

  // Format bytes to human readable format
  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  // Format milliseconds to human readable format
  static String formatDuration(int milliseconds) {
    final duration = Duration(milliseconds: milliseconds);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    final ms = duration.inMilliseconds % 1000;
    
    if (minutes > 0) {
      return '$minutes min ${seconds.toString().padLeft(2, '0')} sec';
    } else if (seconds > 0) {
      return '$seconds.${(ms ~/ 10).toString().padLeft(2, '0')} sec';
    } else {
      return '$ms ms';
    }
  }

  // Check if string is valid IP address
  static bool isValidIpAddress(String ip) {
    final ipv4Pattern = RegExp(
      r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$',
    );
    return ipv4Pattern.hasMatch(ip);
  }

  // Check if string is valid domain name
  static bool isValidDomain(String domain) {
    final domainPattern = RegExp(
      r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9][a-z0-9-]{0,61}[a-z0-9]$',
      caseSensitive: false,
    );
    return domainPattern.hasMatch(domain);
  }

  // Check if string is valid MAC address
  static bool isValidMacAddress(String mac) {
    final macPattern = RegExp(
      r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$',
    );
    return macPattern.hasMatch(mac);
  }

  // Check if string is valid port number
  static bool isValidPort(String port) {
    final portNumber = int.tryParse(port);
    return portNumber != null && portNumber > 0 && portNumber <= 65535;
  }

  // Request app permissions
  static Future<bool> requestPermissions(List<Permission> permissions) async {
    Map<Permission, PermissionStatus> statuses = await permissions.request();
    return statuses.values.every((status) => status.isGranted);
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  // Get device type
  static String getDeviceType() {
    if (Platform.isAndroid) {
      return 'Android';
    } else if (Platform.isIOS) {
      return 'iOS';
    } else if (Platform.isWindows) {
      return 'Windows';
    } else if (Platform.isLinux) {
      return 'Linux';
    } else if (Platform.isMacOS) {
      return 'macOS';
    } else {
      return 'Unknown';
    }
  }

  // Get required permissions based on feature
  static List<Permission> getRequiredPermissions(String feature) {
    switch (feature) {
      case 'Network Scanner':
      case 'WiFi Analyzer':
        return [
          Permission.location,
          Permission.nearbyWifiDevices,
        ];
      case 'Speed Test':
        return []; // Remove Permission.internet as it doesn't exist
      default:
        return [];
    }
  }
}

// Extension methods
extension StringExtension on String {
  bool get isValidIp => AppHelpers.isValidIpAddress(this);
  bool get isValidDomain => AppHelpers.isValidDomain(this);
  bool get isValidMac => AppHelpers.isValidMacAddress(this);
  bool get isValidPort => AppHelpers.isValidPort(this);
}