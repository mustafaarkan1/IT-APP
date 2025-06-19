import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/network_entity.dart' hide NetworkService; // إخفاء NetworkService من هذا الاستيراد
import '../../../core/services/network_service.dart'; // استخدام NetworkService من هذا الاستيراد فقط
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/port_scan_config.dart';

class PortScannerProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService(); // إزالة الأقواس الإضافية
  final PermissionService _permissionService = PermissionService();
  final StorageService _storageService = StorageService();

  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isScanning = false;
  double _progress = 0.0;
  int _scannedCount = 0;
  int _totalCount = 0;
  List<PortScanResult> _scanResults = [];
  PortScanConfig? _lastScanConfig;
  DateTime? _scanStartTime;
  DateTime? _scanEndTime;
  StreamSubscription? _scanSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isScanning => _isScanning;
  double get progress => _progress;
  int get scannedCount => _scannedCount;
  int get totalCount => _totalCount;
  List<PortScanResult> get scanResults => List.unmodifiable(_scanResults);
  PortScanConfig? get lastScanConfig => _lastScanConfig;
  Duration? get scanDuration {
    if (_scanStartTime == null || _scanEndTime == null) return null;
    return _scanEndTime!.difference(_scanStartTime!);
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // استخدام الطرق المتاحة في PermissionService
      final hasPermissions = await _permissionService.checkLocationPermission();
      if (!hasPermissions) {
        await _permissionService.checkAndRequestLocationPermission();
      }

      // Initialize storage service if needed
      await _storageService.init();

      // Load previous scan results if available
      await _loadSavedResults();

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing port scanner: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadSavedResults() async {
    try {
      final savedResults = await _storageService.getData(
        'port_scan_results',
        'results',
        defaultValue: null,
      );

      if (savedResults != null) {
        final config = PortScanConfig.fromJson(
          savedResults['config'] as Map<String, dynamic>,
        );
        _lastScanConfig = config;

        final resultsList = (savedResults['results'] as List<dynamic>)
            .map((e) => PortScanResult.fromJson(e as Map<String, dynamic>))
            .toList();
        _scanResults = resultsList;

        if (savedResults.containsKey('startTime') && savedResults.containsKey('endTime')) {
          _scanStartTime = DateTime.parse(savedResults['startTime'] as String);
          _scanEndTime = DateTime.parse(savedResults['endTime'] as String);
        }
      }
    } catch (e) {
      debugPrint('Error loading saved port scan results: $e');
    }
  }

  Future<void> _saveResults() async {
    if (_lastScanConfig == null) return;

    try {
      final resultsToSave = {
        'config': _lastScanConfig!.toJson(),
        'results': _scanResults.map((e) => e.toJson()).toList(),
        'startTime': _scanStartTime?.toIso8601String(),
        'endTime': _scanEndTime?.toIso8601String(),
      };

      await _storageService.saveData('port_scan_results', 'results', resultsToSave);
    } catch (e) {
      debugPrint('Error saving port scan results: $e');
    }
  }

  Future<void> startScan(PortScanConfig config) async {
    if (_isScanning) return;

    _isScanning = true;
    _progress = 0.0;
    _scannedCount = 0;
    _totalCount = config.ports.length;
    _scanResults = [];
    _lastScanConfig = config;
    _scanStartTime = DateTime.now();
    _scanEndTime = null;
    notifyListeners();

    try {
      // استخدام scanPortRange بدلاً من scanPorts
      final results = await _networkService.scanPortRange(
        config.ipAddress,
        config.ports.first,
        config.ports.last,
        timeout: config.timeout,
        maxConcurrent: config.threadCount,
        progressCallback: (scanned, total) {
          _scannedCount = scanned;
          _progress = scanned / total;
          notifyListeners();
        },
      );
      
      // تصفية النتائج للصول فقط على المنافذ المطلوبة
      _scanResults = results.where((result) => config.ports.contains(result.port)).toList();
      _completeScan();
    } catch (e) {
      debugPrint('Error starting port scan: $e');
      _completeScan();
    }
  }

  void cancelScan() {
    if (!_isScanning) return;

    _scanSubscription?.cancel();
    // لا نحتاج إلى استدعاء cancelPortScan لأننا نستخدم scanPortRange
    _completeScan();
  }

  void _completeScan() {
    _isScanning = false;
    _scanEndTime = DateTime.now();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    
    // Sort results by port number
    _scanResults.sort((a, b) => a.port.compareTo(b.port));
    
    // Save results
    _saveResults();
    
    notifyListeners();
  }

  void clearResults() {
    if (_isScanning) {
      cancelScan();
    }
    
    _scanResults = [];
    _lastScanConfig = null;
    _scanStartTime = null;
    _scanEndTime = null;
    _progress = 0.0;
    _scannedCount = 0;
    _totalCount = 0;
    
    // Clear saved results
    _storageService.deleteData('port_scan_results', 'results');
    
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    super.dispose();
  }
}