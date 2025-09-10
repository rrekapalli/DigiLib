import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/document.dart';
import '../../models/entities/tag.dart';
import '../../providers/tag_provider.dart';
import '../../widgets/tag_selection_dialog.dart';
import '../../widgets/tag_autocomplete_field.dart';

/// Screen for managing tags for a specific document
class DocumentTaggingScreen extends ConsumerStatefulWidget {
  final Document document;

  const DocumentTaggingScreen({
    super.key,
    required this.document,
  });

  @override
  ConsumerState<DocumentTaggingScreen> createState() => _DocumentTaggingScreenState();
}

class _DocumentTaggingScreenState extends ConsumerState<DocumentTaggingScreen> {
  List<Tag> _documentTags = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDocumentTags();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showTagSelectionDialog(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Tags',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'select_all',
                child: ListTile(
                  leading: Icon(Icons.select_all),
                  title: Text('Select All Tags'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: ListTile(
                  leading: Icon(Icons.clear_all),
                  title: Text('Remove All Tags'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share Tags'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Document info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getDocumentIcon(widget.document.extension),
                      color: _getDocumentColor(widget.document.extension),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.document.title ?? widget.document.filename ?? 'Unknown Document',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.document.author != null && widget.document.author!.isNotEmpty)
                            Text(
                              widget.document.author!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.label,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_documentTags.length} tag${_documentTags.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Quick add section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Add',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TagAutocompleteField(
                  hintText: 'Search or create tags to add...',
                  excludeTags: _documentTags,
                  onTagSelected: _addTag,
                  onTagCreated: _createAndAddTag,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Current tags
          Expanded(
            child: _buildTagsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTagSelectionDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Tags'),
      ),
    );
  }

  Widget _buildTagsList() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tags...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tags',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loadDocumentTags,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_documentTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline,
              size: 80,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tags Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add tags to organize and categorize this document.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showTagSelectionDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Tags'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Current Tags',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _documentTags.length,
            itemBuilder: (context, index) {
              final tag = _documentTags[index];
              return _buildTagTile(tag);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagTile(Tag tag) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagColor = _getTagColor(tag.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: tagColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: tagColor.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(
            Icons.label,
            color: tagColor,
            size: 16,
          ),
        ),
        title: Text(
          tag.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'Added ${_formatDate(tag.createdAt)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tagColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '0 docs', // Mock usage count
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _removeTag(tag),
              icon: Icon(
                Icons.remove_circle_outline,
                color: colorScheme.error,
              ),
              tooltip: 'Remove tag',
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'select_all':
        _showTagSelectionDialog();
        break;
      case 'clear_all':
        _clearAllTags();
        break;
      case 'export':
        _exportTags();
        break;
    }
  }

  void _showTagSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => TagSelectionDialog(
        document: widget.document,
        currentTags: _documentTags,
        onTagsSelected: _updateDocumentTags,
      ),
    );
  }

  Future<void> _loadDocumentTags() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Mock implementation - in real app, this would call the tag service
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock tags for demonstration
      final mockTags = [
        Tag(
          id: '1',
          ownerId: 'user1',
          name: 'Important',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Tag(
          id: '2',
          ownerId: 'user1',
          name: 'Work',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        ),
      ];

      setState(() {
        _documentTags = mockTags;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _addTag(Tag tag) {
    if (!_documentTags.any((t) => t.id == tag.id)) {
      setState(() {
        _documentTags.add(tag);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added tag "${tag.name}"'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _createAndAddTag(String tagName) async {
    try {
      final newTag = await ref.read(tagProvider.notifier).createTag(tagName);
      _addTag(newTag);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create tag: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _removeTag(Tag tag) {
    setState(() {
      _documentTags.removeWhere((t) => t.id == tag.id);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Removed tag "${tag.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => _addTag(tag),
        ),
      ),
    );
  }

  void _updateDocumentTags(List<Tag> newTags) {
    setState(() {
      _documentTags = newTags;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Updated tags for document'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAllTags() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove All Tags'),
        content: const Text(
          'Are you sure you want to remove all tags from this document?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _documentTags.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All tags removed'),
                ),
              );
            },
            child: const Text('Remove All'),
          ),
        ],
      ),
    );
  }

  void _exportTags() {
    final tagNames = _documentTags.map((tag) => tag.name).join(', ');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Document tags:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tagNames.isNotEmpty ? tagNames : 'No tags',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () {
              // In a real app, this would copy to clipboard or share
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tags copied to clipboard'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  IconData _getDocumentIcon(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'epub':
        return Icons.menu_book;
      case 'docx':
      case 'doc':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocumentColor(String? extension) {
    switch (extension?.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'epub':
        return Colors.green;
      case 'docx':
      case 'doc':
        return Colors.blue;
      case 'txt':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getTagColor(String tagName) {
    final hash = tagName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}