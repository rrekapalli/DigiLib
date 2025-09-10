import 'package:flutter/material.dart';
import '../models/ui/document_view_settings.dart';

/// Dialog for selecting document sort options
class DocumentSortDialog extends StatefulWidget {
  final DocumentViewSettings currentSettings;
  final Function(DocumentViewSettings settings) onSettingsChanged;

  const DocumentSortDialog({
    super.key,
    required this.currentSettings,
    required this.onSettingsChanged,
  });

  @override
  State<DocumentSortDialog> createState() => _DocumentSortDialogState();
}

class _DocumentSortDialogState extends State<DocumentSortDialog> {
  late DocumentSortBy _sortBy;
  late bool _ascending;

  @override
  void initState() {
    super.initState();
    _sortBy = widget.currentSettings.sortBy;
    _ascending = widget.currentSettings.ascending;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Sort Documents'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sort by',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Sort options
          ...DocumentSortBy.values.map((sortBy) {
            return RadioListTile<DocumentSortBy>(
              title: Text(_getSortDisplayName(sortBy)),
              value: sortBy,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
              },
              contentPadding: EdgeInsets.zero,
            );
          }),
          
          const SizedBox(height: 16),
          
          Text(
            'Order',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Sort direction
          RadioListTile<bool>(
            title: const Text('Ascending (A-Z, 0-9)'),
            value: true,
            groupValue: _ascending,
            onChanged: (value) {
              setState(() {
                _ascending = value!;
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text('Descending (Z-A, 9-0)'),
            value: false,
            groupValue: _ascending,
            onChanged: (value) {
              setState(() {
                _ascending = value!;
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
              sortBy: _sortBy,
              ascending: _ascending,
            );
            widget.onSettingsChanged(newSettings);
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _getSortDisplayName(DocumentSortBy sortBy) {
    switch (sortBy) {
      case DocumentSortBy.name:
        return 'Name';
      case DocumentSortBy.author:
        return 'Author';
      case DocumentSortBy.dateCreated:
        return 'Date Created';
      case DocumentSortBy.dateModified:
        return 'Date Modified';
      case DocumentSortBy.size:
        return 'File Size';
      case DocumentSortBy.pageCount:
        return 'Page Count';
    }
  }
}