
import '../../../core/models/network_entity.dart';

/// Represents the result of a network scan
class NetworkScanResult {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final String networkRange;
  final List<NetworkDevice> devices;
  final ScanStatus status;
  final String? errorMessage;
  final Map<String, dynamic> metadata;

  const NetworkScanResult({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.networkRange,
    required this.devices,
    required this.status,
    this.errorMessage,
    this.metadata = const {},
  });

  /// Get the duration of the scan
  Duration get duration {
    if (endTime == null) {
      return Duration.zero;
    }
    return endTime!.difference(startTime);
  }

  /// Get the number of online devices
  int get onlineDeviceCount {
    return devices.where((device) => device.isOnline).length;
  }

  /// Get the number of offline devices
  int get offlineDeviceCount {
    return devices.where((device) => !device.isOnline).length;
  }

  /// Check if the scan is complete
  bool get isComplete {
    return status == ScanStatus.completed || status == ScanStatus.failed;
  }

  /// Create a copy of this result with updated values
  NetworkScanResult copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    String? networkRange,
    List<NetworkDevice>? devices,
    ScanStatus? status,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkScanResult(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      networkRange: networkRange ?? this.networkRange,
      devices: devices ?? this.devices,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'networkRange': networkRange,
      'devices': devices.map((device) => device.toJson()).toList(),
      'status': status.toString(),
      'errorMessage': errorMessage,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory NetworkScanResult.fromJson(Map<String, dynamic> json) {
    return NetworkScanResult(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime'] as String) : null,
      networkRange: json['networkRange'] as String,
      devices: (json['devices'] as List)
          .map((deviceJson) => NetworkDevice.fromJson(deviceJson as Map<String, dynamic>))
          .toList(),
      status: _parseScanStatus(json['status'] as String?),
      errorMessage: json['errorMessage'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static ScanStatus _parseScanStatus(String? value) {
    if (value == null) return ScanStatus.unknown;
    return ScanStatus.values.firstWhere(
      (status) => status.toString() == value,
      orElse: () => ScanStatus.unknown,
    );
  }
}

/// Status of a network scan
enum ScanStatus {
  notStarted,
  inProgress,
  completed,
  failed,
  cancelled,
  unknown,
}

/// Configuration for a network scan
class NetworkScanConfig {
  final String networkRange;
  final int timeout; // in milliseconds
  final int threadCount;
  final bool scanPorts;
  final List<int> portsToScan;
  final bool resolveMacVendors;
  final bool resolveHostnames;

  const NetworkScanConfig({
    required this.networkRange,
    this.timeout = 5000,
    this.threadCount = 10,
    this.scanPorts = false,
    this.portsToScan = const [80, 443, 22, 21],
    this.resolveMacVendors = true,
    this.resolveHostnames = true,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'networkRange': networkRange,
      'timeout': timeout,
      'threadCount': threadCount,
      'scanPorts': scanPorts,
      'portsToScan': portsToScan,
      'resolveMacVendors': resolveMacVendors,
      'resolveHostnames': resolveHostnames,
    };
  }

  /// Create from JSON
  factory NetworkScanConfig.fromJson(Map<String, dynamic> json) {
    return NetworkScanConfig(
      networkRange: json['networkRange'] as String,
      timeout: json['timeout'] as int? ?? 5000,
      threadCount: json['threadCount'] as int? ?? 10,
      scanPorts: json['scanPorts'] as bool? ?? false,
      portsToScan: (json['portsToScan'] as List?)?.map((e) => e as int).toList() ?? [80, 443, 22, 21],
      resolveMacVendors: json['resolveMacVendors'] as bool? ?? true,
      resolveHostnames: json['resolveHostnames'] as bool? ?? true,
    );
  }
}