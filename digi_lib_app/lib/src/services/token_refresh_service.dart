import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';

/// Service that handles automatic token refresh
class TokenRefreshService {
  final Ref _ref;
  Timer? _refreshTimer;
  ProviderSubscription<AuthState>? _authSubscription;

  TokenRefreshService(this._ref) {
    _startListening();
  }

  void _startListening() {
    _authSubscription = _ref.listen<AuthState>(
      authProvider,
      (previous, current) {
        _handleAuthStateChange(current);
      },
    );
  }

  void _handleAuthStateChange(AuthState authState) {
    _cancelRefreshTimer();

    if (authState.isAuthenticated && authState.tokenExpiresAt != null) {
      _scheduleTokenRefresh(authState.tokenExpiresAt!);
    }
  }

  void _scheduleTokenRefresh(DateTime expiresAt) {
    // Schedule refresh 5 minutes before expiration
    final refreshTime = expiresAt.subtract(const Duration(minutes: 5));
    final timeUntilRefresh = refreshTime.difference(DateTime.now());

    if (timeUntilRefresh.isNegative) {
      // Token is already expired or about to expire, refresh immediately
      _performTokenRefresh();
      return;
    }

    _refreshTimer = Timer(timeUntilRefresh, () {
      _performTokenRefresh();
    });
  }

  void _performTokenRefresh() async {
    try {
      final authNotifier = _ref.read(authProvider.notifier);
      await authNotifier.refreshToken();
    } catch (e) {
      // Token refresh failed, the auth provider will handle the error
      // and potentially sign out the user
    }
  }

  void _cancelRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void dispose() {
    _cancelRefreshTimer();
    _authSubscription?.close();
  }
}

/// Provider for TokenRefreshService
final tokenRefreshServiceProvider = Provider<TokenRefreshService>((ref) {
  final service = TokenRefreshService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});