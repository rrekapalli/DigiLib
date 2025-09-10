import 'package:flutter/material.dart';
import '../models/entities/library.dart';

import '../screens/library/library_configuration_screen.dart';

/// Dialog for adding a new library
class AddLibraryDialog extends StatefulWidget {
  const AddLibraryDialog({super.key});

  @override
  State<AddLibraryDialog> createState() => _AddLibraryDialogState();
}

class _AddLibraryDialogState extends State<AddLibraryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  LibraryType _selectedType = LibraryType.local;
  final bool _isLoading = false;
  String? _error;

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
      title: const Text('Add Library'),
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
                  hintText: 'Enter a name for your library',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a library name';
                  }
                  if (value.trim().length < 2) {
                    return 'Library name must be at least 2 characters';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),

              const SizedBox(height: 24),

              // Library type selection
              Text(
                'Library Type',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              ...LibraryType.values.map(
                (type) => _buildTypeOption(type, colorScheme),
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
          onPressed: _isLoading ? null : _handleAdd,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Library'),
        ),
      ],
    );
  }

  Widget _buildTypeOption(LibraryType type, ColorScheme colorScheme) {
    final isSelected = _selectedType == type;
    final typeInfo = _getTypeInfo(type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: _isLoading ? null : () => setState(() => _selectedType = type),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outline,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Radio<LibraryType>(
                value: type,
                groupValue: _selectedType,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => _selectedType = value);
                        }
                      },
              ),
              const SizedBox(width: 8),
              Icon(typeInfo.icon, color: typeInfo.color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      typeInfo.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeInfo.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
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

  LibraryTypeInfo _getTypeInfo(LibraryType type) {
    switch (type) {
      case LibraryType.local:
        return LibraryTypeInfo(
          title: 'Local Folder',
          description: 'Documents stored on your device',
          icon: Icons.folder,
          color: Colors.blue,
        );
      case LibraryType.gdrive:
        return LibraryTypeInfo(
          title: 'Google Drive',
          description: 'Documents from your Google Drive',
          icon: Icons.cloud,
          color: Colors.green,
        );
      case LibraryType.onedrive:
        return LibraryTypeInfo(
          title: 'OneDrive',
          description: 'Documents from your Microsoft OneDrive',
          icon: Icons.cloud,
          color: Colors.blue.shade700,
        );
      case LibraryType.s3:
        return LibraryTypeInfo(
          title: 'Amazon S3',
          description: 'Documents from an S3 bucket',
          icon: Icons.cloud_queue,
          color: Colors.orange,
        );
    }
  }

  Future<void> _handleAdd() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Close dialog and navigate to configuration screen
    Navigator.of(context).pop();

    // Navigate to configuration screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LibraryConfigurationScreen(
          libraryType: _selectedType,
          libraryName: _nameController.text.trim(),
        ),
      ),
    );
  }
}

class LibraryTypeInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const LibraryTypeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
