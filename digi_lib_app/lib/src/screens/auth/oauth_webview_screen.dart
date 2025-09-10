import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_api_service.dart';

/// WebView screen for OAuth2 authentication flow
class OAuthWebViewScreen extends ConsumerStatefulWidget {
  final String providerId;

  const OAuthWebViewScreen({
    super.key,
    required this.providerId,
  });

  @override
  ConsumerState<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends ConsumerState<OAuthWebViewScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  String? _error;
  
  // OAuth2 configuration
  static const String _redirectUri = 'com.digitallibrary.app://oauth/callback';
  static const String _clientId = 'your-oauth-client-id'; // This would come from config
  
  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _error = null;
            });
            _handleNavigation(url);
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _error = 'Failed to load authentication page: ${error.description}';
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith(_redirectUri)) {
              _handleNavigation(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    _loadOAuthUrl();
  }

  void _loadOAuthUrl() {
    final authUrl = _buildOAuthUrl();
    _controller.loadRequest(Uri.parse(authUrl));
  }

  String _buildOAuthUrl() {
    final baseUrl = AppConstants.baseUrl;
    final state = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Store state for validation (in real app, this would be more secure)
    
    switch (widget.providerId) {
      case 'google':
        return '$baseUrl/auth/oauth2/google'
            '?client_id=$_clientId'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
            '&response_type=code'
            '&scope=${Uri.encodeComponent('openid email profile')}'
            '&state=$state';
      case 'microsoft':
        return '$baseUrl/auth/oauth2/microsoft'
            '?client_id=$_clientId'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
            '&response_type=code'
            '&scope=${Uri.encodeComponent('openid email profile')}'
            '&state=$state';
      case 'github':
        return '$baseUrl/auth/oauth2/github'
            '?client_id=$_clientId'
            '&redirect_uri=${Uri.encodeComponent(_redirectUri)}'
            '&response_type=code'
            '&scope=${Uri.encodeComponent('user:email')}'
            '&state=$state';
      default:
        throw ArgumentError('Unsupported OAuth provider: ${widget.providerId}');
    }
  }

  void _handleNavigation(String url) {
    if (url.startsWith(_redirectUri)) {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];
      final state = uri.queryParameters['state'];
      final error = uri.queryParameters['error'];
      final errorDescription = uri.queryParameters['error_description'];

      if (error != null) {
        _handleOAuthError(error, errorDescription);
      } else if (code != null && state != null) {
        _handleOAuthSuccess(code, state);
      } else {
        _handleOAuthError('invalid_response', 'Missing authorization code or state');
      }
    }
  }

  void _handleOAuthSuccess(String code, String state) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Create a mock auth service for now (in real app, would use dependency injection)
      final authService = MockAuthApiService();
      
      // Exchange code for tokens
      final authResult = await authService.signInWithOAuth2(
        widget.providerId,
        code,
        state,
        _redirectUri,
      );

      // Get user info
      final user = await authService.getCurrentUser();

      // Update auth state
      await ref.read(authProvider.notifier).signInWithOAuth2(authResult, user);

      if (mounted) {
        // Navigate back to main app (this will be handled by auth state routing)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      _handleOAuthError('authentication_failed', e.toString());
    }
  }

  void _handleOAuthError(String error, String? description) {
    setState(() {
      _isLoading = false;
      _error = description ?? error;
    });

    // Show error dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Authentication Failed'),
          content: Text(_error ?? 'An unknown error occurred'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Go back to sign-in screen
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadOAuthUrl(); // Retry
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sign in with ${_getProviderDisplayName()}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadOAuthUrl,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () => _openInExternalBrowser(),
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Open in browser',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_error == null)
            WebViewWidget(controller: _controller)
          else
            _buildErrorView(),
          
          if (_isLoading)
            Container(
              color: colorScheme.surface.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading authentication page...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Authentication Error',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              _error ?? 'An unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
                FilledButton(
                  onPressed: _loadOAuthUrl,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getProviderDisplayName() {
    switch (widget.providerId) {
      case 'google':
        return 'Google';
      case 'microsoft':
        return 'Microsoft';
      case 'github':
        return 'GitHub';
      default:
        return widget.providerId;
    }
  }

  void _openInExternalBrowser() async {
    final authUrl = _buildOAuthUrl();
    final uri = Uri.parse(authUrl);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open browser'),
          ),
        );
      }
    }
  }
}