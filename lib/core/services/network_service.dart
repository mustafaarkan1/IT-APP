import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';

import '../models/network_entity.dart';
import '../utils/helpers.dart';

class NetworkService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();
  
  // Singleton pattern
  static final NetworkService _instance = NetworkService._internal();
  
  factory NetworkService() => _instance;
  
  NetworkService._internal();

  // Stream controller for connectivity changes
  final StreamController<List<ConnectivityResult>> _connectivityController = 
      StreamController<List<ConnectivityResult>>.broadcast();

  Stream<List<ConnectivityResult>> get connectivityStream => _connectivityController.stream;

  // Initialize the service
  Future<void> init() async {
    // Listen for connectivity changes
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _connectivityController.add(result);
    });
    
    // Add initial connectivity state
    final initialConnectivity = await _connectivity.checkConnectivity();
    _connectivityController.add(initialConnectivity);
  }

  // Get current connectivity status
  Future<List<ConnectivityResult>> getConnectivityStatus() async {
    return await _connectivity.checkConnectivity();
  }

  // Check if device is connected to the internet
  Future<bool> isConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    return !connectivityResult.contains(ConnectivityResult.none) || connectivityResult.isNotEmpty;
  }

  // Get current WiFi information
  Future<Map<String, String?>> getWifiInfo() async {
    try {
      final wifiName = await _networkInfo.getWifiName(); // "FooNetwork"
      final wifiBSSID = await _networkInfo.getWifiBSSID(); // "11:22:33:44:55:66"
      final wifiIP = await _networkInfo.getWifiIP(); // "192.168.1.1"
      final wifiIPv6 = await _networkInfo.getWifiIPv6(); // "2001:0db8:85a3:0000:0000:8a2e:0370:7334"
      final wifiSubmask = await _networkInfo.getWifiSubmask(); // "255.255.255.0"
      final wifiBroadcast = await _networkInfo.getWifiBroadcast(); // "192.168.1.255"
      final wifiGateway = await _networkInfo.getWifiGatewayIP(); // "192.168.1.1"

      return {
        'name': wifiName,
        'bssid': wifiBSSID,
        'ip': wifiIP,
        'ipv6': wifiIPv6,
        'submask': wifiSubmask,
        'broadcast': wifiBroadcast,
        'gateway': wifiGateway,
      };
    } catch (e) {
      debugPrint('Error getting WiFi info: $e');
      return {};
    }
  }

  // Ping a host and return the result
  Future<PingResult> pingHost(String host, {int timeout = 5000}) async {
    final timestamp = DateTime.now();
    
    try {
      // Validate the host
      if (!AppHelpers.isValidIpAddress(host) && !AppHelpers.isValidDomain(host)) {
        return PingResult(
          host: host,
          isSuccess: false,
          errorMessage: 'Invalid host format',
          timestamp: timestamp,
        );
      }

      final stopwatch = Stopwatch()..start();
      
      // Create a socket connection to test reachability
      final socket = await Socket.connect(
        host, 
        80, // Using port 80 (HTTP) as a common open port
        timeout: Duration(milliseconds: timeout),
      );
      
      socket.destroy();
      stopwatch.stop();
      
      return PingResult(
        host: host,
        isSuccess: true,
        responseTime: stopwatch.elapsedMilliseconds.toDouble(),
        timestamp: timestamp,
      );
    } on SocketException catch (e) {
      return PingResult(
        host: host,
        isSuccess: false,
        errorMessage: e.message,
        timestamp: timestamp,
      );
    } catch (e) {
      return PingResult(
        host: host,
        isSuccess: false,
        errorMessage: e.toString(),
        timestamp: timestamp,
      );
    }
  }

  // Scan a port on a host
  Future<PortScanResult> scanPort(String host, int port, {String protocol = 'TCP', int timeout = 3000}) async {
    final timestamp = DateTime.now();
    final stopwatch = Stopwatch()..start();
    
    try {
      // Validate the host and port
      if (!AppHelpers.isValidIpAddress(host) && !AppHelpers.isValidDomain(host)) {
        return PortScanResult(
          host: host,
          port: port,
          protocol: protocol,
          status: ServiceStatus.unknown,
          scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: timestamp,
        );
      }

      if (!AppHelpers.isValidPort(port.toString())) {
        return PortScanResult(
          host: host,
          port: port,
          protocol: protocol,
          status: ServiceStatus.unknown,
          scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: timestamp,
        );
      }

      // Currently only TCP scanning is implemented
      if (protocol.toUpperCase() == 'TCP') {
        final socket = await Socket.connect(
          host, 
          port,
          timeout: Duration(milliseconds: timeout),
        );
        
        socket.destroy();
        stopwatch.stop();
        
        // Try to determine service name based on common ports
        final serviceName = _getServiceNameByPort(port);
        
        return PortScanResult(
          host: host,
          port: port,
          protocol: protocol,
          status: ServiceStatus.open,
          serviceName: serviceName,
          scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: timestamp,
        );
      } else {
        // UDP scanning would be implemented here
        return PortScanResult(
          host: host,
          port: port,
          protocol: protocol,
          status: ServiceStatus.unknown,
          scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
          timestamp: timestamp,
        );
      }
    } on SocketException {
      stopwatch.stop();
      return PortScanResult(
        host: host,
        port: port,
        protocol: protocol,
        status: ServiceStatus.closed,
        scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
        timestamp: timestamp,
      );
    } catch (e) {
      stopwatch.stop();
      return PortScanResult(
        host: host,
        port: port,
        protocol: protocol,
        status: ServiceStatus.unknown,
        scanDuration: stopwatch.elapsedMilliseconds.toDouble(),
        timestamp: timestamp,
      );
    }
  }

  // Get service name by port number
  String? _getServiceNameByPort(int port) {
    final commonPorts = {
      21: 'FTP',
      22: 'SSH',
      23: 'Telnet',
      25: 'SMTP',
      53: 'DNS',
      80: 'HTTP',
      110: 'POP3',
      123: 'NTP',
      143: 'IMAP',
      443: 'HTTPS',
      465: 'SMTPS',
      587: 'SMTP (Submission)',
      993: 'IMAPS',
      995: 'POP3S',
      3306: 'MySQL',
      3389: 'RDP',
      5900: 'VNC',
      8080: 'HTTP Proxy',
    };
    
    return commonPorts[port];
  }

  // Scan a range of ports on a host
  Future<List<PortScanResult>> scanPortRange(
    String host, 
    int startPort, 
    int endPort, {
    String protocol = 'TCP',
    int timeout = 3000,
    int maxConcurrent = 10,
    Function(int scanned, int total)? progressCallback,
  }) async {
    final results = <PortScanResult>[];
    
    // Validate port range
    if (startPort < 1 || endPort > 65535 || startPort > endPort) {
      return results;
    }
    
    final totalPorts = endPort - startPort + 1;
    int scanned = 0;
    
    // Create batches of ports to scan concurrently
    for (int i = startPort; i <= endPort; i += maxConcurrent) {
      final endBatch = (i + maxConcurrent - 1) > endPort ? endPort : (i + maxConcurrent - 1);
      final batch = List<int>.generate(endBatch - i + 1, (index) => i + index);
      
      // Scan ports in this batch concurrently
      final batchResults = await Future.wait(
        batch.map((port) => scanPort(host, port, protocol: protocol, timeout: timeout))
      );
      
      results.addAll(batchResults);
      
      // Update progress
      scanned += batch.length;
      progressCallback?.call(scanned, totalPorts);
    }
    
    return results;
  }

  // Perform a DNS lookup
  Future<List<InternetAddress>> lookupHost(String host) async {
    try {
      if (!AppHelpers.isValidDomain(host) && !AppHelpers.isValidIpAddress(host)) {
        return [];
      }
      
      return await InternetAddress.lookup(host);
    } catch (e) {
      debugPrint('DNS lookup error: $e');
      return [];
    }
  }

  // Get local IP address range based on current IP
  Future<String?> getLocalIpRange() async {
    try {
      final wifiInfo = await getWifiInfo();
      final localIp = wifiInfo['ip'];
      final subnet = wifiInfo['submask'];
      
      if (localIp == null || subnet == null) {
        return null;
      }
      
      // Extract network portion based on subnet mask
      final ipParts = localIp.split('.');
      final subnetParts = subnet.split('.');
      
      if (ipParts.length != 4 || subnetParts.length != 4) {
        return null;
      }
      
      final networkParts = List<int>.filled(4, 0);
      
      for (int i = 0; i < 4; i++) {
        final ipOctet = int.parse(ipParts[i]);
        final subnetOctet = int.parse(subnetParts[i]);
        networkParts[i] = ipOctet & subnetOctet;
      }
      
      return '${networkParts[0]}.${networkParts[1]}.${networkParts[2]}.*';
    } catch (e) {
      debugPrint('Error getting local IP range: $e');
      return null;
    }
  }

  // Perform DNS lookup with specific record type
  Future<Map<String, List<String>>> performDnsLookup(String domain, String recordType) async {
    try {
      if (!AppHelpers.isValidDomain(domain) && !AppHelpers.isValidIpAddress(domain)) {
        return {};
      }
      
      // Use the existing lookupHost method for basic resolution
      final addresses = await lookupHost(domain);
      
      // Create result map
      final Map<String, List<String>> results = {};
      
      // Handle different record types
      switch (recordType) {
        case 'A':
          // A records (IPv4 addresses)
          results['A'] = addresses
              .where((addr) => addr.type == InternetAddressType.IPv4)
              .map((addr) => addr.address)
              .toList();
          break;
        case 'AAAA':
          // AAAA records (IPv6 addresses)
          results['AAAA'] = addresses
              .where((addr) => addr.type == InternetAddressType.IPv6)
              .map((addr) => addr.address)
              .toList();
          break;
        case 'ANY':
          // Both IPv4 and IPv6 addresses
          results['A'] = addresses
              .where((addr) => addr.type == InternetAddressType.IPv4)
              .map((addr) => addr.address)
              .toList();
          results['AAAA'] = addresses
              .where((addr) => addr.type == InternetAddressType.IPv6)
              .map((addr) => addr.address)
              .toList();
          break;
        default:
          // For other record types (MX, TXT, CNAME, etc.)
          // Note: Dart's InternetAddress.lookup doesn't support these directly
          // You would need a DNS library or platform-specific code for full DNS record support
          results[recordType] = ['Record type $recordType not supported in this implementation'];
      }
      
      return results;
    } catch (e) {
      debugPrint('DNS lookup error: $e');
      return {};
    }
  }

  // Dispose resources
  void dispose() {
    _connectivityController.close();
  }

  // Get available WiFi networks
  Future<List<WifiNetwork>> getWifiNetworks() async {
    try {
      // This is a placeholder implementation
      // You'll need to use platform-specific code or a plugin to get actual WiFi networks
      // For example, you might use wifi_scan or wifi_iot package
      
      // For now, return a sample network for testing
      final wifiInfo = await getWifiInfo();
      
      return [
        WifiNetwork(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: wifiInfo['name'] ?? 'Unknown Network',
          discoveredAt: DateTime.now(),
          ssid: wifiInfo['name']?.replaceAll('"', '') ?? 'Unknown SSID',
          bssid: wifiInfo['bssid'] ?? '00:00:00:00:00:00',
          signalStrength: -65, // Sample value
          channel: 6, // Sample value
          frequency: '2400', // Sample value in MHz
          securityType: 'WPA2',
          isConnected: true,
          metadata: {
            'vendor': 'Unknown',
          },
        ),
      ];
    } catch (e) {
      debugPrint('Error getting WiFi networks: $e');
      return [];
    }
  }
}