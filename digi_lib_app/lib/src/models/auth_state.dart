import 'package:digi_lib_app/src/models/entities/user.dart';

/// Represents the current authentication state of the application
enum AuthStatus {
  /// Initial state, checking if user is authenticated
  loading,

  /// User is authenticated and has valid tokens
  authenticated,

  /// User is not authenticated or tokens are invalid
  unauthenticated,

  /// Authentication is in progress (signing in)
  authenticating,

  /// Token refresh is in progress
  refreshing,

  /// Authentication failed with an error
  error,
}

/// Authentication state containing user info and status
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? accessToken;
  final DateTime? tokenExpiresAt;
  final String? error;
  final bool hasRefreshToken;

  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.tokenExpiresAt,
    this.error,
    this.hasRefreshToken = false,
  });

  /// Initial loading state
  const AuthState.loading()
    : status = AuthStatus.loading,
      user = null,
      accessToken = null,
      tokenExpiresAt = null,
      error = null,
      hasRefreshToken = false;

  /// Authenticated state with user and token info
  const AuthState.authenticated({
    required this.user,
    required this.accessToken,
    required this.tokenExpiresAt,
    required this.hasRefreshToken,
  }) : status = AuthStatus.authenticated,
       error = null;

  /// Unauthenticated state
  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      user = null,
      accessToken = null,
      tokenExpiresAt = null,
      error = null,
      hasRefreshToken = false;

  /// Authenticating state (sign-in in progress)
  const AuthState.authenticating()
    : status = AuthStatus.authenticating,
      user = null,
      accessToken = null,
      tokenExpiresAt = null,
      error = null,
      hasRefreshToken = false;

  /// Token refresh in progress
  AuthState.refreshing({required this.user, required this.hasRefreshToken})
    : status = AuthStatus.refreshing,
      accessToken = null,
      tokenExpiresAt = null,
      error = null;

  /// Error state with error message
  const AuthState.error(String error)
    : status = AuthStatus.error,
      user = null,
      accessToken = null,
      tokenExpiresAt = null,
      error = error,
      hasRefreshToken = false;

  /// Check if the current access token is expired or about to expire
  bool get isTokenExpired {
    if (tokenExpiresAt == null) return true;

    // Consider token expired if it expires within the next 5 minutes
    final expirationBuffer = DateTime.now().add(const Duration(minutes: 5));
    return tokenExpiresAt!.isBefore(expirationBuffer);
  }

  /// Check if the user is currently authenticated with a valid token
  bool get isAuthenticated {
    return status == AuthStatus.authenticated &&
        accessToken != null &&
        !isTokenExpired;
  }

  /// Check if authentication is in progress
  bool get isLoading {
    return status == AuthStatus.loading ||
        status == AuthStatus.authenticating ||
        status == AuthStatus.refreshing;
  }

  /// Check if there's an authentication error
  bool get hasError {
    return status == AuthStatus.error && error != null;
  }

  /// Check if token refresh is needed and possible
  bool get needsTokenRefresh {
    return status == AuthStatus.authenticated &&
        isTokenExpired &&
        hasRefreshToken;
  }

  /// Create a copy of this state with updated values
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? accessToken,
    DateTime? tokenExpiresAt,
    String? error,
    bool? hasRefreshToken,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      tokenExpiresAt: tokenExpiresAt ?? this.tokenExpiresAt,
      error: error ?? this.error,
      hasRefreshToken: hasRefreshToken ?? this.hasRefreshToken,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthState &&
        other.status == status &&
        other.user == user &&
        other.accessToken == accessToken &&
        other.tokenExpiresAt == tokenExpiresAt &&
        other.error == error &&
        other.hasRefreshToken == hasRefreshToken;
  }

  @override
  int get hashCode {
    return Object.hash(
      status,
      user,
      accessToken,
      tokenExpiresAt,
      error,
      hasRefreshToken,
    );
  }

  @override
  String toString() {
    return 'AuthState('
        'status: $status, '
        'user: ${user?.id}, '
        'hasToken: ${accessToken != null}, '
        'tokenExpired: $isTokenExpired, '
        'hasRefreshToken: $hasRefreshToken, '
        'error: $error'
        ')';
  }
}
