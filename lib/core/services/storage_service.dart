import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  
  // Factory constructor
  factory StorageService() => _instance;
  
  // Private constructor
  StorageService._internal();

  // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Encryption key for Hive
  late final Uint8List _encryptionKey;
  
  // Initialize storage service
  Future<void> init() async {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Get or generate encryption key
    await _setupEncryption();
    
    // Open boxes
    await _openBoxes();
  }

  // Setup encryption for Hive
  Future<void> _setupEncryption() async {
    // Try to get existing encryption key
    String? encryptionKeyString = await _secureStorage.read(key: 'hive_encryption_key');
    
    if (encryptionKeyString == null) {
      // Generate a new key if none exists
      final key = Uint8List(32); // 256-bit key
      for (var i = 0; i < key.length; i++) {
        key[i] = i * 2; // Simple key generation, should use a secure random generator in production
      }
      
      // Save the key to secure storage
      await _secureStorage.write(
        key: 'hive_encryption_key',
        value: base64Encode(key),
      );
      
      _encryptionKey = key;
    } else {
      // Use existing key
      _encryptionKey = base64Decode(encryptionKeyString);
    }
  }

  // Open Hive boxes
  Future<void> _openBoxes() async {
    // Open settings box
    await Hive.openBox(
      'settings',
      encryptionCipher: HiveAesCipher(_encryptionKey),
    );
    
    // Open scan history box
    await openScanHistoryBox();
    
    // Open connections box
    await Hive.openBox(
      'connections',
      encryptionCipher: HiveAesCipher(_encryptionKey),
    );
  }

  // Get a Hive box
  Box getBox(String boxName) {
    return Hive.box(boxName);
  }

  // Add this method at the class level
  Future<Box> openScanHistoryBox() async {
    // Check if the box is already open
    if (Hive.isBoxOpen('scan_history')) {
      return Hive.box('scan_history');
    }
    
    // Open the box if it's not already open
    return await Hive.openBox(
      'scan_history',
      encryptionCipher: HiveAesCipher(_encryptionKey),
    );
  }

  // Save data to a box
  Future<void> saveData(String boxName, String key, dynamic value) async {
    final box = getBox(boxName);
    await box.put(key, value);
  }

  // Get data from a box
  dynamic getData(String boxName, String key, {dynamic defaultValue}) {
    final box = getBox(boxName);
    return box.get(key, defaultValue: defaultValue);
  }

  // Delete data from a box
  Future<void> deleteData(String boxName, String key) async {
    final box = getBox(boxName);
    await box.delete(key);
  }

  // Clear all data in a box
  Future<void> clearBox(String boxName) async {
    final box = getBox(boxName);
    await box.clear();
  }

  // Save sensitive data to secure storage
  Future<void> saveSecureData(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  // Get sensitive data from secure storage
  Future<String?> getSecureData(String key) async {
    return await _secureStorage.read(key: key);
  }

  // Delete sensitive data from secure storage
  Future<void> deleteSecureData(String key) async {
    await _secureStorage.delete(key: key);
  }

  // Hash a string (for passwords, etc.)
  String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}