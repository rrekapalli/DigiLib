import 'package:flutter/material.dart';

/// Loading screen shown during authentication processes
class AuthLoadingScreen extends StatelessWidget {
  final String? message;
  final bool showProgress;

  const AuthLoadingScreen({
    super.key,
    this.message,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.library_books,
                size: 40,
                color: colorScheme.primary,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Loading indicator
            if (showProgress) ...[
              CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
            ],
            
            // Message
            Text(
              message ?? 'Setting up your digital library...',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Please wait a moment',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}