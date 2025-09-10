import 'package:flutter/material.dart';
import '../models/entities/library.dart';

/// Dialog for configuring library settings
class LibrarySettingsDialog extends StatefulWidget {
  final Library library;
  final Function(Library) onUpdate;

  const LibrarySettingsDialog({
    super.key,
    required this.library,
    required this.onUpdate,
  });

  @override
  State<LibrarySettingsDialog> createState() => _LibrarySettingsDialogState();
}

class _LibrarySettingsDialogState extends State<LibrarySettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.library.name;
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

    return AlertDialog(
      title: Text('Settings - ${widget.library.name}'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Library name field
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

              const SizedBox(height: 16),

              // Library type (read-only)
              Text(
                'Type: ${_getLibraryTypeDisplayName(widget.library.type)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 8),

              // Created date (read-only)
              Text(
                'Created: ${_formatDate(widget.library.createdAt)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),

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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _handleUpdate,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final updatedLibrary = widget.library.copyWith(
        name: _nameController.text.trim(),
      );

      widget.onUpdate(updatedLibrary);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update library: $e';
        _isLoading = false;
      });
    }
  }
}