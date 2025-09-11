import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

/// Widget for picking local folders on desktop platforms
class LocalFolderPicker extends StatefulWidget {
  final String? initialPath;
  final Function(String) onPathSelected;
  final bool enabled;

  const LocalFolderPicker({
    super.key,
    this.initialPath,
    required this.onPathSelected,
    this.enabled = true,
  });

  @override
  State<LocalFolderPicker> createState() => _LocalFolderPickerState();
}

class _LocalFolderPickerState extends State<LocalFolderPicker> {
  String? _selectedPath;
  bool _isValidPath = false;
  String? _pathError;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
    if (_selectedPath != null) {
      _validatePath(_selectedPath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Folder Location',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _pathError != null
                  ? colorScheme.error
                  : colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedPath != null) ...[
                        Text(_selectedPath!, style: theme.textTheme.bodyMedium),
                        if (_isValidPath) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Valid folder path',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        Text(
                          'No folder selected',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(8),
                child: FilledButton.icon(
                  onPressed: widget.enabled ? _pickFolder : null,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Browse'),
                ),
              ),
            ],
          ),
        ),

        if (_pathError != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.error, size: 16, color: colorScheme.error),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _pathError!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 8),

        Text(
          'Select a folder containing your digital documents. The app will scan this folder for supported file types (PDF, EPUB, DOCX).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Future<void> _pickFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      setState(() {
        _selectedPath = selectedDirectory;
        _pathError = null;
      });

      if (selectedDirectory != null) {
        _validatePath(selectedDirectory);
        widget.onPathSelected(selectedDirectory);
      }
    } catch (e) {
      setState(() {
        _pathError = 'Failed to select folder: $e';
        _isValidPath = false;
      });
    }
  }

  void _validatePath(String path) {
    try {
      final directory = Directory(path);

      if (!directory.existsSync()) {
        setState(() {
          _pathError = 'Selected folder does not exist';
          _isValidPath = false;
        });
        return;
      }

      // Check if we can read the directory
      try {
        directory.listSync(recursive: false);
      } catch (e) {
        setState(() {
          _pathError = 'Cannot access selected folder. Check permissions.';
          _isValidPath = false;
        });
        return;
      }

      setState(() {
        _pathError = null;
        _isValidPath = true;
      });
    } catch (e) {
      setState(() {
        _pathError = 'Invalid folder path: $e';
        _isValidPath = false;
      });
    }
  }

  bool get isValidPath => _isValidPath;
  String? get selectedPath => _selectedPath;
}
