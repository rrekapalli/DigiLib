import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';
import 'package:digi_lib_app/src/network/connectivity_service.dart';
import 'package:digi_lib_app/src/network/api_client.dart';
import 'package:digi_lib_app/src/providers/providers.dart';

/// Mock SecureStorageService for testing
class MockSecureStorageService implements SecureStorageService {
  final Map<String, String> _storage = {};
  bool _shouldThrowError = false;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void clearMockStorage() {
    _storage.clear();
  }

  @override
  Future<void> storeRefreshToken(String token) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage['refresh_token'] = token;
  }

  @override
  Future<String?> getRefreshToken() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage['refresh_token'];
  }

  @override
  Future<void> clearRefreshToken() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove('refresh_token');
  }

  @override
  Future<void> storeUserId(String userId) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage['user_id'] = userId;
  }

  @override
  Future<String?> getUserId() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage['user_id'];
  }

  @override
  Future<void> clearUserId() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove('user_id');
  }

  @override
  Future<bool> isAvailable() async {
    return !_shouldThrowError;
  }

  @override
  Future<String?> read(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage[key];
  }

  @override
  Future<void> write(String key, String value) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage[key] = value;
  }

  Future<void> delete(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.clear();
  }

  // Missing methods from SecureStorageService interface:

  @override
  Future<void> storeServerConfig(Map<String, dynamic> config) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage['server_config'] = config.toString();
  }

  @override
  Future<Map<String, dynamic>?> getServerConfig() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    final configStr = _storage['server_config'];
    if (configStr == null) return null;
    // Simple mock implementation - in real code this would be JSON
    return {'mock': 'config'};
  }

  @override
  Future<void> clearServerConfig() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove('server_config');
  }

  @override
  Future<void> storeEncryptionKey(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage['encryption_key'] = key;
  }

  @override
  Future<String?> getEncryptionKey() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage['encryption_key'];
  }

  @override
  Future<void> clearEncryptionKey() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove('encryption_key');
  }

  @override
  Future<void> clearAll() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.clear();
  }

  @override
  Future<Set<String>> getAllKeys() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage.keys.toSet();
  }

  @override
  Future<bool> containsKey(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage.containsKey(key);
  }

  @override
  Future<void> storeSecureData(String key, String value) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage[key] = value;
  }

  @override
  Future<String?> getSecureData(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    return _storage[key];
  }

  @override
  Future<void> deleteSecureData(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove(key);
  }
}

/// Mock ConnectivityService for testing
class MockConnectivityService implements ConnectivityService {
  bool _isConnected = true;

  void setConnected(bool connected) {
    _isConnected = connected;
  }

  @override
  bool hasConnectivity() {
    return _isConnected;
  }

  @override
  Future<bool> checkConnectivity() async {
    return _isConnected;
  }

  @override
  Stream<bool> get connectivityStream => Stream.value(_isConnected);

  @override
  bool get isConnected => _isConnected;

  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  void dispose() {
    // Mock dispose
  }
}

/// Simple mock NotificationService for testing
/// Note: This implements a simplified interface that may not match the full NotificationService
class MockNotificationService {
  final List<String> _notifications = [];

  List<String> get notifications => List.unmodifiable(_notifications);

  void clearNotifications() {
    _notifications.clear();
  }

  Future<void> initialize() async {
    // Mock initialization
  }

  Future<void> showNotification(String title, String body) async {
    _notifications.add('$title: $body');
  }

  Future<void> showErrorNotification(
    String title,
    String error, {
    Map<String, dynamic>? data,
  }) async {
    _notifications.add('ERROR - $title: $error');
  }

  Future<void> showInfoNotification(
    String title,
    String info, {
    Map<String, dynamic>? data,
  }) async {
    _notifications.add('INFO - $title: $info');
  }

  Future<void> showSyncNotification(String message) async {
    _notifications.add('SYNC: $message');
  }

  Future<void> showScanProgressNotification(
    String libraryName,
    int progress,
  ) async {
    _notifications.add('SCAN: $libraryName - $progress%');
  }

  Future<void> cancelNotification(int id) async {
    // Mock cancel
  }

  Future<void> cancelAllNotifications() async {
    _notifications.clear();
  }
}

/// Mock ApiClient for testing
class MockApiClient implements ApiClient {
  final Map<String, dynamic> _responses = {};
  final List<String> _requests = [];
  bool _shouldThrowError = false;
  String? _authToken;

  void setShouldThrowError(bool shouldThrow) {
    _shouldThrowError = shouldThrow;
  }

  void setMockResponse(String path, dynamic response) {
    _responses[path] = response;
  }

  List<String> get requests => List.unmodifiable(_requests);

  void clearRequests() {
    _requests.clear();
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams}) async {
    if (_shouldThrowError) throw Exception('Mock API error');
    _requests.add('GET $path');
    return _responses[path] as T;
  }

  @override
  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParams,
  }) async {
    if (_shouldThrowError) throw Exception('Mock API error');
    _requests.add('POST $path');
    return _responses[path] as T;
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    if (_shouldThrowError) throw Exception('Mock API error');
    _requests.add('PUT $path');
    return _responses[path] as T;
  }

  @override
  Future<T> delete<T>(String path) async {
    if (_shouldThrowError) throw Exception('Mock API error');
    _requests.add('DELETE $path');
    return _responses[path] as T;
  }

  @override
  void setAuthToken(String token) {
    _authToken = token;
  }

  @override
  void clearAuthToken() {
    _authToken = null;
  }

  String? get authToken => _authToken;

  @override
  String get baseUrl => 'https://mock-api.example.com';

  @override
  bool get hasAuthToken => _authToken != null;
}

/// Create a test container with mock providers
ProviderContainer createTestContainer({
  MockSecureStorageService? mockSecureStorage,
  MockConnectivityService? mockConnectivity,
  MockNotificationService? mockNotification,
  MockApiClient? mockApiClient,
}) {
  return ProviderContainer(
    overrides: [
      if (mockSecureStorage != null)
        secureStorageServiceProvider.overrideWithValue(mockSecureStorage),
      // Add other provider overrides as needed
    ],
  );
}

/// Test utilities
class TestUtils {
  /// Wait for all microtasks to complete
  static Future<void> pumpEventQueue() async {
    await Future.delayed(Duration.zero);
  }

  /// Create a test DateTime
  static DateTime testDateTime() => DateTime.parse('2024-01-01T00:00:00Z');
}
