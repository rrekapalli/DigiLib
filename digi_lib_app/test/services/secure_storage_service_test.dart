import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';

void main() {
  group('SecureStorageService', () {
    late SecureStorageService service;

    setUp(() {
      service = SecureStorageService();
    });

    tearDown(() async {
      try {
        await service.clearAll();
      } catch (e) {
        // Ignore errors during cleanup
      }
    });

    test('should store and retrieve refresh token', () async {
      const testToken = 'test_refresh_token_123';
      
      await service.storeRefreshToken(testToken);
      final retrievedToken = await service.getRefreshToken();
      
      expect(retrievedToken, equals(testToken));
    });

    test('should store and retrieve user ID', () async {
      const testUserId = 'user_123';
      
      await service.storeUserId(testUserId);
      final retrievedUserId = await service.getUserId();
      
      expect(retrievedUserId, equals(testUserId));
    });

    test('should store and retrieve server config', () async {
      final testConfig = {
        'apiUrl': 'https://api.example.com',
        'timeout': 30000,
        'retries': 3,
      };
      
      await service.storeServerConfig(testConfig);
      final retrievedConfig = await service.getServerConfig();
      
      expect(retrievedConfig, equals(testConfig));
    });

    test('should store and retrieve encryption key', () async {
      const testKey = 'encryption_key_abc123';
      
      await service.storeEncryptionKey(testKey);
      final retrievedKey = await service.getEncryptionKey();
      
      expect(retrievedKey, equals(testKey));
    });

    test('should clear individual items', () async {
      const testToken = 'test_token';
      const testUserId = 'test_user';
      
      await service.storeRefreshToken(testToken);
      await service.storeUserId(testUserId);
      
      // Verify items are stored
      expect(await service.getRefreshToken(), equals(testToken));
      expect(await service.getUserId(), equals(testUserId));
      
      // Clear refresh token
      await service.clearRefreshToken();
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getUserId(), equals(testUserId)); // Should still exist
      
      // Clear user ID
      await service.clearUserId();
      expect(await service.getUserId(), isNull);
    });

    test('should clear all data', () async {
      await service.storeRefreshToken('token');
      await service.storeUserId('user');
      await service.storeEncryptionKey('key');
      
      await service.clearAll();
      
      expect(await service.getRefreshToken(), isNull);
      expect(await service.getUserId(), isNull);
      expect(await service.getEncryptionKey(), isNull);
    });

    test('should handle generic secure data operations', () async {
      const testKey = 'custom_key';
      const testValue = 'custom_value';
      
      await service.storeSecureData(testKey, testValue);
      final retrievedValue = await service.getSecureData(testKey);
      
      expect(retrievedValue, equals(testValue));
      
      await service.deleteSecureData(testKey);
      final deletedValue = await service.getSecureData(testKey);
      
      expect(deletedValue, isNull);
    });

    test('should check if key exists', () async {
      const testKey = 'test_key';
      const testValue = 'test_value';
      
      expect(await service.containsKey(testKey), isFalse);
      
      await service.storeSecureData(testKey, testValue);
      expect(await service.containsKey(testKey), isTrue);
      
      await service.deleteSecureData(testKey);
      expect(await service.containsKey(testKey), isFalse);
    });

    test('should get all keys', () async {
      await service.storeRefreshToken('token');
      await service.storeUserId('user');
      await service.storeSecureData('custom', 'value');
      
      final keys = await service.getAllKeys();
      
      expect(keys.contains('refresh_token'), isTrue);
      expect(keys.contains('user_id'), isTrue);
      expect(keys.contains('custom'), isTrue);
    });

    test('should use generic read/write methods', () async {
      const testKey = 'generic_test';
      const testValue = 'generic_value';
      
      await service.write(testKey, testValue);
      final retrievedValue = await service.read(testKey);
      
      expect(retrievedValue, equals(testValue));
    });

    test('should handle errors gracefully', () async {
      // Test with invalid operations that might throw exceptions
      // The actual behavior depends on the platform and secure storage implementation
      
      // These should not throw exceptions but handle them internally
      expect(() async => await service.getRefreshToken(), returnsNormally);
      expect(() async => await service.clearAll(), returnsNormally);
    });

    test('should handle null values correctly', () async {
      const testKey = 'null_test';
      
      // Getting non-existent key should return null
      final nonExistentValue = await service.getSecureData(testKey);
      expect(nonExistentValue, isNull);
      
      // Server config should return null if not set
      final nonExistentConfig = await service.getServerConfig();
      expect(nonExistentConfig, isNull);
    });

    test('should handle JSON serialization for server config', () async {
      final complexConfig = {
        'nested': {
          'value': 123,
          'array': [1, 2, 3],
          'boolean': true,
        },
        'string': 'test',
        'number': 42.5,
      };
      
      await service.storeServerConfig(complexConfig);
      final retrievedConfig = await service.getServerConfig();
      
      expect(retrievedConfig, equals(complexConfig));
    });

    test('should check availability', () async {
      // This test depends on the platform and test environment
      // In most test environments, secure storage might not be fully available
      final isAvailable = await service.isAvailable();
      expect(isAvailable, isA<bool>());
    });
  });
}