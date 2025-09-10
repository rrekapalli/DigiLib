import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';
import 'welcome_screen.dart';
import 'auth_loading_screen.dart';
import '../main_app_screen.dart';

/// Wrapper that handles authentication state routing
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildScreenForAuthState(authState),
    );
  }

  Widget _buildScreenForAuthState(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.loading:
        return const AuthLoadingScreen(
          key: ValueKey('loading'),
          message: 'Checking your authentication...',
        );
        
      case AuthStatus.authenticating:
        return const AuthLoadingScreen(
          key: ValueKey('authenticating'),
          message: 'Signing you in...',
        );
        
      case AuthStatus.refreshing:
        return const AuthLoadingScreen(
          key: ValueKey('refreshing'),
          message: 'Refreshing your session...',
        );
        
      case AuthStatus.authenticated:
        return const MainAppScreen(
          key: ValueKey('authenticated'),
        );
        
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const WelcomeScreen(
          key: ValueKey('unauthenticated'),
        );
    }
  }
}