import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_lib_app/src/providers/auth_provider.dart';
import 'package:digi_lib_app/src/providers/settings_provider.dart';
import 'package:digi_lib_app/src/models/auth_state.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';
import 'package:digi_lib_app/src/models/api/auth_result.dart';
import 'test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthNotifier', () {
    late ProviderContainer container;
    late MockSecureStorageService mockStorage;
    late User testUser;
    late AuthResult testAuthResult;

    setUp(() {
      mockStorage = MockSecureStorageService();
      
      container = ProviderContainer(
        overrides: [
          secureStorageServiceProvider.overrideWithValue(mockStorage),
        ],
      );

      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        provider: 'oauth2',
        providerId: 'provider-123',
        createdAt: DateTime.now(),
      );

      testAuthResult = AuthResult(
        accessToken: 'test-access-token',
        refreshToken: 'test-refresh-token',
        expiresIn: 3600, // 1 hour
        tokenType: 'Bearer',
      );
    });

    tearDown(() {
      container.dispose();
      mockStorage.clearMockStorage();
    });

    group('Initialization', () {
      test('should start in loading state', () {
        final initialState = container.read(authProvider);
        
        expect(initialState.status, equals(AuthStatus.loading));
      });

      test('should initialize to unauthenticated when no stored tokens', () async {
        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
      });

      test('should handle initialization errors gracefully', () async {
        mockStorage.setShouldThrowError(true);
        
        // Create new container with error-prone storage
        final errorContainer = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(mockStorage),
          ],
        );

        // Wait for initialization to complete
        await Future.delayed(const Duration(milliseconds: 100));
        
        final state = errorContainer.read(authProvider);
        expect(state.status, equals(AuthStatus.error));
        expect(state.error, isNotNull);
        
        errorContainer.dispose();
      });
    });

    group('Sign In', () {
      test('should sign in successfully with OAuth2', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.user, equals(testUser));
        expect(state.accessToken, equals(testAuthResult.accessToken));
        expect(state.hasRefreshToken, isTrue);
        expect(state.tokenExpiresAt, isNotNull);
      });

      test('should handle sign in errors', () async {
        mockStorage.setShouldThrowError(true);
        final authNotifier = container.read(authProvider.notifier);
        
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.error));
        expect(state.error, isNotNull);
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
      });
    });

    group('Sign Out', () {
      test('should sign out successfully', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // First sign in
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(container.read(authProvider).status, equals(AuthStatus.authenticated));
        
        // Then sign out
        await authNotifier.signOut();
        
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(state.hasRefreshToken, isFalse);
      });

      test('should handle sign out errors gracefully', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // First sign in
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(container.read(authProvider).status, equals(AuthStatus.authenticated));
        
        // Make storage throw errors
        mockStorage.setShouldThrowError(true);
        
        // Sign out should still work even if storage fails
        await authNotifier.signOut();
        
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.unauthenticated));
      });
    });

    group('User Updates', () {
      test('should update user information when authenticated', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // First sign in
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(container.read(authProvider).user, equals(testUser));
        
        // Update user
        final updatedUser = testUser.copyWith(name: 'Updated Name');
        authNotifier.updateUser(updatedUser);
        
        final state = container.read(authProvider);
        expect(state.user?.name, equals('Updated Name'));
        expect(state.status, equals(AuthStatus.authenticated));
      });

      test('should not update user when not authenticated', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // Try to update user when not authenticated
        authNotifier.updateUser(testUser);
        
        final state = container.read(authProvider);
        expect(state.user, isNull);
      });
    });

    group('Utility Methods', () {
      test('should provide correct authentication status', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // Initially not authenticated
        expect(authNotifier.isAuthenticated, isFalse);
        expect(authNotifier.currentAccessToken, isNull);
        expect(authNotifier.currentUser, isNull);
        
        // After sign in
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(authNotifier.isAuthenticated, isTrue);
        expect(authNotifier.currentAccessToken, equals(testAuthResult.accessToken));
        expect(authNotifier.currentUser, equals(testUser));
      });

      test('should clear error state', () async {
        mockStorage.setShouldThrowError(true);
        final authNotifier = container.read(authProvider.notifier);
        
        // Cause an error
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(container.read(authProvider).hasError, isTrue);
        
        // Clear error
        authNotifier.clearError();
        expect(container.read(authProvider).hasError, isFalse);
        expect(container.read(authProvider).status, equals(AuthStatus.unauthenticated));
      });

      test('should check secure storage availability', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // Storage should be available initially
        expect(await authNotifier.isSecureStorageAvailable(), isTrue);
        
        // Make storage unavailable
        mockStorage.setShouldThrowError(true);
        expect(await authNotifier.isSecureStorageAvailable(), isFalse);
      });
    });

    group('Token Management', () {
      test('should detect when token refresh is needed', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // Sign in with short-lived token
        final shortLivedAuthResult = AuthResult(
          accessToken: 'short-lived-token',
          refreshToken: 'test-refresh-token',
          expiresIn: 1, // 1 second
          tokenType: 'Bearer',
        );
        
        await authNotifier.signInWithOAuth2(shortLivedAuthResult, testUser);
        
        // Wait for token to expire
        await Future.delayed(const Duration(seconds: 2));
        
        expect(authNotifier.needsTokenRefresh, isTrue);
      });

      test('should handle refresh token when available', () async {
        final authNotifier = container.read(authProvider.notifier);
        
        // Sign in first
        await authNotifier.signInWithOAuth2(testAuthResult, testUser);
        expect(container.read(authProvider).hasRefreshToken, isTrue);
        
        // Force refresh should work
        await authNotifier.forceRefresh();
        
        // Should still be authenticated after refresh
        final state = container.read(authProvider);
        expect(state.status, equals(AuthStatus.authenticated));
      });
    });
  });
}