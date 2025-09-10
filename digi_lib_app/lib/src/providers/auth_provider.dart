import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digi_lib_app/src/models/auth_state.dart';
import 'package:digi_lib_app/src/models/entities/user.dart';
import 'package:digi_lib_app/src/models/api/auth_result.dart';
import 'package:digi_lib_app/src/services/secure_storage_service.dart';
import 'package:digi_lib_app/src/services/auth_api_service.dart';
import 'settings_provider.dart';
import 'auth_api_service_provider.dart';

/// Provider for AuthNotifier
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final authApiService = ref.watch(authApiServiceProvider);
  return AuthNotifier(secureStorage, authApiService);
});



/// Provider for current user
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authProvider);
  return authState.user;
});

/// Notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final SecureStorageService _secureStorage;
  final AuthApiService _authApiService;
  Timer? _tokenRefreshTimer;
  Timer? _tokenExpirationTimer;

  AuthNotifier(this._secureStorage, this._authApiService) : super(const AuthState.loading()) {
    _initializeAuth();
  }

  @override
  void dispose() {
    _tokenRefreshTimer?.cancel();
    _tokenExpirationTimer?.cancel();
    super.dispose();
  }

  /// Initialize authentication state by checking stored tokens
  Future<void> _initializeAuth() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      final userId = await _secureStorage.getUserId();
      
      if (refreshToken != null && userId != null) {
        // We have stored credentials, try to refresh the token
        await _refreshTokenSilently();
      } else {
        // No stored credentials, user is unauthenticated
        state = const AuthState.unauthenticated();
      }
    } catch (e) {
      // Error during initialization, clear any stored data and set unauthenticated
      await _clearStoredAuth();
      state = AuthState.error('Failed to initialize authentication: $e');
    }
  }

  /// Sign in with OAuth2 result
  Future<void> signInWithOAuth2(AuthResult authResult, User user) async {
    try {
      state = const AuthState.authenticating();

      // Store tokens securely
      await _secureStorage.storeRefreshToken(authResult.refreshToken);
      await _secureStorage.storeUserId(user.id);

      // Calculate token expiration time
      final expiresAt = DateTime.now().add(Duration(seconds: authResult.expiresIn));

      // Update state to authenticated
      state = AuthState.authenticated(
        user: user,
        accessToken: authResult.accessToken,
        tokenExpiresAt: expiresAt,
        hasRefreshToken: true,
      );

      // Schedule token refresh
      _scheduleTokenRefresh(expiresAt);

    } catch (e) {
      await _clearStoredAuth();
      state = AuthState.error('Sign in failed: $e');
    }
  }

  /// Sign in with OAuth2 provider using API
  Future<void> signInWithOAuth2Provider(String provider, String code, String state, String redirectUri) async {
    try {
      this.state = const AuthState.authenticating();

      // Call API to exchange code for tokens
      final authResult = await _authApiService.signInWithOAuth2(provider, code, state, redirectUri);
      final user = await _authApiService.getCurrentUser();

      // Store tokens securely
      await _secureStorage.storeRefreshToken(authResult.refreshToken);
      await _secureStorage.storeUserId(user.id);

      // Calculate token expiration time
      final expiresAt = DateTime.now().add(Duration(seconds: authResult.expiresIn));

      // Update state to authenticated
      this.state = AuthState.authenticated(
        user: user,
        accessToken: authResult.accessToken,
        tokenExpiresAt: expiresAt,
        hasRefreshToken: true,
      );

      // Schedule token refresh
      _scheduleTokenRefresh(expiresAt);

    } catch (e) {
      await _clearStoredAuth();
      this.state = AuthState.error('OAuth2 sign in failed: $e');
    }
  }

  /// Refresh the access token using stored refresh token
  Future<void> refreshToken() async {
    if (!state.hasRefreshToken) {
      await signOut();
      return;
    }

    try {
      // Set refreshing state while keeping user info
      if (state.user != null) {
        state = AuthState.refreshing(
          user: state.user!,
          hasRefreshToken: state.hasRefreshToken,
        );
      }

      // Call actual API to refresh the token
      final authResult = await _authApiService.refreshToken();
      final user = await _authApiService.getCurrentUser();

      // Calculate token expiration time
      final expiresAt = DateTime.now().add(Duration(seconds: authResult.expiresIn));

      state = AuthState.authenticated(
        user: user,
        accessToken: authResult.accessToken,
        tokenExpiresAt: expiresAt,
        hasRefreshToken: true,
      );

      _scheduleTokenRefresh(expiresAt);

    } catch (e) {
      // Refresh failed, sign out the user
      await signOut();
      state = AuthState.error('Token refresh failed: $e');
    }
  }

  /// Silently refresh token without changing UI state (used during initialization)
  Future<void> _refreshTokenSilently() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      final userId = await _secureStorage.getUserId();

      if (refreshToken == null || userId == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Call actual API to refresh token
      final authResult = await _authApiService.refreshToken();
      final user = await _authApiService.getCurrentUser();

      // Calculate token expiration time
      final expiresAt = DateTime.now().add(Duration(seconds: authResult.expiresIn));

      state = AuthState.authenticated(
        user: user,
        accessToken: authResult.accessToken,
        tokenExpiresAt: expiresAt,
        hasRefreshToken: true,
      );

      _scheduleTokenRefresh(expiresAt);

    } catch (e) {
      await _clearStoredAuth();
      state = const AuthState.unauthenticated();
    }
  }

  /// Sign out the user and clear all stored authentication data
  Future<void> signOut() async {
    try {
      // Cancel any scheduled timers
      _tokenRefreshTimer?.cancel();
      _tokenExpirationTimer?.cancel();

      // Call API to sign out (this will clear server-side session)
      await _authApiService.signOut();

      // Clear stored authentication data
      await _clearStoredAuth();

      // Update state to unauthenticated
      state = const AuthState.unauthenticated();

    } catch (e) {
      // Even if API call or clearing storage fails, set state to unauthenticated
      await _clearStoredAuth();
      state = const AuthState.unauthenticated();
    }
  }

  /// Clear all stored authentication data
  Future<void> _clearStoredAuth() async {
    try {
      await _secureStorage.clearRefreshToken();
      await _secureStorage.clearUserId();
    } catch (e) {
      // Log error but don't throw - we want to continue with sign out
      print('Error clearing stored auth data: $e');
    }
  }

  /// Schedule automatic token refresh before expiration
  void _scheduleTokenRefresh(DateTime expiresAt) {
    _tokenRefreshTimer?.cancel();
    _tokenExpirationTimer?.cancel();

    // Schedule refresh 5 minutes before expiration
    final refreshTime = expiresAt.subtract(const Duration(minutes: 5));
    final timeUntilRefresh = refreshTime.difference(DateTime.now());

    if (timeUntilRefresh.isNegative) {
      // Token is already expired or about to expire, refresh immediately
      Future.microtask(() => refreshToken());
      return;
    }

    _tokenRefreshTimer = Timer(timeUntilRefresh, () {
      refreshToken();
    });

    // Also schedule a timer for actual expiration as a fallback
    final timeUntilExpiration = expiresAt.difference(DateTime.now());
    if (!timeUntilExpiration.isNegative) {
      _tokenExpirationTimer = Timer(timeUntilExpiration, () {
        if (state.isAuthenticated) {
          // Token has expired, force refresh or sign out
          refreshToken();
        }
      });
    }
  }

  /// Update user information (after profile updates)
  void updateUser(User user) {
    if (state.status == AuthStatus.authenticated) {
      state = state.copyWith(user: user);
    }
  }

  /// Check if the current token needs refresh
  bool get needsTokenRefresh => state.needsTokenRefresh;

  /// Get current access token (null if not authenticated or expired)
  String? get currentAccessToken {
    if (state.isAuthenticated) {
      return state.accessToken;
    }
    return null;
  }

  /// Get current user (null if not authenticated)
  User? get currentUser => state.user;

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Check if authentication is in progress
  bool get isLoading => state.isLoading;

  /// Get current error message
  String? get error => state.error;

  /// Clear current error state
  void clearError() {
    if (state.hasError) {
      state = const AuthState.unauthenticated();
    }
  }

  /// Force token refresh (for manual refresh)
  Future<void> forceRefresh() async {
    if (state.hasRefreshToken) {
      await refreshToken();
    }
  }

  /// Check if secure storage is available
  Future<bool> isSecureStorageAvailable() async {
    try {
      return await _secureStorage.isAvailable();
    } catch (e) {
      return false;
    }
  }
}