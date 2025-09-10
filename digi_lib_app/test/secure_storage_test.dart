import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('SecureStorageService', () {
    late SecureStorageService secureStorage;

    setUp(() {
      secureStorage = SecureStorageService();
    });

    tearDown(() async {
      // Clean up after each test
      try {
        await secureStorage.clearAll();
      } catch (e) {
        // Ignore cleanup errors in tests
      }
    });

    group('Refresh Token Operations', () {
      test('should store and retrieve refresh token', () async {
        const testToken = 'test_refresh_token_12345';
        
        await secureStorage.storeRefreshToken(testToken);
        final retrievedToken = await secureStorage.getRefreshToken();
        
        expect(retrievedToken, equals(testToken));
      });

      test('should return null when no refresh token is stored', () async {
        final token = await secureStorage.getRefreshToken();
        expect(token, isNull);
      });

      test('should clear refresh token', () async {
        const testToken = 'test_refresh_token_12345';
        
        await secureStorage.storeRefreshToken(testToken);
        await secureStorage.clearRefreshToken();
        final retrievedToken = await secureStorage.getRefreshToken();
        
        expect(retrievedToken, isNull);
      });
    });

    group('User ID Operations', () {
      test('should store and retrieve user ID', () async {
        const testUserId = 'user_123_456_789';
        
        await secureStorage.storeUserId(testUserId);
        final retrievedUserId = await secureStorage.getUserId();
        
        expect(retrievedUserId, equals(testUserId));
      });

      test('should return null when no user ID is stored', () async {
        final userId = await secureStorage.getUserId();
        expect(userId, isNull);
      });

      test('should clear user ID', () async {
        const testUserId = 'user_123_456_789';
        
        await secureStorage.storeUserId(testUserId);
        await secureStorage.clearUserId();
        final retrievedUserId = await secureStorage.getUserId();
        
        expect(retrievedUserId, isNull);
      });
    });

    group('Server Config Operations', () {
      test('should store and retrieve server config', () async {
        final testConfig = {
          'apiUrl': 'https://api.example.com',
          'timeout': 30000,
          'retryAttempts': 3,
        };
        
        await secureStorage.storeServerConfig(testConfig);
        final retrievedConfig = await secureStorage.getServerConfig();
        
        expect(retrievedConfig, equals(testConfig));
      });

      test('should return null when no server config is stored', () async {
        final config = await secureStorage.getServerConfig();
        expect(config, isNull);
      });

      test('should clear server config', () async {
        final testConfig = {
          'apiUrl': 'https://api.example.com',
          'timeout': 30000,
        };
        
        await secureStorage.storeServerConfig(testConfig);
        await secureStorage.clearServerConfig();
        final retrievedConfig = await secureStorage.getServerConfig();
        
        expect(retrievedConfig, isNull);
      });
    });

    group('Encryption Key Operations', () {
      test('should store and retrieve encryption key', () async {
        const testKey = 'encryption_key_abcdef123456';
        
        await secureStorage.storeEncryptionKey(testKey);
        final retrievedKey = await secureStorage.getEncryptionKey();
        
        expect(retrievedKey, equals(testKey));
      });

      test('should return null when no encryption key is stored', () async {
        final key = await secureStorage.getEncryptionKey();
        expect(key, isNull);
      });

      test('should clear encryption key', () async {
        const testKey = 'encryption_key_abcdef123456';
        
        await secureStorage.storeEncryptionKey(testKey);
        await secureStorage.clearEncryptionKey();
        final retrievedKey = await secureStorage.getEncryptionKey();
        
        expect(retrievedKey, isNull);
      });
    });

    group('Generic Secure Data Operations', () {
      test('should store and retrieve generic secure data', () async {
        const testKey = 'custom_key';
        const testValue = 'custom_secure_value';
        
        await secureStorage.storeSecureData(testKey, testValue);
        final retrievedValue = await secureStorage.getSecureData(testKey);
        
        expect(retrievedValue, equals(testValue));
      });

      test('should return null for non-existent key', () async {
        final value = await secureStorage.getSecureData('non_existent_key');
        expect(value, isNull);
      });

      test('should delete generic secure data', () async {
        const testKey = 'custom_key';
        const testValue = 'custom_secure_value';
        
        await secureStorage.storeSecureData(testKey, testValue);
        await secureStorage.deleteSecureData(testKey);
        final retrievedValue = await secureStorage.getSecureData(testKey);
        
        expect(retrievedValue, isNull);
      });
    });

    group('Utility Operations', () {
      test('should check if key exists', () async {
        const testKey = 'test_key';
        const testValue = 'test_value';
        
        // Key should not exist initially
        expect(await secureStorage.containsKey(testKey), isFalse);
        
        // Store data and check again
        await secureStorage.storeSecureData(testKey, testValue);
        expect(await secureStorage.containsKey(testKey), isTrue);
        
        // Delete and check again
        await secureStorage.deleteSecureData(testKey);
        expect(await secureStorage.containsKey(testKey), isFalse);
      });

      test('should get all keys', () async {
        const testData = {
          'key1': 'value1',
          'key2': 'value2',
          'key3': 'value3',
        };
        
        // Store test data
        for (final entry in testData.entries) {
          await secureStorage.storeSecureData(entry.key, entry.value);
        }
        
        final allKeys = await secureStorage.getAllKeys();
        
        // Check that all keys are present
        for (final key in testData.keys) {
          expect(allKeys.contains(key), isTrue);
        }
      });

      test('should clear all data', () async {
        // Store various types of data
        await secureStorage.storeRefreshToken('test_token');
        await secureStorage.storeUserId('test_user');
        await secureStorage.storeServerConfig({'test': 'config'});
        await secureStorage.storeEncryptionKey('test_key');
        await secureStorage.storeSecureData('custom', 'data');
        
        // Clear all
        await secureStorage.clearAll();
        
        // Verify all data is cleared
        expect(await secureStorage.getRefreshToken(), isNull);
        expect(await secureStorage.getUserId(), isNull);
        expect(await secureStorage.getServerConfig(), isNull);
        expect(await secureStorage.getEncryptionKey(), isNull);
        expect(await secureStorage.getSecureData('custom'), isNull);
      });
    });

    group('Error Handling', () {
      test('should handle SecureStorageException', () async {
        // This test verifies that our custom exception is properly defined
        const exception = SecureStorageException('Test error message');
        expect(exception.message, equals('Test error message'));
        expect(exception.toString(), equals('SecureStorageException: Test error message'));
      });
    });
  });
}