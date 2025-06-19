import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../../core/models/network_entity.dart' as models;
import '../../../core/services/network_service.dart';
import '../../../core/services/permission_service.dart';

class WifiAnalyzerProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  final PermissionService _permissionService = PermissionService();
  
  List<models.WifiNetwork> _networks = [];
  bool _isLoading = false;
  String? _error;
  String _lastScanTime = 'Never';
  Timer? _autoRefreshTimer;
  bool _autoRefreshEnabled = false;
  int _autoRefreshInterval = 30; // seconds

  List<models.WifiNetwork> get networks => _networks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get lastScanTime => _lastScanTime;
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  int get autoRefreshInterval => _autoRefreshInterval;

  WifiAnalyzerProvider() {
    _init();
  }

  Future<void> _init() async {
    await _checkPermissions();
    await scanWifiNetworks();
  }

  Future<void> _checkPermissions() async {
    try {
      final hasPermissions = await _permissionService.checkAndRequestLocationPermission();
      if (!hasPermissions) {
        _error = 'Location permission is required to scan WiFi networks';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error checking permissions: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> scanWifiNetworks() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final hasPermissions = await _permissionService.checkAndRequestLocationPermission();
      if (!hasPermissions) {
        _error = 'Location permission is required to scan WiFi networks';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final networks = await _networkService.getWifiNetworks();
      
      // Sort networks by signal strength (strongest first)
      networks.sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
      
      _networks = networks;
      _lastScanTime = DateFormat('HH:mm:ss').format(DateTime.now());
    } catch (e) {
      _error = 'Error scanning WiFi networks: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleAutoRefresh() {
    _autoRefreshEnabled = !_autoRefreshEnabled;
    
    if (_autoRefreshEnabled) {
      _startAutoRefresh();
    } else {
      _stopAutoRefresh();
    }
    
    notifyListeners();
  }

  void setAutoRefreshInterval(int seconds) {
    if (seconds < 5) seconds = 5; // Minimum 5 seconds
    if (seconds > 300) seconds = 300; // Maximum 5 minutes
    
    _autoRefreshInterval = seconds;
    
    if (_autoRefreshEnabled) {
      _stopAutoRefresh();
      _startAutoRefresh();
    }
    
    notifyListeners();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      Duration(seconds: _autoRefreshInterval),
      (_) => scanWifiNetworks(),
    );
  }

  void _stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  @override
  void dispose() {
    _stopAutoRefresh();
    super.dispose();
  }
}
