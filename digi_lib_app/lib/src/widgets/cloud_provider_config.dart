import 'package:flutter/material.dart';
import '../models/entities/library.dart';

/// Widget for configuring cloud provider settings
class CloudProviderConfig extends StatefulWidget {
  final LibraryType providerType;
  final Map<String, dynamic>? initialConfig;
  final Function(Map<String, dynamic>) onConfigChanged;
  final bool enabled;

  const CloudProviderConfig({
    super.key,
    required this.providerType,
    this.initialConfig,
    required this.onConfigChanged,
    this.enabled = true,
  });

  @override
  State<CloudProviderConfig> createState() => _CloudProviderConfigState();
}

class _CloudProviderConfigState extends State<CloudProviderConfig> {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  String? _authError;
  Map<String, dynamic> _config = {};

  @override
  void initState() {
    super.initState();
    _config = Map<String, dynamic>.from(widget.initialConfig ?? {});
    _checkAuthenticationStatus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_getProviderDisplayName(widget.providerType)} Configuration',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Authentication status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isAuthenticated 
                ? Colors.green.withValues(alpha: 0.1)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isAuthenticated 
                  ? Colors.green.withValues(alpha: 0.3)
                  : colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _isAuthenticated ? Icons.check_circle : Icons.account_circle,
                color: _isAuthenticated ? Colors.green : colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAuthenticated 
                          ? 'Connected to ${_getProviderDisplayName(widget.providerType)}'
                          : 'Not connected',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _isAuthenticated ? Colors.green : null,
                      ),
                    ),
                    if (_isAuthenticated) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Account: ${_config['account_name'] ?? 'Unknown'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isAuthenticating) ...[
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ] else ...[
                FilledButton(
                  onPressed: widget.enabled 
                      ? (_isAuthenticated ? _disconnect : _authenticate)
                      : null,
                  style: _isAuthenticated 
                      ? FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        )
                      : null,
                  child: Text(_isAuthenticated ? 'Disconnect' : 'Connect'),
                ),
              ],
            ],
          ),
        ),
        
        // Authentication error
        if (_authError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error,
                  color: colorScheme.onErrorContainer,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _authError!,
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // Provider-specific configuration
        if (_isAuthenticated) ...[
          const SizedBox(height: 24),
          _buildProviderSpecificConfig(theme, colorScheme),
        ],
        
        const SizedBox(height: 16),
        
        Text(
          _getProviderDescription(widget.providerType),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildProviderSpecificConfig(ThemeData theme, ColorScheme colorScheme) {
    switch (widget.providerType) {
      case LibraryType.gdrive:
        return _buildGoogleDriveConfig(theme, colorScheme);
      case LibraryType.onedrive:
        return _buildOneDriveConfig(theme, colorScheme);
      case LibraryType.s3:
        return _buildS3Config(theme, colorScheme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoogleDriveConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folder Selection',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _config['folder_name'] ?? 'Root folder',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: widget.enabled ? _selectGoogleDriveFolder : null,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOneDriveConfig(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folder Selection',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _config['folder_name'] ?? 'Root folder',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              TextButton(
                onPressed: widget.enabled ? _selectOneDriveFolder : null,
                child: const Text('Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildS3Config(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'S3 Configuration',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        
        const SizedBox(height: 12),
        
        TextFormField(
          initialValue: _config['bucket'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Bucket Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _updateConfig('bucket', value),
          enabled: widget.enabled,
        ),
        
        const SizedBox(height: 12),
        
        TextFormField(
          initialValue: _config['prefix'] ?? '',
          decoration: const InputDecoration(
            labelText: 'Prefix (optional)',
            hintText: 'documents/',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _updateConfig('prefix', value),
          enabled: widget.enabled,
        ),
        
        const SizedBox(height: 12),
        
        DropdownButtonFormField<String>(
          initialValue: _config['region'] ?? 'us-east-1',
          decoration: const InputDecoration(
            labelText: 'Region',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: 'us-east-1', child: Text('US East (N. Virginia)')),
            DropdownMenuItem(value: 'us-west-2', child: Text('US West (Oregon)')),
            DropdownMenuItem(value: 'eu-west-1', child: Text('Europe (Ireland)')),
            DropdownMenuItem(value: 'ap-southeast-1', child: Text('Asia Pacific (Singapore)')),
          ],
          onChanged: widget.enabled ? (value) => _updateConfig('region', value) : null,
        ),
      ],
    );
  }

  void _checkAuthenticationStatus() {
    // In a real implementation, this would check stored credentials
    // For now, simulate based on config
    setState(() {
      _isAuthenticated = _config.containsKey('access_token') || 
                        _config.containsKey('credentials');
    });
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _authError = null;
    });

    try {
      // Simulate OAuth flow
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real implementation, this would:
      // 1. Open OAuth flow in webview or browser
      // 2. Handle the callback
      // 3. Store the tokens securely
      
      setState(() {
        _isAuthenticated = true;
        _isAuthenticating = false;
        _config['access_token'] = 'mock_access_token';
        _config['account_name'] = 'user@example.com';
        _config['folder_id'] = 'root';
        _config['folder_name'] = 'Root folder';
      });
      
      widget.onConfigChanged(_config);
      
    } catch (e) {
      setState(() {
        _authError = 'Authentication failed: $e';
        _isAuthenticating = false;
      });
    }
  }

  Future<void> _disconnect() async {
    setState(() {
      _isAuthenticated = false;
      _config.remove('access_token');
      _config.remove('account_name');
      _config.remove('folder_id');
      _config.remove('folder_name');
    });
    
    widget.onConfigChanged(_config);
  }

  void _selectGoogleDriveFolder() {
    // In a real implementation, this would show a Google Drive folder picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Drive folder picker would open here'),
      ),
    );
  }

  void _selectOneDriveFolder() {
    // In a real implementation, this would show a OneDrive folder picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OneDrive folder picker would open here'),
      ),
    );
  }

  void _updateConfig(String key, String? value) {
    setState(() {
      if (value != null && value.isNotEmpty) {
        _config[key] = value;
      } else {
        _config.remove(key);
      }
    });
    
    widget.onConfigChanged(_config);
  }

  String _getProviderDisplayName(LibraryType type) {
    switch (type) {
      case LibraryType.gdrive:
        return 'Google Drive';
      case LibraryType.onedrive:
        return 'OneDrive';
      case LibraryType.s3:
        return 'Amazon S3';
      default:
        return 'Cloud Provider';
    }
  }

  String _getProviderDescription(LibraryType type) {
    switch (type) {
      case LibraryType.gdrive:
        return 'Connect to your Google Drive account to access documents stored in your Google Drive folders.';
      case LibraryType.onedrive:
        return 'Connect to your Microsoft OneDrive account to access documents stored in your OneDrive folders.';
      case LibraryType.s3:
        return 'Configure access to an Amazon S3 bucket containing your documents. You\'ll need appropriate IAM permissions.';
      default:
        return 'Configure your cloud storage provider.';
    }
  }
}