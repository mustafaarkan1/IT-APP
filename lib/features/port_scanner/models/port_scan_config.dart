import 'package:flutter/foundation.dart';

/// Configuration for a port scan operation
class PortScanConfig {
  /// The target IP address or hostname to scan
  final String ipAddress;
  
  /// List of port numbers to scan
  final List<int> ports;
  
  /// Timeout in milliseconds for each port scan attempt
  final int timeout;
  
  /// Number of concurrent threads to use for scanning
  final int threadCount;

  /// Creates a new port scan configuration
  const PortScanConfig({
    required this.ipAddress,
    required this.ports,
    this.timeout = 3000,
    this.threadCount = 50,
  });

  /// Creates a copy of this configuration with the given fields replaced
  PortScanConfig copyWith({
    String? ipAddress,
    List<int>? ports,
    int? timeout,
    int? threadCount,
  }) {
    return PortScanConfig(
      ipAddress: ipAddress ?? this.ipAddress,
      ports: ports ?? this.ports,
      timeout: timeout ?? this.timeout,
      threadCount: threadCount ?? this.threadCount,
    );
  }

  /// Converts this configuration to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'ports': ports,
      'timeout': timeout,
      'threadCount': threadCount,
    };
  }

  /// Creates a configuration from a JSON map
  factory PortScanConfig.fromJson(Map<String, dynamic> json) {
    return PortScanConfig(
      ipAddress: json['ipAddress'] as String,
      ports: (json['ports'] as List<dynamic>).map((e) => e as int).toList(),
      timeout: json['timeout'] as int,
      threadCount: json['threadCount'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PortScanConfig &&
        other.ipAddress == ipAddress &&
        listEquals(other.ports, ports) &&
        other.timeout == timeout &&
        other.threadCount == threadCount;
  }

  @override
  int get hashCode {
    return ipAddress.hashCode ^
        Object.hashAll(ports) ^
        timeout.hashCode ^
        threadCount.hashCode;
  }

  @override
  String toString() {
    return 'PortScanConfig(ipAddress: $ipAddress, ports: ${ports.length} ports, timeout: $timeout, threadCount: $threadCount)';
  }
}