import 'package:test/test.dart';
import 'test_helpers.dart';

void main() {
  group('Services Unit Tests', () {
    group('MockSecureStorageService', () {
      late MockSecureStorageService mockStorage;

      setUp(() {
        mockStorage = MockSecureStorageService();
      });

      tearDown(() {
        mockStorage.clearMockStorage();
      });

      test('should store and retrieve refresh token', () async {
        const token = 'test-refresh-token';
        
        await mockStorage.storeRefreshToken(token);
        final retrievedToken = await mockStorage.getRefreshToken();
        
        expect(retrievedToken, equals(token));
      });

      test('should store and retrieve user ID', () async {
        const userId = 'test-user-id';
        
        await mockStorage.storeUserId(userId);
        final retrievedUserId = await mockStorage.getUserId();
        
        expect(retrievedUserId, equals(userId));
      });

      test('should clear refresh token', () async {
        const token = 'test-refresh-token';
        
        await mockStorage.storeRefreshToken(token);
        await mockStorage.clearRefreshToken();
        final retrievedToken = await mockStorage.getRefreshToken();
        
        expect(retrievedToken, isNull);
      });

      test('should clear user ID', () async {
        const userId = 'test-user-id';
        
        await mockStorage.storeUserId(userId);
        await mockStorage.clearUserId();
        final retrievedUserId = await mockStorage.getUserId();
        
        expect(retrievedUserId, isNull);
      });

      test('should handle generic read/write operations', () async {
        const key = 'test-key';
        const value = 'test-value';
        
        await mockStorage.write(key, value);
        final retrievedValue = await mockStorage.read(key);
        
        expect(retrievedValue, equals(value));
      });

      test('should delete specific keys', () async {
        const key = 'test-key';
        const value = 'test-value';
        
        await mockStorage.write(key, value);
        await mockStorage.delete(key);
        final retrievedValue = await mockStorage.read(key);
        
        expect(retrievedValue, isNull);
      });

      test('should delete all keys', () async {
        await mockStorage.write('key1', 'value1');
        await mockStorage.write('key2', 'value2');
        await mockStorage.storeRefreshToken('token');
        
        await mockStorage.deleteAll();
        
        expect(await mockStorage.read('key1'), isNull);
        expect(await mockStorage.read('key2'), isNull);
        expect(await mockStorage.getRefreshToken(), isNull);
      });

      test('should report availability correctly', () async {
        expect(await mockStorage.isAvailable(), isTrue);
        
        mockStorage.setShouldThrowError(true);
        expect(await mockStorage.isAvailable(), isFalse);
      });

      test('should throw errors when configured to do so', () async {
        mockStorage.setShouldThrowError(true);
        
        expect(() => mockStorage.storeRefreshToken('token'), throwsException);
        expect(() => mockStorage.getRefreshToken(), throwsException);
        expect(() => mockStorage.write('key', 'value'), throwsException);
        expect(() => mockStorage.read('key'), throwsException);
      });
    });

    group('MockConnectivityService', () {
      late MockConnectivityService mockConnectivity;

      setUp(() {
        mockConnectivity = MockConnectivityService();
      });

      test('should report connectivity status', () async {
        // Default is connected
        expect(await mockConnectivity.hasConnectivity(), isTrue);
        
        // Set to disconnected
        mockConnectivity.setConnected(false);
        expect(await mockConnectivity.hasConnectivity(), isFalse);
        
        // Set back to connected
        mockConnectivity.setConnected(true);
        expect(await mockConnectivity.hasConnectivity(), isTrue);
      });

      test('should provide connectivity stream', () async {
        final stream = mockConnectivity.connectivityStream;
        final firstValue = await stream.first;
        
        expect(firstValue, isTrue);
      });
    });

    group('MockNotificationService', () {
      late MockNotificationService mockNotification;

      setUp(() {
        mockNotification = MockNotificationService();
      });

      tearDown(() {
        mockNotification.clearNotifications();
      });

      test('should initialize without errors', () async {
        await mockNotification.initialize();
        // Should complete without throwing
      });

      test('should show basic notifications', () async {
        await mockNotification.showNotification('Test Title', 'Test Body');
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(1));
        expect(notifications.first, equals('Test Title: Test Body'));
      });

      test('should show error notifications', () async {
        await mockNotification.showErrorNotification('Error Title', 'Error message');
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(1));
        expect(notifications.first, equals('ERROR - Error Title: Error message'));
      });

      test('should show info notifications', () async {
        await mockNotification.showInfoNotification('Info Title', 'Info message');
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(1));
        expect(notifications.first, equals('INFO - Info Title: Info message'));
      });

      test('should show sync notifications', () async {
        await mockNotification.showSyncNotification('Sync completed');
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(1));
        expect(notifications.first, equals('SYNC: Sync completed'));
      });

      test('should show scan progress notifications', () async {
        await mockNotification.showScanProgressNotification('My Library', 75);
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(1));
        expect(notifications.first, equals('SCAN: My Library - 75%'));
      });

      test('should clear all notifications', () async {
        await mockNotification.showNotification('Title 1', 'Body 1');
        await mockNotification.showNotification('Title 2', 'Body 2');
        
        expect(mockNotification.notifications.length, equals(2));
        
        await mockNotification.cancelAllNotifications();
        expect(mockNotification.notifications.length, equals(0));
      });

      test('should handle multiple notifications', () async {
        await mockNotification.showNotification('Title 1', 'Body 1');
        await mockNotification.showErrorNotification('Error', 'Something went wrong');
        await mockNotification.showSyncNotification('Syncing...');
        
        final notifications = mockNotification.notifications;
        expect(notifications.length, equals(3));
        expect(notifications[0], equals('Title 1: Body 1'));
        expect(notifications[1], equals('ERROR - Error: Something went wrong'));
        expect(notifications[2], equals('SYNC: Syncing...'));
      });
    });

    group('MockApiClient', () {
      late MockApiClient mockApiClient;

      setUp(() {
        mockApiClient = MockApiClient();
      });

      tearDown(() {
        mockApiClient.clearRequests();
      });

      test('should handle GET requests', () async {
        const mockResponse = {'data': 'test'};
        mockApiClient.setMockResponse('/test', mockResponse);
        
        final response = await mockApiClient.get<Map<String, dynamic>>('/test');
        
        expect(response, equals(mockResponse));
        expect(mockApiClient.requests, contains('GET /test'));
      });

      test('should handle POST requests', () async {
        const mockResponse = {'id': '123'};
        mockApiClient.setMockResponse('/create', mockResponse);
        
        final response = await mockApiClient.post<Map<String, dynamic>>(
          '/create',
          body: {'name': 'test'},
        );
        
        expect(response, equals(mockResponse));
        expect(mockApiClient.requests, contains('POST /create'));
      });

      test('should handle PUT requests', () async {
        const mockResponse = {'updated': true};
        mockApiClient.setMockResponse('/update', mockResponse);
        
        final response = await mockApiClient.put<Map<String, dynamic>>(
          '/update',
          body: {'name': 'updated'},
        );
        
        expect(response, equals(mockResponse));
        expect(mockApiClient.requests, contains('PUT /update'));
      });

      test('should handle DELETE requests', () async {
        const mockResponse = {'deleted': true};
        mockApiClient.setMockResponse('/delete', mockResponse);
        
        final response = await mockApiClient.delete<Map<String, dynamic>>('/delete');
        
        expect(response, equals(mockResponse));
        expect(mockApiClient.requests, contains('DELETE /delete'));
      });

      test('should manage auth tokens', () {
        const token = 'test-auth-token';
        
        mockApiClient.setAuthToken(token);
        expect(mockApiClient.authToken, equals(token));
        
        mockApiClient.clearAuthToken();
        expect(mockApiClient.authToken, isNull);
      });

      test('should track request history', () async {
        mockApiClient.setMockResponse('/test1', {});
        mockApiClient.setMockResponse('/test2', {});
        
        await mockApiClient.get('/test1');
        await mockApiClient.post('/test2');
        
        final requests = mockApiClient.requests;
        expect(requests.length, equals(2));
        expect(requests, contains('GET /test1'));
        expect(requests, contains('POST /test2'));
      });

      test('should throw errors when configured to do so', () async {
        mockApiClient.setShouldThrowError(true);
        
        expect(() => mockApiClient.get('/test'), throwsException);
        expect(() => mockApiClient.post('/test'), throwsException);
        expect(() => mockApiClient.put('/test'), throwsException);
        expect(() => mockApiClient.delete('/test'), throwsException);
      });

      test('should clear request history', () async {
        mockApiClient.setMockResponse('/test', {});
        await mockApiClient.get('/test');
        
        expect(mockApiClient.requests.length, equals(1));
        
        mockApiClient.clearRequests();
        expect(mockApiClient.requests.length, equals(0));
      });
    });

    group('TestUtils', () {
      test('should provide test utilities', () async {
        // Test pumpEventQueue
        await TestUtils.pumpEventQueue();
        // Should complete without throwing
        
        // Test testDateTime
        final testDate = TestUtils.testDateTime();
        expect(testDate, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });
    });
  });
}