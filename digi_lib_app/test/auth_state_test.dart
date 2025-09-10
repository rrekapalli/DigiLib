import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/models/auth_state.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';

void main() {
  group('AuthState', () {
    late User testUser;
    late DateTime futureTime;
    late DateTime pastTime;

    setUp(() {
      testUser = User(
        id: 'test-user-id',
        email: 'test@example.com',
        name: 'Test User',
        provider: 'oauth2',
        providerId: 'provider-123',
        createdAt: DateTime.now(),
      );
      
      futureTime = DateTime.now().add(const Duration(hours: 1));
      pastTime = DateTime.now().subtract(const Duration(hours: 1));
    });

    group('Constructors', () {
      test('should create loading state', () {
        const state = AuthState.loading();
        
        expect(state.status, equals(AuthStatus.loading));
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpiresAt, isNull);
        expect(state.error, isNull);
        expect(state.hasRefreshToken, isFalse);
      });

      test('should create authenticated state', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state.status, equals(AuthStatus.authenticated));
        expect(state.user, equals(testUser));
        expect(state.accessToken, equals('test-token'));
        expect(state.tokenExpiresAt, equals(futureTime));
        expect(state.error, isNull);
        expect(state.hasRefreshToken, isTrue);
      });

      test('should create unauthenticated state', () {
        const state = AuthState.unauthenticated();
        
        expect(state.status, equals(AuthStatus.unauthenticated));
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpiresAt, isNull);
        expect(state.error, isNull);
        expect(state.hasRefreshToken, isFalse);
      });

      test('should create authenticating state', () {
        const state = AuthState.authenticating();
        
        expect(state.status, equals(AuthStatus.authenticating));
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpiresAt, isNull);
        expect(state.error, isNull);
        expect(state.hasRefreshToken, isFalse);
      });

      test('should create refreshing state', () {
        final state = AuthState.refreshing(
          user: testUser,
          hasRefreshToken: true,
        );
        
        expect(state.status, equals(AuthStatus.refreshing));
        expect(state.user, equals(testUser));
        expect(state.accessToken, isNull);
        expect(state.tokenExpiresAt, isNull);
        expect(state.error, isNull);
        expect(state.hasRefreshToken, isTrue);
      });

      test('should create error state', () {
        const errorMessage = 'Authentication failed';
        const state = AuthState.error(errorMessage);
        
        expect(state.status, equals(AuthStatus.error));
        expect(state.user, isNull);
        expect(state.accessToken, isNull);
        expect(state.tokenExpiresAt, isNull);
        expect(state.error, equals(errorMessage));
        expect(state.hasRefreshToken, isFalse);
      });
    });

    group('Token Expiration', () {
      test('should detect expired token', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: pastTime,
          hasRefreshToken: true,
        );
        
        expect(state.isTokenExpired, isTrue);
      });

      test('should detect valid token', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state.isTokenExpired, isFalse);
      });

      test('should consider token expired if expiration time is null', () {
        final state = AuthState(
          status: AuthStatus.authenticated,
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: null, // Explicitly null
          hasRefreshToken: true,
        );
        
        expect(state.isTokenExpired, isTrue);
      });

      test('should consider token expired if expires within 5 minutes', () {
        final soonToExpire = DateTime.now().add(const Duration(minutes: 3));
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: soonToExpire,
          hasRefreshToken: true,
        );
        
        expect(state.isTokenExpired, isTrue);
      });
    });

    group('Authentication Status', () {
      test('should be authenticated with valid token', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state.isAuthenticated, isTrue);
      });

      test('should not be authenticated with expired token', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: pastTime,
          hasRefreshToken: true,
        );
        
        expect(state.isAuthenticated, isFalse);
      });

      test('should not be authenticated in unauthenticated state', () {
        const state = AuthState.unauthenticated();
        expect(state.isAuthenticated, isFalse);
      });

      test('should not be authenticated in loading state', () {
        const state = AuthState.loading();
        expect(state.isAuthenticated, isFalse);
      });
    });

    group('Loading Status', () {
      test('should be loading in loading state', () {
        const state = AuthState.loading();
        expect(state.isLoading, isTrue);
      });

      test('should be loading in authenticating state', () {
        const state = AuthState.authenticating();
        expect(state.isLoading, isTrue);
      });

      test('should be loading in refreshing state', () {
        final state = AuthState.refreshing(
          user: testUser,
          hasRefreshToken: true,
        );
        expect(state.isLoading, isTrue);
      });

      test('should not be loading in authenticated state', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        expect(state.isLoading, isFalse);
      });

      test('should not be loading in unauthenticated state', () {
        const state = AuthState.unauthenticated();
        expect(state.isLoading, isFalse);
      });
    });

    group('Error Status', () {
      test('should have error in error state', () {
        const state = AuthState.error('Test error');
        expect(state.hasError, isTrue);
        expect(state.error, equals('Test error'));
      });

      test('should not have error in other states', () {
        const loadingState = AuthState.loading();
        const unauthenticatedState = AuthState.unauthenticated();
        final authenticatedState = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(loadingState.hasError, isFalse);
        expect(unauthenticatedState.hasError, isFalse);
        expect(authenticatedState.hasError, isFalse);
      });
    });

    group('Token Refresh Need', () {
      test('should need token refresh when authenticated with expired token and refresh token', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: pastTime,
          hasRefreshToken: true,
        );
        
        expect(state.needsTokenRefresh, isTrue);
      });

      test('should not need token refresh when token is valid', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state.needsTokenRefresh, isFalse);
      });

      test('should not need token refresh when no refresh token available', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: pastTime,
          hasRefreshToken: false,
        );
        
        expect(state.needsTokenRefresh, isFalse);
      });

      test('should not need token refresh when not authenticated', () {
        const state = AuthState.unauthenticated();
        expect(state.needsTokenRefresh, isFalse);
      });
    });

    group('Copy With', () {
      test('should create copy with updated values', () {
        const originalState = AuthState.loading();
        
        final updatedState = originalState.copyWith(
          status: AuthStatus.authenticated,
          user: testUser,
          accessToken: 'new-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(updatedState.status, equals(AuthStatus.authenticated));
        expect(updatedState.user, equals(testUser));
        expect(updatedState.accessToken, equals('new-token'));
        expect(updatedState.tokenExpiresAt, equals(futureTime));
        expect(updatedState.hasRefreshToken, isTrue);
        expect(updatedState.error, isNull);
      });

      test('should preserve original values when not specified', () {
        final originalState = AuthState.authenticated(
          user: testUser,
          accessToken: 'original-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        final updatedState = originalState.copyWith(
          accessToken: 'new-token',
        );
        
        expect(updatedState.status, equals(AuthStatus.authenticated));
        expect(updatedState.user, equals(testUser));
        expect(updatedState.accessToken, equals('new-token'));
        expect(updatedState.tokenExpiresAt, equals(futureTime));
        expect(updatedState.hasRefreshToken, isTrue);
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final state1 = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        final state2 = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final state1 = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token-1',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        final state2 = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token-2',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        expect(state1, isNot(equals(state2)));
      });
    });

    group('String Representation', () {
      test('should provide meaningful string representation', () {
        final state = AuthState.authenticated(
          user: testUser,
          accessToken: 'test-token',
          tokenExpiresAt: futureTime,
          hasRefreshToken: true,
        );
        
        final stringRep = state.toString();
        
        expect(stringRep, contains('AuthState'));
        expect(stringRep, contains('authenticated'));
        expect(stringRep, contains(testUser.id));
        expect(stringRep, contains('hasToken: true'));
        expect(stringRep, contains('hasRefreshToken: true'));
      });
    });
  });
}