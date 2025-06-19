import 'dart:async';
// Remove unused import: import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/models/network_entity.dart' as models;
import '../../../core/services/network_service.dart';
import '../../../core/utils/helpers.dart';
import '../models/network_scan_result.dart';

class NetworkScannerService {
  final NetworkService _networkService = NetworkService();
  
  // Singleton pattern
  static final NetworkScannerService _instance = NetworkScannerService._internal();
  
  factory NetworkScannerService() => _instance;
  
  NetworkScannerService._internal();

  // Stream controller for scan progress updates
  final StreamController<NetworkScanResult> _scanProgressController = 
      StreamController<NetworkScanResult>.broadcast();

  Stream<NetworkScanResult> get scanProgressStream => _scanProgressController.stream;

  // Currently active scan
  NetworkScanResult? _currentScan;
  bool _isCancelled = false;

  // Get the current scan
  NetworkScanResult? get currentScan => _currentScan;

  // Check if a scan is in progress
  bool get isScanning => _currentScan != null && _currentScan!.status == ScanStatus.inProgress;

  // Start a network scan
  Future<NetworkScanResult> startScan(NetworkScanConfig config) async {
    if (isScanning) {
      throw Exception('A scan is already in progress');
    }

    _isCancelled = false;

    // Create a new scan result
    final scanId = 'scan_${DateTime.now().millisecondsSinceEpoch}';
    _currentScan = NetworkScanResult(
      id: scanId,
      startTime: DateTime.now(),
      networkRange: config.networkRange,
      devices: [],
      status: ScanStatus.inProgress,
      metadata: {
        'config': config.toJson(),
      },
    );

    // Emit initial scan state
    _scanProgressController.add(_currentScan!);

    try {
      // Parse the network range
      final ipAddresses = await _parseNetworkRange(config.networkRange);
      
      if (ipAddresses.isEmpty) {
        _completeWithError('Invalid network range or unable to determine IP addresses');
        return _currentScan!;
      }

      final totalHosts = ipAddresses.length;
      int scannedHosts = 0;
      final devices = <models.NetworkDevice>[];

      // Create batches of IPs to scan concurrently
      for (int i = 0; i < ipAddresses.length; i += config.threadCount) {
        if (_isCancelled) {
          _completeScan(ScanStatus.cancelled);
          return _currentScan!;
        }

        final endBatch = (i + config.threadCount) > ipAddresses.length 
            ? ipAddresses.length 
            : (i + config.threadCount);
        final batch = ipAddresses.sublist(i, endBatch);
        
        // Scan hosts in this batch concurrently
        final batchResults = await Future.wait(
          batch.map((ip) => _scanHost(ip, config))
        );
        
        // Add discovered devices
        for (final device in batchResults) {
          if (device != null) {
            devices.add(device);
          }
        }
        
        // Update progress
        scannedHosts += batch.length;
        final progress = (scannedHosts / totalHosts) * 100;
        
        // Update current scan with progress
        _currentScan = _currentScan!.copyWith(
          devices: List.from(devices),
          metadata: {
            ..._currentScan!.metadata,
            'progress': progress,
            'scannedHosts': scannedHosts,
            'totalHosts': totalHosts,
          },
        );
        
        // Emit progress update
        _scanProgressController.add(_currentScan!);
      }

      // Complete the scan
      _completeScan(ScanStatus.completed);
      return _currentScan!;
    } catch (e) {
      _completeWithError(e.toString());
      return _currentScan!;
    }
  }

  // Cancel the current scan
  void cancelScan() {
    if (isScanning) {
      _isCancelled = true;
    }
  }

  // Parse a network range string into a list of IP addresses
  Future<List<String>> _parseNetworkRange(String range) async {
    final ipAddresses = <String>[];
    
    // Check if it's a single IP
    if (AppHelpers.isValidIpAddress(range)) {
      ipAddresses.add(range);
      return ipAddresses;
    }
    
    // Check if it's a range with wildcard (e.g., 192.168.1.*)
    if (range.contains('*')) {
      final parts = range.split('.');
      if (parts.length != 4) {
        return [];
      }
      
      // Replace * with a range of numbers
      for (int i = 0; i < parts.length; i++) {
        if (parts[i] == '*') {
          // For each wildcard position, generate all possible values
          for (int value = 1; value <= 254; value++) {
            final newParts = List<String>.from(parts);
            newParts[i] = value.toString();
            ipAddresses.add(newParts.join('.'));
          }
          break;
        }
      }
      
      return ipAddresses;
    }
    
    // Check if it's a CIDR notation (e.g., 192.168.1.0/24)
    if (range.contains('/')) {
      final parts = range.split('/');
      if (parts.length != 2) {
        return [];
      }
      
      final baseIp = parts[0];
      final prefixLength = int.tryParse(parts[1]);
      
      if (!AppHelpers.isValidIpAddress(baseIp) || prefixLength == null) {
        return [];
      }
      
      // Calculate the number of hosts in this subnet
      final hostCount = pow(2, 32 - prefixLength).toInt() - 2;
      if (hostCount <= 0) {
        return [];
      }
      
      // Convert base IP to integer
      final ipParts = baseIp.split('.').map(int.parse).toList();
      final baseIpInt = (ipParts[0] << 24) + (ipParts[1] << 16) + (ipParts[2] << 8) + ipParts[3];
      
      // Calculate subnet mask
      final mask = ~((1 << (32 - prefixLength)) - 1) & 0xFFFFFFFF;
      
      // Calculate network address
      final networkAddress = baseIpInt & mask;
      
      // Generate all host addresses in this subnet
      for (int i = 1; i <= hostCount; i++) {
        final hostIpInt = networkAddress + i;
        final hostIp = [
          (hostIpInt >> 24) & 0xFF,
          (hostIpInt >> 16) & 0xFF,
          (hostIpInt >> 8) & 0xFF,
          hostIpInt & 0xFF,
        ].join('.');
        
        ipAddresses.add(hostIp);
      }
      
      return ipAddresses;
    }
    
    // Check if it's a range with hyphen (e.g., 192.168.1.1-192.168.1.254)
    if (range.contains('-')) {
      final parts = range.split('-');
      if (parts.length != 2) {
        return [];
      }
      
      final startIp = parts[0].trim();
      final endIp = parts[1].trim();
      
      if (!AppHelpers.isValidIpAddress(startIp) || !AppHelpers.isValidIpAddress(endIp)) {
        return [];
      }
      
      // Convert IPs to integers
      final startParts = startIp.split('.').map(int.parse).toList();
      final endParts = endIp.split('.').map(int.parse).toList();
      
      final startIpInt = (startParts[0] << 24) + (startParts[1] << 16) + (startParts[2] << 8) + startParts[3];
      final endIpInt = (endParts[0] << 24) + (endParts[1] << 16) + (endParts[2] << 8) + endParts[3];
      
      if (startIpInt > endIpInt) {
        return [];
      }
      
      // Generate all IPs in the range
      for (int i = startIpInt; i <= endIpInt; i++) {
        final ip = [
          (i >> 24) & 0xFF,
          (i >> 16) & 0xFF,
          (i >> 8) & 0xFF,
          i & 0xFF,
        ].join('.');
        
        ipAddresses.add(ip);
      }
      
      return ipAddresses;
    }
    
    // If none of the above, try to determine local network
    final localRange = await _networkService.getLocalIpRange();
    if (localRange != null) {
      return await _parseNetworkRange(localRange);
    }
    
    return [];
  }

  // Scan a single host
  Future<models.NetworkDevice?> _scanHost(String ip, NetworkScanConfig config) async {
    try {
      // Ping the host to check if it's online
      final pingResult = await _networkService.pingHost(
        ip, 
        timeout: config.timeout,
      );
      
      if (!pingResult.isSuccess) {
        return null; // Host is not reachable
      }
      
      // Create a basic device entry
      final device = models.NetworkDevice(
        id: ip,
        name: ip, // Will be updated with hostname if resolved
        discoveredAt: DateTime.now(),
        ipAddress: ip,
        isOnline: true,
        metadata: {
          'responseTime': pingResult.responseTime,
        },
      );
      
      // Try to resolve hostname if configured
      if (config.resolveHostnames) {
        try {
          final addresses = await _networkService.lookupHost(ip);
          if (addresses.isNotEmpty && addresses.first.host != ip) {
            final hostname = addresses.first.host;
            return device.copyWith(
              name: hostname,
              metadata: {
                ...device.metadata,
                'hostname': hostname,
              },
            );
          }
        } catch (e) {
          // Hostname resolution failed, continue with IP as name
        }
      }
      
      // Scan ports if configured
      if (config.scanPorts && config.portsToScan.isNotEmpty) {
        final openPorts = <int>[];
        final services = <String, String>{};
        
        for (final port in config.portsToScan) {
          final portResult = await _networkService.scanPort(
            ip, 
            port,
            timeout: config.timeout ~/ 2, // Use shorter timeout for port scans
          );
          
          if (portResult.status == models.ServiceStatus.open) {
            openPorts.add(port);
            if (portResult.serviceName != null) {
              services[port.toString()] = portResult.serviceName!;
            }
          }
        }
        
        if (openPorts.isNotEmpty) {
          return device.copyWith(
            metadata: {
              ...device.metadata,
              'openPorts': openPorts,
              'services': services,
            },
          );
        }
      }
      
      return device;
    } catch (e) {
      debugPrint('Error scanning host $ip: $e');
      return null;
    }
  }

  // Complete the scan with an error
  void _completeWithError(String errorMessage) {
    _currentScan = _currentScan!.copyWith(
      endTime: DateTime.now(),
      status: ScanStatus.failed,
      errorMessage: errorMessage,
    );
    
    _scanProgressController.add(_currentScan!);
    _currentScan = null;
  }

  // Complete the scan successfully
  void _completeScan(ScanStatus status) {
    _currentScan = _currentScan!.copyWith(
      endTime: DateTime.now(),
      status: status,
    );
    
    _scanProgressController.add(_currentScan!);
    _currentScan = null;
  }

  // Dispose resources
  void dispose() {
    _scanProgressController.close();
  }
}