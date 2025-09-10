import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for exporting and importing settings
class SettingsExportImportDialog extends StatefulWidget {
  final String Function() onExport;
  final Future<void> Function(String) onImport;

  const SettingsExportImportDialog({
    super.key,
    required this.onExport,
    required this.onImport,
  });

  @override
  State<SettingsExportImportDialog> createState() => _SettingsExportImportDialogState();
}

class _SettingsExportImportDialogState extends State<SettingsExportImportDialog> {
  final TextEditingController _importController = TextEditingController();
  bool _isImporting = false;

  @override
  void dispose() {
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export/Import Settings'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Export your current settings to share or backup.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exportSettings,
                icon: const Icon(Icons.download),
                label: const Text('Export to Clipboard'),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Import Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Paste exported settings JSON to import.'),
            const SizedBox(height: 16),
            TextField(
              controller: _importController,
              decoration: const InputDecoration(
                labelText: 'Settings JSON',
                hintText: 'Paste exported settings here...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isImporting ? null : _importSettings,
                icon: _isImporting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isImporting ? 'Importing...' : 'Import Settings'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  void _exportSettings() {
    try {
      final settingsJson = widget.onExport();
      Clipboard.setData(ClipboardData(text: settingsJson));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings exported to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importSettings() async {
    final settingsJson = _importController.text.trim();
    
    if (settingsJson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please paste settings JSON first'),
        ),
      );
      return;
    }

    setState(() {
      _isImporting = true;
    });

    try {
      await widget.onImport(settingsJson);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings imported successfully'),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
      }
    }
  }
}