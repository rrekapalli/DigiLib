import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_state.dart';
import 'oauth_webview_screen.dart';
import 'mock_sign_in_screen.dart';

/// OAuth2 sign-in screen with provider selection
class OAuthSignInScreen extends ConsumerWidget {
  const OAuthSignInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header
                    Icon(
                      Icons.login,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Sign in to your account',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Choose your preferred sign-in method',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // OAuth providers
                    _buildOAuthProviders(context, ref, authState),
                    
                    // Mock sign-in for development
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      Text(
                        'Development Mode',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: authState.isLoading ? null : () => _navigateToMockSignIn(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            ),
                            side: BorderSide(
                              color: Colors.orange.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.bug_report,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Mock Sign In (Testing)',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Loading indicator
                    if (authState.isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        _getLoadingMessage(authState),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    
                    // Error message
                    if (authState.hasError) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authState.error ?? 'An error occurred',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.read(authProvider.notifier).clearError(),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Help text
              Text(
                'Having trouble signing in?\nContact support for assistance',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthProviders(BuildContext context, WidgetRef ref, AuthState authState) {
    final providers = [
      {
        'id': 'google',
        'name': 'Google',
        'icon': Icons.g_mobiledata, // Using built-in icon, in real app would use custom Google icon
        'color': const Color(0xFF4285F4),
      },
      {
        'id': 'microsoft',
        'name': 'Microsoft',
        'icon': Icons.business,
        'color': const Color(0xFF00A4EF),
      },
      {
        'id': 'github',
        'name': 'GitHub',
        'icon': Icons.code,
        'color': const Color(0xFF333333),
      },
    ];

    return Column(
      children: providers.map((provider) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildProviderButton(
          context,
          ref,
          provider['id'] as String,
          provider['name'] as String,
          provider['icon'] as IconData,
          provider['color'] as Color,
          authState.isLoading,
        ),
      )).toList(),
    );
  }

  Widget _buildProviderButton(
    BuildContext context,
    WidgetRef ref,
    String providerId,
    String providerName,
    IconData icon,
    Color color,
    bool isLoading,
  ) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : () => _signInWithProvider(context, ref, providerId),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          ),
          side: BorderSide(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Continue with $providerName',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getLoadingMessage(AuthState authState) {
    switch (authState.status) {
      case AuthStatus.authenticating:
        return 'Signing you in...';
      case AuthStatus.loading:
        return 'Setting up your account...';
      case AuthStatus.refreshing:
        return 'Refreshing your session...';
      default:
        return 'Please wait...';
    }
  }

  void _signInWithProvider(BuildContext context, WidgetRef ref, String providerId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OAuthWebViewScreen(providerId: providerId),
      ),
    );
  }

  void _navigateToMockSignIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MockSignInScreen(),
      ),
    );
  }
}