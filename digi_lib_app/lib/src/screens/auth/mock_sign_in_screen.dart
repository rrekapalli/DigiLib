import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/constants.dart';
import '../../utils/network_test.dart';
import '../../providers/auth_provider.dart';
import '../../models/api/auth_result.dart';
import '../../models/entities/user.dart';

/// Mock sign-in screen for testing without OAuth server
class MockSignInScreen extends ConsumerStatefulWidget {
  const MockSignInScreen({super.key});

  @override
  ConsumerState<MockSignInScreen> createState() => _MockSignInScreenState();
}

class _MockSignInScreenState extends ConsumerState<MockSignInScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mock Sign In'),
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
                    Icon(
                      Icons.bug_report,
                      size: 80,
                      color: colorScheme.primary,
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Mock Authentication',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'This is a test authentication screen\nfor development purposes',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 48),

                    if (_isLoading) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'Signing you in...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _mockSignIn,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Sign In with Mock User',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _testNetworkConnectivity,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppConstants.defaultBorderRadius,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Test API Connectivity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(
                    AppConstants.defaultBorderRadius,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'API Configuration:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base URL: ${AppConstants.baseUrl}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _mockSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Create mock auth result
      const authResult = AuthResult(
        accessToken: 'mock_access_token_${1234567890}',
        refreshToken: 'mock_refresh_token_${1234567890}',
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      // Create mock user
      final user = User(
        id: 'mock_user_id',
        email: 'test@example.com',
        name: 'Test User',
        provider: 'mock',
        providerId: 'mock_provider_id',
        createdAt: DateTime.now(),
      );

      // Sign in with mock data
      await ref.read(authProvider.notifier).signInWithOAuth2(authResult, user);

      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mock sign-in successful!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mock sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testNetworkConnectivity() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Testing network connectivity... Check debug console for results.',
        ),
      ),
    );

    // Run network test
    try {
      await NetworkTest.testApiConnectivity();
    } catch (e) {
      debugPrint('Network test error: $e');
    }
  }
}
