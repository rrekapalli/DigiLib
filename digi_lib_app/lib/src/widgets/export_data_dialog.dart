import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for exporting user data
class ExportDataDialog extends StatefulWidget {
  final Future<String> Function() onExport;

  const ExportDataDialog({
    super.key,
    required this.onExport,
  });

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  bool _isExporting = false;
  String? _exportedData;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Data'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isExporting && _exportedData == null) ...[
              const Text(
                'Export all your data including documents, bookmarks, comments, and settings.',
              ),
              const SizedBox(height: 16),
              const Text(
                'This may take a few moments depending on the amount of data.',
              ),
            ] else if (_isExporting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Exporting your data...'),
            ] else if (_exportedData != null) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text('Data exported successfully!'),
              const SizedBox(height: 16),
              const Text(
                'Your data has been copied to the clipboard. You can paste it into a text file to save it.',
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (!_isExporting && _exportedData == null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _exportData,
            child: const Text('Export'),
          ),
        ] else if (_exportedData != null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: _copyToClipboard,
            child: const Text('Copy Again'),
          ),
        ],
      ],
    );
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final data = await widget.onExport();
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: data));
      
      setState(() {
        _exportedData = data;
        _isExporting = false;
      });
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _copyToClipboard() async {
    if (_exportedData != null) {
      await Clipboard.setData(ClipboardData(text: _exportedData!));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data copied to clipboard')),
        );
      }
    }
  }
}