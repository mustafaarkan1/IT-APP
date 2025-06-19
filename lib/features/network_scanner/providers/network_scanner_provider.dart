import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/network_scan_result.dart';
import '../services/network_scanner_service.dart';

class NetworkScannerProvider extends ChangeNotifier {
  final NetworkScannerService _scannerService = NetworkScannerService();
  final StorageService _storageService = StorageService();
  final PermissionService _permissionService = PermissionService();

  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isLoadingHistory = true;
  String? _error;

  NetworkScanResult? _lastScanResult;
  NetworkScanResult? _currentScanProgress;
  List<NetworkScanResult> _scanHistory = [];

  StreamSubscription<NetworkScanResult>? _scanProgressSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  String? get error => _error;
  bool get isScanning => _scannerService.isScanning;
  NetworkScanResult? get lastScanResult => _lastScanResult;
  NetworkScanResult? get currentScanProgress => _currentScanProgress;
  List<NetworkScanResult> get scanHistory => _scanHistory;

  // Initialize the provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check required permissions
      final hasPermissions = await _checkPermissions();
      if (!hasPermissions) {
        _error = 'Required permissions not granted';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Subscribe to scan progress updates
      _scanProgressSubscription = _scannerService.scanProgressStream.listen(_onScanProgressUpdate);

      // Load scan history
      await _loadScanHistory();

      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Check required permissions
  Future<bool> _checkPermissions() async {
    try {
      // For network scanning, we typically need location permission on mobile devices
      // because WiFi scanning requires it
      return await _permissionService.checkAndRequestLocationPermission();
    } catch (e) {
      debugPrint('Error checking permissions: $e');
      return false;
    }
  }

  // Load scan history from storage
  Future<void> _loadScanHistory() async {
    _isLoadingHistory = true;
    notifyListeners();

    try {
      final box = await _storageService.openScanHistoryBox();
      final historyData = box.values.toList();

      _scanHistory = historyData
          .map((data) => NetworkScanResult.fromJson(Map<String, dynamic>.from(data)))
          .toList();

      // Sort by start time, most recent first
      _scanHistory.sort((a, b) => b.startTime.compareTo(a.startTime));

      // If there's a recent scan, set it as the last result
      if (_scanHistory.isNotEmpty && _lastScanResult == null) {
        _lastScanResult = _scanHistory.first;
      }

      _isLoadingHistory = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading scan history: $e');
      _isLoadingHistory = false;
      _scanHistory = [];
      notifyListeners();
    }
  }

  // Start a new network scan
  Future<void> startScan(NetworkScanConfig config) async {
    if (isScanning) {
      return;
    }

    try {
      // Reset current state
      _currentScanProgress = null;
      _error = null;
      notifyListeners();

      // Start the scan
      await _scannerService.startScan(config);
    } catch (e) {
      _error = 'Failed to start scan: ${e.toString()}';
      notifyListeners();
    }
  }

  // Cancel the current scan
  void cancelScan() {
    if (isScanning) {
      _scannerService.cancelScan();
    }
  }

  // Handle scan progress updates
  void _onScanProgressUpdate(NetworkScanResult progress) {
    _currentScanProgress = progress;
    notifyListeners();

    // If the scan is complete, update the last result and save to history
    if (progress.isComplete) {
      _lastScanResult = progress;
      _saveScanToHistory(progress);
      _currentScanProgress = null;
    }
  }

  // Save a scan result to history
  Future<void> _saveScanToHistory(NetworkScanResult result) async {
    try {
      // Add to local history list
      final existingIndex = _scanHistory.indexWhere((scan) => scan.id == result.id);
      if (existingIndex >= 0) {
        _scanHistory[existingIndex] = result;
      } else {
        _scanHistory.insert(0, result);
      }

      // Sort by start time, most recent first
      _scanHistory.sort((a, b) => b.startTime.compareTo(a.startTime));

      // Limit history size
      if (_scanHistory.length > 20) {
        _scanHistory = _scanHistory.sublist(0, 20);
      }

      notifyListeners();

      // Save to persistent storage
      final box = await _storageService.openScanHistoryBox();
      await box.put(result.id, result.toJson());
    } catch (e) {
      debugPrint('Error saving scan to history: $e');
    }
  }

  // Set a specific scan result as the current one (for viewing from history)
  void setLastScanResult(NetworkScanResult result) {
    _lastScanResult = result;
    notifyListeners();
  }

  // Clear scan history
  Future<void> clearScanHistory() async {
    try {
      final box = await _storageService.openScanHistoryBox();
      await box.clear();
      _scanHistory = [];
      _lastScanResult = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing scan history: $e');
    }
  }

  @override
  void dispose() {
    _scanProgressSubscription?.cancel();
    super.dispose();
  }
}