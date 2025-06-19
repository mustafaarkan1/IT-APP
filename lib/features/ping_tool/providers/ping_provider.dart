// تعديل الاستيرادات لحل مشكلة الاستيراد المبهم
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/network_entity.dart' hide NetworkService; // إخفاء NetworkService من هذا الاستيراد
import '../../../core/services/network_service.dart'; // استخدام NetworkService من هذا الاستيراد فقط
import '../../../core/services/permission_service.dart';
import '../../../core/services/storage_service.dart';

class PingProvider extends ChangeNotifier {
  // إصلاح تعريف NetworkService - إزالة التحويل غير الضروري
  final NetworkService _networkService = NetworkService();
  final PermissionService _permissionService = PermissionService();
  final StorageService _storageService = StorageService();

  bool _isInitialized = false;
  bool _isLoading = true;
  bool _isPinging = false;
  int _currentPingCount = 0;
  int _totalPingCount = 0;
  PingResult? _currentResult;
  List<PingResult> _pingHistory = [];
  StreamSubscription? _pingSubscription;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isPinging => _isPinging;
  int get currentPingCount => _currentPingCount;
  int get totalPingCount => _totalPingCount;
  PingResult? get currentResult => _currentResult;
  List<PingResult> get pingHistory => List.unmodifiable(_pingHistory);

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isLoading = true;
    notifyListeners();

    try {
      // استخدام الطرق المتاحة في PermissionService
      final hasPermission = await _permissionService.checkLocationPermission();
      if (!hasPermission) {
        await _permissionService.checkAndRequestLocationPermission();
      }

      await _loadPingHistory();
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing PingProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadPingHistory() async {
    try {
      final data = await _storageService.getData('ping_history', 'history', defaultValue: <dynamic>[]);
      _pingHistory = (data as List)
          .map((item) => PingResult.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      debugPrint('Error loading ping history: $e');
      _pingHistory = [];
    }
    notifyListeners();
  }

  Future<void> _savePingHistory() async {
    try {
      final data = _pingHistory.map((result) => result.toJson()).toList();
      await _storageService.saveData('ping_history', 'history', data);
    } catch (e) {
      debugPrint('Error saving ping history: $e');
    }
  }

  // تعديل طريقة startPing لاستخدام pingHost بدلاً من ping
  Future<void> startPing(String target, {int count = 4, int timeout = 1000}) async {
    if (_isPinging) return;
    _isPinging = true;
    _currentPingCount = 0;
    _totalPingCount = count;
    
    _currentResult = PingResult(
      host: target,
      isSuccess: false,
      timestamp: DateTime.now(),
      packetsSent: 0,
      packetsReceived: 0,
      responseTimes: [],
    );
    
    notifyListeners();
    
    final controller = StreamController<int?>();
      
    // تنفيذ عمليات ping متعددة يدوياً
    _pingSubscription = Stream.periodic(const Duration(seconds: 1), (i) => i)
        .take(count)
        .listen((i) async {
          try {
            final result = await _networkService.pingHost(target, timeout: timeout);
            _currentPingCount++;
            
            // تحديث النتائج الحالية
            final currentResponseTimes = List<int?>.from(_currentResult!.responseTimes);
            currentResponseTimes.add(result.isSuccess ? result.responseTime?.toInt() : null);
            
            _currentResult = PingResult(
              host: target,
              isSuccess: _currentResult!.isSuccess || result.isSuccess,
              timestamp: _currentResult!.timestamp,
              packetsSent: _currentPingCount,
              packetsReceived: result.isSuccess ? _currentResult!.packetsReceived + 1 : _currentResult!.packetsReceived,
              responseTimes: currentResponseTimes,
              minResponseTime: _currentResult!.minResponseTime,
              maxResponseTime: _currentResult!.maxResponseTime,
              avgResponseTime: _currentResult!.avgResponseTime,
            );
            
            controller.add(result.isSuccess ? result.responseTime?.toInt() : null);
            notifyListeners();
          } catch (e) {
            controller.addError(e);
          }
          
          if (_currentPingCount >= count) {
            _completePing();
            controller.close();
          }
        });
  }

  void stopPing() {
    if (!_isPinging) return;

    _pingSubscription?.cancel();
    // NetworkService doesn't have cancelPing method, so we'll just cancel the subscription
    _pingSubscription?.cancel();
    _completePing();
  }

  void _completePing() {
    if (_currentResult != null) {
      // حساب نسبة فقدان الحزم
      final packetLoss = _currentResult!.packetsSent > 0
          ? 100 - ((_currentResult!.packetsReceived / _currentResult!.packetsSent) * 100)
          : 0.0;
      
      // إنشاء نسخة جديدة من النتيجة بدلاً من استخدام copyWith
      final receivedTimes = _currentResult!.responseTimes.where((t) => t != null).map((t) => t!).toList();
      if (receivedTimes.isNotEmpty) {
        _currentResult = PingResult(
          host: _currentResult!.host,
          ipAddress: _currentResult!.ipAddress,
          isSuccess: _currentResult!.isSuccess,
          responseTime: _currentResult!.responseTime,
          errorMessage: _currentResult!.errorMessage,
          timestamp: _currentResult!.timestamp,
          packetsSent: _currentResult!.packetsSent,
          packetsReceived: _currentResult!.packetsReceived,
          packetLoss: packetLoss,
          responseTimes: _currentResult!.responseTimes,
          minResponseTime: receivedTimes.reduce((a, b) => a < b ? a : b),
          maxResponseTime: receivedTimes.reduce((a, b) => a > b ? a : b),
          avgResponseTime: receivedTimes.reduce((a, b) => a + b) / receivedTimes.length,
        );
      }
    }
    
    // إضافة النتيجة إلى التاريخ إذا كانت ناجحة
    if (_currentResult != null && _currentResult!.isSuccess) {
      _pingHistory.add(_currentResult!);
      _savePingHistory();
    }
    
    _isPinging = false;
    notifyListeners();
  }

  void clearCurrentResults() {
    if (_isPinging) {
      stopPing();
    }
    
    _currentResult = null;
    notifyListeners();
  }

  void deleteHistoryItem(PingResult result) {
    _pingHistory.remove(result);
    _savePingHistory();
    notifyListeners();
  }

  void clearHistory() {
    _pingHistory = [];
    // تعديل استخدام deleteFromBox إلى deleteData
    _storageService.deleteData('ping_history', 'history');
    notifyListeners();
  }

  @override
  void dispose() {
    _pingSubscription?.cancel();
    super.dispose();
  }
}