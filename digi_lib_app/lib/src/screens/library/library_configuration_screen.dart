import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/library.dart';
import '../../models/api/create_library_request.dart';
import '../../providers/library_provider.dart';
import '../../widgets/local_folder_picker.dart';
import '../../widgets/cloud_provider_config.dart';
import '../../widgets/scan_progress_widget.dart';

/// Screen for configuring a new or existing library
class LibraryConfigurationScreen extends ConsumerStatefulWidget {
  final Library? library;
  final LibraryType libraryType;
  final String libraryName;

  const LibraryConfigurationScreen({
    super.key,
    this.library,
    required this.libraryType,
    required this.libraryName,
  });

  @override
  ConsumerState<LibraryConfigurationScreen> createState() => _LibraryConfigurationScreenState();
}

class _LibraryConfigurationScreenState extends ConsumerState<LibraryConfigurationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  Map<String, dynamic> _config = {};
  bool _isConfigValid = false;
  bool _isLoading = false;
  String? _error;
  String? _currentScanJobId;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.libraryName;
    _config = Map<String, dynamic>.from(widget.library?.config ?? {});
    _validateConfiguration();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditing = widget.library != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Configure Library' : 'Add Library'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Library name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Library Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a library name';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 24),

              // Library type display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getLibraryTypeIcon(widget.libraryType),
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Type: ${_getLibraryTypeDisplayName(widget.libraryType)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Configuration based on library type
              _buildConfigurationWidget(),

              // Error message
              if (_error != null) ...[
                const SizedBox(height: 16),
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
                          _error!,
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

              // Scan progress (if scanning)
              if (_currentScanJobId != null) ...[
                const SizedBox(height: 24),
                ScanProgressWidget(
                  libraryId: widget.library?.id ?? '',
                  onCancel: _cancelScan,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: (_isConfigValid && !_isLoading) ? _saveLibrary : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Update' : 'Create'),
              ),
            ),
            if (isEditing && _isConfigValid) ...[
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _startScan,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Scan'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationWidget() {
    switch (widget.libraryType) {
      case LibraryType.local:
        return LocalFolderPicker(
          initialPath: _config['path'] as String?,
          onPathSelected: (path) {
            setState(() {
              _config['path'] = path;
            });
            _validateConfiguration();
          },
          enabled: !_isLoading,
        );
      
      case LibraryType.gdrive:
      case LibraryType.onedrive:
      case LibraryType.s3:
        return CloudProviderConfig(
          providerType: widget.libraryType,
          initialConfig: _config,
          onConfigChanged: (config) {
            setState(() {
              _config = config;
            });
            _validateConfiguration();
          },
          enabled: !_isLoading,
        );
      
      default:
        return const SizedBox.shrink();
    }
  }

  void _validateConfiguration() {
    bool isValid = false;

    switch (widget.libraryType) {
      case LibraryType.local:
        isValid = _config['path'] != null && 
                  (_config['path'] as String).isNotEmpty;
        break;
      
      case LibraryType.gdrive:
      case LibraryType.onedrive:
        isValid = _config.containsKey('access_token') &&
                  _config.containsKey('folder_id');
        break;
      
      case LibraryType.s3:
        isValid = _config.containsKey('access_token') &&
                  _config.containsKey('bucket') &&
                  (_config['bucket'] as String).isNotEmpty;
        break;
    }

    setState(() {
      _isConfigValid = isValid;
    });
  }

  Future<void> _saveLibrary() async {
    if (!_formKey.currentState!.validate() || !_isConfigValid) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.library != null) {
        // Update existing library
        // TODO: Implement library update functionality
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library updated successfully'),
          ),
        );
      } else {
        // Create new library
        final request = CreateLibraryRequest(
          name: _nameController.text.trim(),
          type: widget.libraryType,
          config: _config,
        );

        await ref.read(libraryProvider.notifier).addLibrary(request);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Library created successfully'),
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to save library: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _startScan() async {
    if (widget.library == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final scanJob = await ref.read(libraryProvider.notifier).scanLibrary(widget.library!.id);
      
      setState(() {
        _currentScanJobId = scanJob.id;
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Library scan started'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to start scan: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelScan() async {
    if (_currentScanJobId == null) return;

    try {
      await ref.read(libraryProvider.notifier).cancelScanJob(_currentScanJobId!);
      
      setState(() {
        _currentScanJobId = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scan cancelled'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to cancel scan: $e';
      });
    }
  }

  IconData _getLibraryTypeIcon(LibraryType type) {
    switch (type) {
      case LibraryType.local:
        return Icons.folder;
      case LibraryType.gdrive:
        return Icons.cloud;
      case LibraryType.onedrive:
        return Icons.cloud;
      case LibraryType.s3:
        return Icons.cloud_queue;
    }
  }

  String _getLibraryTypeDisplayName(LibraryType type) {
    switch (type) {
      case LibraryType.local:
        return 'Local Folder';
      case LibraryType.gdrive:
        return 'Google Drive';
      case LibraryType.onedrive:
        return 'OneDrive';
      case LibraryType.s3:
        return 'Amazon S3';
    }
  }
}