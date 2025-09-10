import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/auth_state.dart';

/// Widget that handles session timeout and re-authentication prompts
class SessionTimeoutHandler extends ConsumerStatefulWidget {
  final Widget child;

  const SessionTimeoutHandler({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<SessionTimeoutHandler> createState() => _SessionTimeoutHandlerState();
}

class _SessionTimeoutHandlerState extends ConsumerState<SessionTimeoutHandler> {
  bool _isShowingTimeoutDialog = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, current) {
      _handleAuthStateChange(previous, current);
    });

    return widget.child;
  }

  void _handleAuthStateChange(AuthState? previous, AuthState current) {
    // Handle token expiration and need for refresh
    if (current.needsTokenRefresh && !_isShowingTimeoutDialog) {
      _showTokenRefreshDialog();
    }

    // Handle authentication errors that might indicate session timeout
    if (current.hasError && 
        current.error?.contains('token') == true && 
        !_isShowingTimeoutDialog) {
      _showSessionTimeoutDialog();
    }

    // Clear dialog if authentication is restored
    if (current.isAuthenticated && _isShowingTimeoutDialog) {
      _isShowingTimeoutDialog = false;
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showTokenRefreshDialog() {
    if (_isShowingTimeoutDialog || !mounted) return;
    
    _isShowingTimeoutDialog = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.access_time),
            SizedBox(width: 8),
            Text('Session Expiring'),
          ],
        ),
        content: const Text(
          'Your session is about to expire. Would you like to refresh it to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isShowingTimeoutDialog = false;
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign Out'),
          ),
          FilledButton(
            onPressed: () {
              _isShowingTimeoutDialog = false;
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).forceRefresh();
            },
            child: const Text('Refresh Session'),
          ),
        ],
      ),
    ).then((_) {
      _isShowingTimeoutDialog = false;
    });
  }

  void _showSessionTimeoutDialog() {
    if (_isShowingTimeoutDialog || !mounted) return;
    
    _isShowingTimeoutDialog = true;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline),
            SizedBox(width: 8),
            Text('Session Expired'),
          ],
        ),
        content: const Text(
          'Your session has expired. Please sign in again to continue.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              _isShowingTimeoutDialog = false;
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).signOut();
            },
            child: const Text('Sign In Again'),
          ),
        ],
      ),
    ).then((_) {
      _isShowingTimeoutDialog = false;
    });
  }
}