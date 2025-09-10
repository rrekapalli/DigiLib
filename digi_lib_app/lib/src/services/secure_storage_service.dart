import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data like tokens and configuration
/// Uses platform-specific secure storage (Keychain on iOS, Keystore on Android, etc.)
class SecureStorageService {
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _serverConfigKey = 'server_config';
  static const String _encryptionKeyKey = 'encryption_key';

  late final FlutterSecureStorage _storage;

  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
      lOptions: LinuxOptions(),
      wOptions: WindowsOptions(
        useBackwardCompatibility: false,
      ),
      mOptions: MacOsOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
        synchronizable: false,
      ),
    );
  }

  /// Store refresh token securely
  Future<void> storeRefreshToken(String token) async {
    try {
      await _storage.write(key: _refreshTokenKey, value: token);
    } catch (e) {
      throw SecureStorageException('Failed to store refresh token: $e');
    }
  }

  /// Retrieve refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve refresh token: $e');
    }
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    try {
      await _storage.delete(key: _refreshTokenKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear refresh token: $e');
    }
  }

  /// Store user ID
  Future<void> storeUserId(String userId) async {
    try {
      await _storage.write(key: _userIdKey, value: userId);
    } catch (e) {
      throw SecureStorageException('Failed to store user ID: $e');
    }
  }

  /// Retrieve user ID
  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _userIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve user ID: $e');
    }
  }

  /// Clear user ID
  Future<void> clearUserId() async {
    try {
      await _storage.delete(key: _userIdKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear user ID: $e');
    }
  }

  /// Store server configuration (API endpoints, etc.)
  Future<void> storeServerConfig(Map<String, dynamic> config) async {
    try {
      final configJson = jsonEncode(config);
      await _storage.write(key: _serverConfigKey, value: configJson);
    } catch (e) {
      throw SecureStorageException('Failed to store server config: $e');
    }
  }

  /// Retrieve server configuration
  Future<Map<String, dynamic>?> getServerConfig() async {
    try {
      final configJson = await _storage.read(key: _serverConfigKey);
      if (configJson == null) return null;
      return jsonDecode(configJson) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException('Failed to retrieve server config: $e');
    }
  }

  /// Clear server configuration
  Future<void> clearServerConfig() async {
    try {
      await _storage.delete(key: _serverConfigKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear server config: $e');
    }
  }

  /// Store encryption key for local data
  Future<void> storeEncryptionKey(String key) async {
    try {
      await _storage.write(key: _encryptionKeyKey, value: key);
    } catch (e) {
      throw SecureStorageException('Failed to store encryption key: $e');
    }
  }

  /// Retrieve encryption key for local data
  Future<String?> getEncryptionKey() async {
    try {
      return await _storage.read(key: _encryptionKeyKey);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve encryption key: $e');
    }
  }

  /// Clear encryption key
  Future<void> clearEncryptionKey() async {
    try {
      await _storage.delete(key: _encryptionKeyKey);
    } catch (e) {
      throw SecureStorageException('Failed to clear encryption key: $e');
    }
  }

  /// Clear all stored data (for logout/reset)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException('Failed to clear all secure storage: $e');
    }
  }

  /// Check if secure storage is available on the platform
  Future<bool> isAvailable() async {
    try {
      // Try to write and read a test value
      const testKey = 'availability_test';
      const testValue = 'test';
      
      await _storage.write(key: testKey, value: testValue);
      final result = await _storage.read(key: testKey);
      await _storage.delete(key: testKey);
      
      return result == testValue;
    } catch (e) {
      return false;
    }
  }

  /// Get all stored keys (for debugging/maintenance)
  Future<Set<String>> getAllKeys() async {
    try {
      final allData = await _storage.readAll();
      return allData.keys.toSet();
    } catch (e) {
      throw SecureStorageException('Failed to retrieve all keys: $e');
    }
  }

  /// Check if a specific key exists
  Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      return false;
    }
  }

  /// Store generic secure data with custom key
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException('Failed to store secure data for key $key: $e');
    }
  }

  /// Retrieve generic secure data with custom key
  Future<String?> getSecureData(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to retrieve secure data for key $key: $e');
    }
  }

  /// Delete generic secure data with custom key
  Future<void> deleteSecureData(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Failed to delete secure data for key $key: $e');
    }
  }

  /// Generic read method (alias for getSecureData)
  Future<String?> read(String key) async {
    return await getSecureData(key);
  }

  /// Generic write method (alias for storeSecureData)
  Future<void> write(String key, String value) async {
    await storeSecureData(key, value);
  }

  /// Generic deleteAll method (alias for clearAll)
  Future<void> deleteAll() async {
    await clearAll();
  }
}

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  final String message;
  
  const SecureStorageException(this.message);
  
  @override
  String toString() => 'SecureStorageException: $message';
}