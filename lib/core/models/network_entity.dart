
// Remove the unused import line

/// Base class for network entities discovered by various tools
class NetworkEntity {
  final String id; // Unique identifier (could be IP, MAC, hostname, etc.)
  final String name; // Display name
  final DateTime discoveredAt; // When this entity was discovered
  final Map<String, dynamic> metadata; // Additional data specific to the entity type

  const NetworkEntity({
    required this.id,
    required this.name,
    required this.discoveredAt,
    this.metadata = const {},
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NetworkEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'discoveredAt': discoveredAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory NetworkEntity.fromJson(Map<String, dynamic> json) {
    return NetworkEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}

/// Represents a device on the network
class NetworkDevice extends NetworkEntity {
  final String? ipAddress;
  final String? macAddress;
  final String? manufacturer;
  final DeviceType deviceType;
  final bool isOnline;
  
  // إضافة الخصائص المفقودة
  final List<int> openPorts;
  final String? vendor;
  final String? hostname;
  final int? responseTime; // بالميلي ثانية

  const NetworkDevice({
    required super.id,
    required super.name,
    required super.discoveredAt,
    this.ipAddress,
    this.macAddress,
    this.manufacturer,
    this.deviceType = DeviceType.unknown,
    this.isOnline = true,
    this.openPorts = const [],
    this.vendor,
    this.hostname,
    this.responseTime,
    super.metadata,
  });

  // Add copyWith method
  NetworkDevice copyWith({
    String? id,
    String? name,
    DateTime? discoveredAt,
    String? ipAddress,
    String? macAddress,
    String? manufacturer,
    DeviceType? deviceType,
    bool? isOnline,
    List<int>? openPorts,
    String? vendor,
    String? hostname,
    int? responseTime,
    Map<String, dynamic>? metadata,
  }) {
    return NetworkDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      ipAddress: ipAddress ?? this.ipAddress,
      macAddress: macAddress ?? this.macAddress,
      manufacturer: manufacturer ?? this.manufacturer,
      deviceType: deviceType ?? this.deviceType,
      isOnline: isOnline ?? this.isOnline,
      openPorts: openPorts ?? this.openPorts,
      vendor: vendor ?? this.vendor,
      hostname: hostname ?? this.hostname,
      responseTime: responseTime ?? this.responseTime,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'manufacturer': manufacturer,
      'deviceType': deviceType.toString(),
      'isOnline': isOnline,
      'openPorts': openPorts,
      'vendor': vendor,
      'hostname': hostname,
      'responseTime': responseTime,
    });
    return json;
  }

  factory NetworkDevice.fromJson(Map<String, dynamic> json) {
    return NetworkDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      ipAddress: json['ipAddress'] as String?,
      macAddress: json['macAddress'] as String?,
      manufacturer: json['manufacturer'] as String?,
      deviceType: _parseDeviceType(json['deviceType'] as String?),
      isOnline: json['isOnline'] as bool? ?? true,
      openPorts: (json['openPorts'] as List?)?.map((e) => e as int).toList() ?? const [],
      vendor: json['vendor'] as String?,
      hostname: json['hostname'] as String?,
      responseTime: json['responseTime'] as int?,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static DeviceType _parseDeviceType(String? value) {
    if (value == null) return DeviceType.unknown;
    return DeviceType.values.firstWhere(
      (type) => type.toString() == value,
      orElse: () => DeviceType.unknown,
    );
  }
}

/// Represents a network service running on a device
class NetworkService extends NetworkEntity {
  final String hostId; // ID of the host device
  final String? ipAddress;
  final int port;
  final String protocol; // TCP, UDP
  final String? serviceName; // e.g., HTTP, SSH, FTP
  final String? version;
  final ServiceStatus status;

  const NetworkService({
    required super.id,
    required super.name,
    required super.discoveredAt,
    required this.hostId,
    this.ipAddress,
    required this.port,
    required this.protocol,
    this.serviceName,
    this.version,
    this.status = ServiceStatus.unknown,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'hostId': hostId,
      'ipAddress': ipAddress,
      'port': port,
      'protocol': protocol,
      'serviceName': serviceName,
      'version': version,
      'status': status.toString(),
    });
    return json;
  }

  factory NetworkService.fromJson(Map<String, dynamic> json) {
    return NetworkService(
      id: json['id'] as String,
      name: json['name'] as String,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      hostId: json['hostId'] as String,
      ipAddress: json['ipAddress'] as String?,
      port: json['port'] as int,
      protocol: json['protocol'] as String,
      serviceName: json['serviceName'] as String?,
      version: json['version'] as String?,
      status: _parseServiceStatus(json['status'] as String?),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  static ServiceStatus _parseServiceStatus(String? value) {
    if (value == null) return ServiceStatus.unknown;
    return ServiceStatus.values.firstWhere(
      (status) => status.toString() == value,
      orElse: () => ServiceStatus.unknown,
    );
  }
}

/// Types of network devices
enum DeviceType {
  router,
  networkSwitch, // Changed from 'switch' to 'networkSwitch'
  server,
  desktop,
  laptop,
  mobile,
  iot,
  printer,
  camera,
  computer, // إضافة قيمة computer
  unknown,
}

/// Status of network services
enum ServiceStatus {
  open,
  closed,
  filtered,
  unknown,
}

/// Represents a ping response
class PingResult {
  final String host;
  final String? ipAddress; // Added for IP display
  final bool isSuccess;
  final double? responseTime; // in milliseconds
  final String? errorMessage;
  final DateTime timestamp;
  
  // Add these new properties
  final int packetsSent;
  final int packetsReceived;
  final double packetLoss;
  final List<int?> responseTimes;
  final int minResponseTime;
  final int maxResponseTime;
  final double? avgResponseTime;

  const PingResult({
    required this.host,
    this.ipAddress,
    required this.isSuccess,
    this.responseTime,
    this.errorMessage,
    required this.timestamp,
    this.packetsSent = 0,
    this.packetsReceived = 0,
    this.packetLoss = 0.0,
    this.responseTimes = const [],
    this.minResponseTime = 0,
    this.maxResponseTime = 0,
    this.avgResponseTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'ipAddress': ipAddress,
      'isSuccess': isSuccess,
      'responseTime': responseTime,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'packetsSent': packetsSent,
      'packetsReceived': packetsReceived,
      'packetLoss': packetLoss,
      'responseTimes': responseTimes,
      'minResponseTime': minResponseTime,
      'maxResponseTime': maxResponseTime,
      'avgResponseTime': avgResponseTime,
    };
  }

  factory PingResult.fromJson(Map<String, dynamic> json) {
    return PingResult(
      host: json['host'] as String,
      ipAddress: json['ipAddress'] as String?,
      isSuccess: json['isSuccess'] as bool,
      responseTime: json['responseTime'] as double?,
      errorMessage: json['errorMessage'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      packetsSent: json['packetsSent'] as int? ?? 0,
      packetsReceived: json['packetsReceived'] as int? ?? 0,
      packetLoss: json['packetLoss'] as double? ?? 0.0,
      responseTimes: (json['responseTimes'] as List?)?.map((e) => e as int?).toList() ?? const [],
      minResponseTime: json['minResponseTime'] as int? ?? 0,
      maxResponseTime: json['maxResponseTime'] as int? ?? 0,
      avgResponseTime: json['avgResponseTime'] as double?,
    );
  }

  PingResult copyWith({
    String? host,
    String? ipAddress,
    bool? isSuccess,
    double? responseTime,
    String? errorMessage,
    DateTime? timestamp,
    int? packetsSent,
    int? packetsReceived,
    double? packetLoss,
    List<int?>? responseTimes,
    int? minResponseTime,
    int? maxResponseTime,
    double? avgResponseTime,
  }) {
    return PingResult(
      host: host ?? this.host,
      ipAddress: ipAddress ?? this.ipAddress,
      isSuccess: isSuccess ?? this.isSuccess,
      responseTime: responseTime ?? this.responseTime,
      errorMessage: errorMessage ?? this.errorMessage,
      timestamp: timestamp ?? this.timestamp,
      packetsSent: packetsSent ?? this.packetsSent,
      packetsReceived: packetsReceived ?? this.packetsReceived,
      packetLoss: packetLoss ?? this.packetLoss,
      responseTimes: responseTimes ?? this.responseTimes,
      minResponseTime: minResponseTime ?? this.minResponseTime,
      maxResponseTime: maxResponseTime ?? this.maxResponseTime,
      avgResponseTime: avgResponseTime ?? this.avgResponseTime,
    );
  }
}

/// Represents a port scan result
class PortScanResult {
  final String host;
  final int port;
  final String protocol; // TCP, UDP
  final ServiceStatus status;
  final String? serviceName;
  final double scanDuration; // in milliseconds
  final DateTime timestamp;

  const PortScanResult({
    required this.host,
    required this.port,
    required this.protocol,
    required this.status,
    this.serviceName,
    required this.scanDuration,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'port': port,
      'protocol': protocol,
      'status': status.toString(),
      'serviceName': serviceName,
      'scanDuration': scanDuration,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory PortScanResult.fromJson(Map<String, dynamic> json) {
    return PortScanResult(
      host: json['host'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String,
      status: NetworkService._parseServiceStatus(json['status'] as String?),
      serviceName: json['serviceName'] as String?,
      scanDuration: json['scanDuration'] as double,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Represents a WiFi network
class WifiNetwork extends NetworkEntity {
  final String ssid;
  final String bssid; // MAC address
  final int signalStrength; // in dBm
  final int channel;
  final String frequency; // in GHz
  final String securityType; // WPA2, WPA3, Open, etc.
  final bool isConnected;

  const WifiNetwork({
    required super.id,
    required super.name,
    required super.discoveredAt,
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.channel,
    required this.frequency,
    required this.securityType,
    this.isConnected = false,
    super.metadata,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json.addAll({
      'ssid': ssid,
      'bssid': bssid,
      'signalStrength': signalStrength,
      'channel': channel,
      'frequency': frequency,
      'securityType': securityType,
      'isConnected': isConnected,
    });
    return json;
  }

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      id: json['id'] as String,
      name: json['name'] as String,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      ssid: json['ssid'] as String,
      bssid: json['bssid'] as String,
      signalStrength: json['signalStrength'] as int,
      channel: json['channel'] as int,
      frequency: json['frequency'] as String,
      securityType: json['securityType'] as String,
      isConnected: json['isConnected'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
}