import 'package:flutter/material.dart';
import '../models/ui/document_view_settings.dart';

/// Dialog for selecting document view mode and display options
class DocumentViewModeDialog extends StatefulWidget {
  final DocumentViewSettings currentSettings;
  final Function(DocumentViewSettings settings) onSettingsChanged;

  const DocumentViewModeDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<DocumentViewModeDialog> createState() => _DocumentViewModeDialogState();
}

class _DocumentViewModeDialogState extends State<DocumentViewModeDialog> {
  late DocumentViewMode _viewMode;
  late bool _showThumbnails;
  late bool _showMetadata;
  late int _gridColumns;

  @override
  void initState() {
    super.initState();
    _viewMode = widget.currentSettings.viewMode;
    _showThumbnails = widget.currentSettings.showThumbnails;
    _showMetadata = widget.currentSettings.showMetadata;
    _gridColumns = widget.currentSettings.gridColumns;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('View Options'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'View Mode',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // View mode options
          RadioListTile<DocumentViewMode>(
            title: const Text('List View'),
            subtitle: const Text('Detailed list with metadata'),
            value: DocumentViewMode.list,
            groupValue: _viewMode,
            onChanged: (value) {
              setState(() {
                _viewMode = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<DocumentViewMode>(
            title: const Text('Grid View'),
            subtitle: const Text('Compact grid with thumbnails'),
            value: DocumentViewMode.grid,
            groupValue: _viewMode,
            onChanged: (value) {
              setState(() {
                _viewMode = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 16),
          
          // Grid columns (only for grid view)
          if (_viewMode == DocumentViewMode.grid) ...[
            Text(
              'Grid Columns',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _gridColumns.toDouble(),
                    min: 1,
                    max: 4,
                    divisions: 3,
                    label: '$_gridColumns columns',
                    onChanged: (value) {
                      setState(() {
                        _gridColumns = value.round();
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    '$_gridColumns columns',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
          ],
          
          Text(
            'Display Options',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Display options
          CheckboxListTile(
            title: const Text('Show Thumbnails'),
            subtitle: const Text('Display document preview images'),
            value: _showThumbnails,
            onChanged: (value) {
              setState(() {
                _showThumbnails = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          CheckboxListTile(
            title: const Text('Show Metadata'),
            subtitle: const Text('Display file size, author, and other details'),
            value: _showMetadata,
            onChanged: (value) {
              setState(() {
                _showMetadata = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final newSettings = widget.currentSettings.copyWith(
              viewMode: _viewMode,
              showThumbnails: _showThumbnails,
              showMetadata: _showMetadata,
              gridColumns: _gridColumns,
            );
            widget.onSettingsChanged(newSettings);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}