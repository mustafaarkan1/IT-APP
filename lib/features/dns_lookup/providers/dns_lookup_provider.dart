import 'package:flutter/foundation.dart';

import '../../../core/services/network_service.dart';

class DnsLookupProvider extends ChangeNotifier {
  final NetworkService _networkService = NetworkService();
  
  bool _isLoading = false;
  String? _error;
  Map<String, List<String>> _results = {};
  String _lastDomain = '';
  String _lastRecordType = '';

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, List<String>> get results => _results;
  String get lastDomain => _lastDomain;
  String get lastRecordType => _lastRecordType;

  Future<void> performLookup(String domain, String recordType) async {
    if (domain.isEmpty) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _lastDomain = domain;
      _lastRecordType = recordType;
      
      final results = await _networkService.performDnsLookup(domain, recordType);
      
      if (results.isEmpty) {
        _error = 'No DNS records found for $domain with record type $recordType';
        _results = {};
      } else {
        _results = results;
      }
    } catch (e) {
      _error = 'Error performing DNS lookup: ${e.toString()}';
      _results = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _results = {};
    _error = null;
    notifyListeners();
  }
}