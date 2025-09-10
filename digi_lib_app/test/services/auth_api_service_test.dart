import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:digi_lib_app/src/services/auth_api_service.dart';
import 'package:digi_lib_app/src/network/api_client.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';
import 'package:digi_lib_app/src/models/api/api_error.dart';

import 'auth_api_service_test.mocks.dart';

@GenerateMocks([ApiClient, SecureStorageService])
void main() {
  group('AuthApiServiceImpl', () {
    late AuthApiServiceImpl authService;
    late MockApiClient mockApiClient;
    late MockSecureStorageService mockSecureStorage;

    setUp(() {
      mockApiClient = MockApiClient();
      mockSecureStorage = MockSecureStorageService();
      authService = AuthApiServiceImpl(mockApiClient, mockSecureStorage);
    });

    group('signInWithOAuth2', () {
      test('should sign in successfully with OAuth2', () async {
        // Arrange
        const provider = 'google';
        const code = 'auth-code';
        const state = 'state-value';
        const redirectUri = 'https://app.example.com/callback';
        
        final authResultJson = {
          'access_token': 'access-token',
          'refresh_token': 'refresh-token',
          'expires_in': 3600,
          'token_type': 'Bearer',
        };

        when(mockApiClient.post<Map<String, dynamic>>(
          '/auth/oauth2/$provider',
          body: {
            'code': code,
            'state': state,
            'redirect_uri': redirectUri,
          },
        )).thenAnswer((_) async => authResultJson);

        when(mockSecureStorage.storeSecureData(any, any)).thenAnswer((_) async {});
        when(mockSecureStorage.storeRefreshToken(any)).thenAnswer((_) async {});

        // Act
        final result = await authService.signInWithOAuth2(provider, code, state, redirectUri);

        // Assert
        expect(result.accessToken, 'access-token');
        expect(result.refreshToken, 'refresh-token');
        expect(result.expiresIn, 3600);
        expect(result.tokenType, 'Bearer');
        expect(authService.isAuthenticated, true);
        expect(authService.currentAccessToken, 'access-token');

        verify(mockApiClient.setAuthToken('access-token')).called(1);
        verify(mockSecureStorage.storeSecureData('access_token', 'access-token')).called(1);
        verify(mockSecureStorage.storeRefreshToken('refresh-token')).called(1);
      });

      test('should handle OAuth2 sign-in error', () async {
        // Arrange
        const provider = 'google';
        const code = 'invalid-code';
        const state = 'state-value';
        const redirectUri = 'https://app.example.com/callback';

        when(mockApiClient.post<Map<String, dynamic>>(
          '/auth/oauth2/$provider',
          body: anyNamed('body'),
        )).thenThrow(ApiException(
          ApiError(
            message: 'Invalid authorization code',
            code: 'INVALID_CODE',
            status: 400,
            timestamp: DateTime.now(),
          ),
        ));

        // Act & Assert
        expect(
          () => authService.signInWithOAuth2(provider, code, state, redirectUri),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('refreshToken', () {
      test('should refresh token successfully', () async {
        // Arrange
        const refreshToken = 'stored-refresh-token';
        final authResultJson = {
          'access_token': 'new-access-token',
          'refresh_token': 'new-refresh-token',
          'expires_in': 3600,
          'token_type': 'Bearer',
        };

        when(mockSecureStorage.getRefreshToken()).thenAnswer((_) async => refreshToken);
        when(mockApiClient.post<Map<String, dynamic>>(
          '/auth/refresh',
          body: {'refresh_token': refreshToken},
        )).thenAnswer((_) async => authResultJson);

        when(mockSecureStorage.storeSecureData(any, any)).thenAnswer((_) async {});
        when(mockSecureStorage.storeRefreshToken(any)).thenAnswer((_) async {});

        // Act
        final result = await authService.refreshToken();

        // Assert
        expect(result.accessToken, 'new-access-token');
        expect(result.refreshToken, 'new-refresh-token');
        expect(authService.currentAccessToken, 'new-access-token');

        verify(mockApiClient.setAuthToken('new-access-token')).called(1);
      });

      test('should handle missing refresh token', () async {
        // Arrange
        when(mockSecureStorage.getRefreshToken()).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authService.refreshToken(),
          throwsA(isA<ApiException>().having(
            (e) => e.error.code,
            'error code',
            'NO_REFRESH_TOKEN',
          )),
        );
      });

      test('should clear tokens on refresh failure', () async {
        // Arrange
        const refreshToken = 'invalid-refresh-token';

        when(mockSecureStorage.getRefreshToken()).thenAnswer((_) async => refreshToken);
        when(mockApiClient.post<Map<String, dynamic>>(
          '/auth/refresh',
          body: {'refresh_token': refreshToken},
        )).thenThrow(ApiException(
          ApiError(
            message: 'Invalid refresh token',
            code: 'INVALID_REFRESH_TOKEN',
            status: 401,
            timestamp: DateTime.now(),
          ),
        ));

        when(mockSecureStorage.deleteSecureData(any)).thenAnswer((_) async {});
        when(mockSecureStorage.clearRefreshToken()).thenAnswer((_) async {});

        // Act & Assert
        await expectLater(
          () => authService.refreshToken(),
          throwsA(isA<ApiException>()),
        );

        verify(mockSecureStorage.deleteSecureData('access_token')).called(1);
        verify(mockSecureStorage.clearRefreshToken()).called(1);
        verify(mockSecureStorage.deleteSecureData('token_expires_at')).called(1);
        verify(mockApiClient.clearAuthToken()).called(1);
      });
    });

    group('getCurrentUser', () {
      test('should get current user successfully', () async {
        // Arrange
        final userJson = {
          'id': 'user-id',
          'email': 'test@example.com',
          'name': 'Test User',
          'provider': 'google',
          'provider_id': 'google-id',
          'created_at': DateTime.now().toIso8601String(),
        };

        // Set up authenticated state
        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => 'access-token');
        when(mockSecureStorage.getSecureData('token_expires_at'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).toIso8601String());
        
        when(mockApiClient.get<Map<String, dynamic>>('/api/users/me'))
            .thenAnswer((_) async => userJson);

        await authService.initialize();

        // Act
        final user = await authService.getCurrentUser();

        // Assert
        expect(user.id, 'user-id');
        expect(user.email, 'test@example.com');
        expect(user.name, 'Test User');
        expect(user.provider, 'google');
        expect(user.providerId, 'google-id');
      });

      test('should handle unauthenticated state', () async {
        // Arrange
        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => authService.getCurrentUser(),
          throwsA(isA<ApiException>().having(
            (e) => e.error.code,
            'error code',
            'NO_ACCESS_TOKEN',
          )),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockSecureStorage.deleteSecureData(any)).thenAnswer((_) async {});
        when(mockSecureStorage.clearRefreshToken()).thenAnswer((_) async {});
        when(mockApiClient.post('/auth/logout')).thenAnswer((_) async => {});

        // Set up authenticated state by initializing with stored token
        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => 'access-token');
        when(mockSecureStorage.getSecureData('token_expires_at'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).toIso8601String());
        await authService.initialize();

        // Act
        await authService.signOut();

        // Assert
        expect(authService.isAuthenticated, false);
        expect(authService.currentAccessToken, null);

        verify(mockSecureStorage.deleteSecureData('access_token')).called(1);
        verify(mockSecureStorage.clearRefreshToken()).called(1);
        verify(mockSecureStorage.deleteSecureData('token_expires_at')).called(1);
        verify(mockApiClient.clearAuthToken()).called(1);
      });

      test('should sign out even if logout API fails', () async {
        // Arrange
        when(mockSecureStorage.deleteSecureData(any)).thenAnswer((_) async {});
        when(mockSecureStorage.clearRefreshToken()).thenAnswer((_) async {});
        when(mockApiClient.post('/auth/logout')).thenThrow(ApiException(
          ApiError(
            message: 'Server error',
            code: 'SERVER_ERROR',
            status: 500,
            timestamp: DateTime.now(),
          ),
        ));

        // Set up authenticated state by initializing with stored token
        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => 'access-token');
        when(mockSecureStorage.getSecureData('token_expires_at'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).toIso8601String());
        await authService.initialize();

        // Act
        await authService.signOut();

        // Assert
        expect(authService.isAuthenticated, false);
        expect(authService.currentAccessToken, null);

        verify(mockSecureStorage.deleteSecureData('access_token')).called(1);
        verify(mockSecureStorage.clearRefreshToken()).called(1);
        verify(mockSecureStorage.deleteSecureData('token_expires_at')).called(1);
        verify(mockApiClient.clearAuthToken()).called(1);
      });
    });

    group('initialize', () {
      test('should initialize with stored tokens', () async {
        // Arrange
        const accessToken = 'stored-access-token';
        final expiresAt = DateTime.now().add(const Duration(hours: 1));

        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => accessToken);
        when(mockSecureStorage.getSecureData('token_expires_at'))
            .thenAnswer((_) async => expiresAt.toIso8601String());

        // Act
        await authService.initialize();

        // Assert
        expect(authService.currentAccessToken, accessToken);
        verify(mockApiClient.setAuthToken(accessToken)).called(1);
      });

      test('should handle missing stored tokens', () async {
        // Arrange
        when(mockSecureStorage.getSecureData('access_token')).thenAnswer((_) async => null);

        // Act
        await authService.initialize();

        // Assert
        expect(authService.currentAccessToken, null);
        expect(authService.isAuthenticated, false);
      });

      test('should clear tokens on initialization error', () async {
        // Arrange
        when(mockSecureStorage.getSecureData('access_token')).thenThrow(Exception('Storage error'));
        when(mockSecureStorage.deleteSecureData(any)).thenAnswer((_) async {});
        when(mockSecureStorage.clearRefreshToken()).thenAnswer((_) async {});

        // Act
        await authService.initialize();

        // Assert
        expect(authService.currentAccessToken, null);
        expect(authService.isAuthenticated, false);

        verify(mockSecureStorage.deleteSecureData('access_token')).called(1);
        verify(mockSecureStorage.clearRefreshToken()).called(1);
        verify(mockSecureStorage.deleteSecureData('token_expires_at')).called(1);
        verify(mockApiClient.clearAuthToken()).called(1);
      });
    });
  });

  group('MockAuthApiService', () {
    late MockAuthApiService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthApiService();
    });

    test('should initialize as not authenticated', () {
      expect(mockAuthService.isAuthenticated, false);
      expect(mockAuthService.currentAccessToken, null);
    });

    test('should sign in successfully', () async {
      // Act
      final result = await mockAuthService.signInWithOAuth2('google', 'code', 'state', 'redirect');

      // Assert
      expect(result.accessToken, 'mock-access-token');
      expect(mockAuthService.isAuthenticated, true);
      expect(mockAuthService.currentAccessToken, 'mock-access-token');
    });

    test('should get current user when authenticated', () async {
      // Arrange
      await mockAuthService.signInWithOAuth2('google', 'code', 'state', 'redirect');

      // Act
      final user = await mockAuthService.getCurrentUser();

      // Assert
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });

    test('should throw error when getting user while not authenticated', () async {
      // Act & Assert
      expect(
        () => mockAuthService.getCurrentUser(),
        throwsA(isA<ApiException>()),
      );
    });

    test('should sign out successfully', () async {
      // Arrange
      await mockAuthService.signInWithOAuth2('google', 'code', 'state', 'redirect');
      expect(mockAuthService.isAuthenticated, true);

      // Act
      await mockAuthService.signOut();

      // Assert
      expect(mockAuthService.isAuthenticated, false);
      expect(mockAuthService.currentAccessToken, null);
    });

    test('should allow setting authentication state', () {
      // Arrange
      final user = User(
        id: 'test-id',
        email: 'custom@example.com',
        name: 'Custom User',
        createdAt: DateTime.now(),
      );

      // Act
      mockAuthService.setAuthenticated(true, token: 'custom-token', user: user);

      // Assert
      expect(mockAuthService.isAuthenticated, true);
      expect(mockAuthService.currentAccessToken, 'custom-token');
    });
  });
}