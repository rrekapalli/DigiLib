import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';
import 'package:digi_lib_app/src/services/connectivity_service.dart';
import 'package:digi_lib_app/src/services/notification_service.dart';
import 'package:digi_lib_app/src/services/api_client.dart';
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

  @override
  Future<void> delete(String key) async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    if (_shouldThrowError) throw Exception('Mock storage error');
    _storage.clear();
  }
}

/// Mock ConnectivityService for testing
class MockConnectivityService implements ConnectivityService {
  bool _isConnected = true;
  
  void setConnected(bool connected) {
    _isConnected = connected;
  }

  @override
  Future<bool> hasConnectivity() async {
    return _isConnected;
  }

  @override
  Stream<bool> get connectivityStream => Stream.value(_isConnected);
}

/// Mock NotificationService for testing
class MockNotificationService implements NotificationService {
  final List<String> _notifications = [];
  
  List<String> get notifications => List.unmodifiable(_notifications);
  
  void clearNotifications() {
    _notifications.clear();
  }

  @override
  Future<void> initialize() async {
    // Mock initialization
  }

  @override
  Future<void> showNotification(String title, String body) async {
    _notifications.add('$title: $body');
  }

  @override
  Future<void> showErrorNotification(String title, String error) async {
    _notifications.add('ERROR - $title: $error');
  }

  @override
  Future<void> showInfoNotification(String title, String info) async {
    _notifications.add('INFO - $title: $info');
  }

  @override
  Future<void> showSyncNotification(String message) async {
    _notifications.add('SYNC: $message');
  }

  @override
  Future<void> showScanProgressNotification(String libraryName, int progress) async {
    _notifications.add('SCAN: $libraryName - $progress%');
  }

  @override
  Future<void> cancelNotification(int id) async {
    // Mock cancel
  }

  @override
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
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams}) async {
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