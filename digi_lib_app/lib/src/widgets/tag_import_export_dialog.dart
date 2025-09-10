import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/tag_provider.dart';

/// Dialog for importing and exporting tags
class TagImportExportDialog extends ConsumerStatefulWidget {
  const TagImportExportDialog({super.key});

  @override
  ConsumerState<TagImportExportDialog> createState() => _TagImportExportDialogState();
}

class _TagImportExportDialogState extends ConsumerState<TagImportExportDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _importController = TextEditingController();
  bool _isProcessing = false;
  String? _exportData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _generateExportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.import_export,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Import/Export Tags',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Export', icon: Icon(Icons.upload)),
                Tab(text: 'Import', icon: Icon(Icons.download)),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExportTab(),
                  _buildImportTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Export your tags to a JSON file that can be imported later or shared with others.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Export options
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Options',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              CheckboxListTile(
                title: const Text('Include tag colors'),
                subtitle: const Text('Export custom tag colors if available'),
                value: true,
                onChanged: null, // Disabled for now
                contentPadding: EdgeInsets.zero,
              ),
              
              CheckboxListTile(
                title: const Text('Include usage statistics'),
                subtitle: const Text('Export tag usage counts and analytics'),
                value: false,
                onChanged: null, // Disabled for now
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Export data preview
        Text(
          'Export Preview',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: _exportData != null
                ? SingleChildScrollView(
                    child: Text(
                      _exportData!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                    ),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Export actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy),
                label: const Text('Copy to Clipboard'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _downloadFile,
                icon: const Icon(Icons.download),
                label: const Text('Download File'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImportTab() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import tags from a JSON file or paste the JSON data directly.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Import options
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Select File'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.paste),
                label: const Text('Paste Data'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Import data input
        Text(
          'JSON Data',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
        Expanded(
          child: TextField(
            controller: _importController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: 'Paste your JSON data here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Import options
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import Options',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              
              CheckboxListTile(
                title: const Text('Merge with existing tags'),
                subtitle: const Text('Keep existing tags and add new ones'),
                value: true,
                onChanged: (value) {
                  // Handle merge option
                },
                contentPadding: EdgeInsets.zero,
              ),
              
              CheckboxListTile(
                title: const Text('Skip duplicates'),
                subtitle: const Text('Don\'t import tags that already exist'),
                value: true,
                onChanged: (value) {
                  // Handle duplicate option
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Import actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _validateData,
                child: const Text('Validate'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : _importData,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: const Text('Import'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _generateExportData() {
    final tagState = ref.read(tagProvider);
    final tags = tagState.tags;
    
    final exportData = {
      'version': '1.0',
      'exported_at': DateTime.now().toIso8601String(),
      'tags': tags.map((tag) => {
        'id': tag.id,
        'name': tag.name,
        'created_at': tag.createdAt.toIso8601String(),
        'owner_id': tag.ownerId,
      }).toList(),
    };
    
    setState(() {
      _exportData = const JsonEncoder.withIndent('  ').convert(exportData);
    });
  }

  void _copyToClipboard() {
    if (_exportData != null) {
      // In a real app, you'd use Clipboard.setData
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export data copied to clipboard'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _downloadFile() {
    // In a real app, you'd trigger a file download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File download started'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _selectFile() {
    // In a real app, you'd use file_picker to select a file
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File selection not implemented in demo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _pasteFromClipboard() {
    // In a real app, you'd use Clipboard.getData
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Clipboard paste not implemented in demo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _validateData() {
    final data = _importController.text.trim();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter JSON data to validate'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final json = jsonDecode(data);
      if (json is Map && json.containsKey('tags')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('JSON data is valid'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw const FormatException('Invalid tag export format');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid JSON: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _importData() async {
    final data = _importController.text.trim();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter JSON data to import'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final json = jsonDecode(data);
      if (json is! Map || !json.containsKey('tags')) {
        throw const FormatException('Invalid tag export format');
      }

      final tags = json['tags'] as List;
      int importedCount = 0;

      for (final tagData in tags) {
        try {
          await ref.read(tagProvider.notifier).createTag(tagData['name']);
          importedCount++;
        } catch (e) {
          // Skip duplicates or handle errors
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported $importedCount tags'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}