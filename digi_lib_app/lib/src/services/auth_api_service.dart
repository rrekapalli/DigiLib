import '../network/api_client.dart';
import '../models/api/auth_result.dart';
import '../models/entities/user.dart';
import '../models/api/api_error.dart';
import 'secure_storage_service.dart';

/// Service for handling authentication API calls
abstract class AuthApiService {
  /// Sign in with OAuth2 provider
  Future<AuthResult> signInWithOAuth2(String provider, String code, String state, String redirectUri);
  
  /// Refresh access token using refresh token
  Future<AuthResult> refreshToken();
  
  /// Get current authenticated user
  Future<User> getCurrentUser();
  
  /// Sign out and clear tokens
  Future<void> signOut();
  
  /// Check if user is currently authenticated
  bool get isAuthenticated;
  
  /// Get current access token
  String? get currentAccessToken;
}

/// Implementation of AuthApiService
class AuthApiServiceImpl implements AuthApiService {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  
  String? _currentAccessToken;
  DateTime? _tokenExpiresAt;

  AuthApiServiceImpl(this._apiClient, this._secureStorage);

  @override
  bool get isAuthenticated => _currentAccessToken != null && !_isTokenExpired();

  @override
  String? get currentAccessToken => _currentAccessToken;

  bool _isTokenExpired() {
    if (_tokenExpiresAt == null) return true;
    return DateTime.now().isAfter(_tokenExpiresAt!.subtract(const Duration(minutes: 5))); // 5 minute buffer
  }

  @override
  Future<AuthResult> signInWithOAuth2(String provider, String code, String state, String redirectUri) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/oauth2/$provider',
        body: {
          'code': code,
          'state': state,
          'redirect_uri': redirectUri,
        },
      );

      final authResult = AuthResult.fromJson(response);
      await _storeTokens(authResult);
      return authResult;
    } catch (e) {
      throw _handleAuthError(e, 'OAuth2 sign-in failed');
    }
  }

  @override
  Future<AuthResult> refreshToken() async {
    try {
      final storedRefreshToken = await _secureStorage.getRefreshToken();
      if (storedRefreshToken == null) {
        throw ApiException(
          ApiError(
            message: 'No refresh token available',
            code: 'NO_REFRESH_TOKEN',
            timestamp: DateTime.now(),
          ),
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        body: {
          'refresh_token': storedRefreshToken,
        },
      );

      final authResult = AuthResult.fromJson(response);
      await _storeTokens(authResult);
      return authResult;
    } catch (e) {
      // If refresh fails, clear stored tokens
      await _clearTokens();
      throw _handleAuthError(e, 'Token refresh failed');
    }
  }

  @override
  Future<User> getCurrentUser() async {
    try {
      await _ensureValidToken();
      
      final response = await _apiClient.get<Map<String, dynamic>>('/api/users/me');
      return User.fromJson(response);
    } catch (e) {
      throw _handleAuthError(e, 'Failed to get current user');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Try to notify server about logout (optional, don't fail if it doesn't work)
      if (_currentAccessToken != null) {
        try {
          await _apiClient.post('/auth/logout');
        } catch (e) {
          // Ignore logout API errors, still clear local tokens
        }
      }
    } finally {
      await _clearTokens();
    }
  }

  /// Ensure we have a valid access token, refreshing if necessary
  Future<void> _ensureValidToken() async {
    if (_currentAccessToken == null) {
      // Try to load token from storage
      final storedToken = await _secureStorage.getSecureData('access_token');
      if (storedToken != null) {
        _currentAccessToken = storedToken;
        _apiClient.setAuthToken(storedToken);
        
        // Check if we have expiration info
        final expiresAtString = await _secureStorage.getSecureData('token_expires_at');
        if (expiresAtString != null) {
          _tokenExpiresAt = DateTime.tryParse(expiresAtString);
        }
      }
    }

    if (_currentAccessToken == null) {
      throw ApiException(
        ApiError(
          message: 'No access token available. Please sign in.',
          code: 'NO_ACCESS_TOKEN',
          timestamp: DateTime.now(),
        ),
      );
    }

    if (_isTokenExpired()) {
      await refreshToken();
    }
  }

  /// Store authentication tokens securely
  Future<void> _storeTokens(AuthResult authResult) async {
    _currentAccessToken = authResult.accessToken;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: authResult.expiresIn));

    // Store tokens securely
    await _secureStorage.storeSecureData('access_token', authResult.accessToken);
    await _secureStorage.storeRefreshToken(authResult.refreshToken);
    await _secureStorage.storeSecureData('token_expires_at', _tokenExpiresAt!.toIso8601String());

    // Set auth token in API client
    _apiClient.setAuthToken(authResult.accessToken);
  }

  /// Clear all stored tokens
  Future<void> _clearTokens() async {
    _currentAccessToken = null;
    _tokenExpiresAt = null;

    await _secureStorage.deleteSecureData('access_token');
    await _secureStorage.clearRefreshToken();
    await _secureStorage.deleteSecureData('token_expires_at');

    _apiClient.clearAuthToken();
  }

  /// Handle authentication-specific errors
  ApiException _handleAuthError(Object error, String context) {
    if (error is ApiException) {
      // Add context to existing API exception
      return ApiException(
        error.error.copyWith(
          message: '${error.error.message} ($context)',
        ),
        error.originalMessage,
      );
    }

    // Create new API exception for other errors
    return ApiException(
      ApiError(
        message: '$context: ${error.toString()}',
        code: 'AUTH_ERROR',
        timestamp: DateTime.now(),
      ),
      error.toString(),
    );
  }

  /// Initialize the service by loading stored tokens
  Future<void> initialize() async {
    try {
      final storedToken = await _secureStorage.getSecureData('access_token');
      if (storedToken != null) {
        _currentAccessToken = storedToken;
        _apiClient.setAuthToken(storedToken);
        
        // Load expiration info
        final expiresAtString = await _secureStorage.getSecureData('token_expires_at');
        if (expiresAtString != null) {
          _tokenExpiresAt = DateTime.tryParse(expiresAtString);
        }
      }
    } catch (e) {
      // If there's an error loading tokens, clear everything
      await _clearTokens();
    }
  }
}

/// Mock implementation for testing
class MockAuthApiService implements AuthApiService {
  bool _isAuthenticated = false;
  String? _accessToken;
  User? _currentUser;

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  String? get currentAccessToken => _accessToken;

  @override
  Future<AuthResult> signInWithOAuth2(String provider, String code, String state, String redirectUri) async {
    _isAuthenticated = true;
    _accessToken = 'mock-access-token';
    
    return const AuthResult(
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<AuthResult> refreshToken() async {
    if (!_isAuthenticated) {
      throw ApiException(
        ApiError(
          message: 'No refresh token available',
          code: 'NO_REFRESH_TOKEN',
          timestamp: DateTime.now(),
        ),
      );
    }

    return const AuthResult(
      accessToken: 'mock-refreshed-access-token',
      refreshToken: 'mock-refresh-token',
      expiresIn: 3600,
      tokenType: 'Bearer',
    );
  }

  @override
  Future<User> getCurrentUser() async {
    if (!_isAuthenticated) {
      throw ApiException(
        ApiError(
          message: 'Not authenticated',
          code: 'NOT_AUTHENTICATED',
          timestamp: DateTime.now(),
        ),
      );
    }

    _currentUser ??= User(
      id: 'mock-user-id',
      email: 'test@example.com',
      name: 'Test User',
      provider: 'google',
      providerId: 'mock-provider-id',
      createdAt: DateTime.now(),
    );

    return _currentUser!;
  }

  @override
  Future<void> signOut() async {
    _isAuthenticated = false;
    _accessToken = null;
    _currentUser = null;
  }

  void setAuthenticated(bool authenticated, {String? token, User? user}) {
    _isAuthenticated = authenticated;
    _accessToken = token;
    _currentUser = user;
  }
}