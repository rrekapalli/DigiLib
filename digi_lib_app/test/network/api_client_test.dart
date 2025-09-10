import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/network/api_client.dart';

void main() {
  group('ApiClientConfig', () {
    test('should create config with default values', () {
      const config = ApiClientConfig(baseUrl: 'https://api.example.com');
      
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.connectTimeout, const Duration(seconds: 30));
      expect(config.receiveTimeout, const Duration(seconds: 30));
      expect(config.sendTimeout, const Duration(seconds: 30));
      expect(config.maxRetries, 3);
      expect(config.retryDelay, const Duration(seconds: 1));
    });

    test('should create config with custom values', () {
      const config = ApiClientConfig(
        baseUrl: 'https://api.example.com',
        connectTimeout: Duration(seconds: 10),
        receiveTimeout: Duration(seconds: 20),
        sendTimeout: Duration(seconds: 15),
        maxRetries: 5,
        retryDelay: Duration(seconds: 2),
        enableLogging: false,
      );
      
      expect(config.baseUrl, 'https://api.example.com');
      expect(config.connectTimeout, const Duration(seconds: 10));
      expect(config.receiveTimeout, const Duration(seconds: 20));
      expect(config.sendTimeout, const Duration(seconds: 15));
      expect(config.maxRetries, 5);
      expect(config.retryDelay, const Duration(seconds: 2));
      expect(config.enableLogging, false);
    });
  });

  group('DioApiClient', () {
    late DioApiClient apiClient;
    late ApiClientConfig config;

    setUp(() {
      config = const ApiClientConfig(
        baseUrl: 'https://api.example.com',
        enableLogging: false,
      );
      apiClient = DioApiClient(config);
    });

    test('should initialize with correct base URL', () {
      expect(apiClient.baseUrl, 'https://api.example.com');
    });

    test('should not have auth token initially', () {
      expect(apiClient.hasAuthToken, false);
    });

    test('should set and clear auth token', () {
      const token = 'test-token';
      
      apiClient.setAuthToken(token);
      expect(apiClient.hasAuthToken, true);
      
      apiClient.clearAuthToken();
      expect(apiClient.hasAuthToken, false);
    });

    // Note: Error handling is tested through integration tests
    // since the error handling methods are private
  });
}