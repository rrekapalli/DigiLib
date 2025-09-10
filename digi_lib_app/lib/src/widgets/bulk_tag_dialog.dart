import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../models/entities/document.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_autocomplete_field.dart';

/// Dialog for applying tags to multiple documents at once
class BulkTagDialog extends ConsumerStatefulWidget {
  final List<Document> documents;
  final Function(List<Tag> tags, BulkTagAction action) onApply;

  const BulkTagDialog({
    super.key,
    required this.documents,
    required this.onApply,
  });

  @override
  ConsumerState<BulkTagDialog> createState() => _BulkTagDialogState();
}

class _BulkTagDialogState extends ConsumerState<BulkTagDialog> {
  final Set<Tag> _selectedTags = <Tag>{};
  BulkTagAction _action = BulkTagAction.add;
  bool _isApplying = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                  Icons.label,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bulk Tag Documents',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${widget.documents.length} document${widget.documents.length == 1 ? '' : 's'} selected',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Action selection
            Text(
              'Action',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<BulkTagAction>(
                    title: const Text('Add tags to documents'),
                    subtitle: const Text('Add selected tags to all documents'),
                    value: BulkTagAction.add,
                    groupValue: _action,
                    onChanged: (value) => setState(() => _action = value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<BulkTagAction>(
                    title: const Text('Remove tags from documents'),
                    subtitle: const Text('Remove selected tags from all documents'),
                    value: BulkTagAction.remove,
                    groupValue: _action,
                    onChanged: (value) => setState(() => _action = value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<BulkTagAction>(
                    title: const Text('Replace all tags'),
                    subtitle: const Text('Replace all existing tags with selected tags'),
                    value: BulkTagAction.replace,
                    groupValue: _action,
                    onChanged: (value) => setState(() => _action = value!),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tag selection
            Text(
              'Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            // Tag autocomplete
            TagAutocompleteField(
              hintText: 'Search or create tags...',
              excludeTags: _selectedTags.toList(),
              onTagSelected: _addTag,
              onTagCreated: _createAndAddTag,
            ),
            
            const SizedBox(height: 16),
            
            // Selected tags
            if (_selectedTags.isNotEmpty) ...[
              Text(
                'Selected Tags (${_selectedTags.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              
              Container(
                constraints: const BoxConstraints(maxHeight: 120),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedTags.map((tag) {
                      return _buildTagChip(tag);
                    }).toList(),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
            
            // Document preview
            Text(
              'Documents to Update',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: ListView.builder(
                  itemCount: widget.documents.length,
                  itemBuilder: (context, index) {
                    final document = widget.documents[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        _getDocumentIcon(document.extension),
                        color: _getDocumentColor(document.extension),
                      ),
                      title: Text(
                        document.title ?? document.filename ?? 'Unknown Document',
                        style: theme.textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: document.author != null
                          ? Text(
                              document.author!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              children: [
                TextButton(
                  onPressed: _isApplying ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                if (_selectedTags.isNotEmpty)
                  TextButton(
                    onPressed: _isApplying ? null : _clearTags,
                    child: const Text('Clear Tags'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _isApplying || _selectedTags.isEmpty ? null : _applyTags,
                  child: _isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_getActionButtonText()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(Tag tag) {
    final tagColor = _getTagColor(tag.name);
    
    return Chip(
      label: Text(
        tag.name,
        style: TextStyle(
          color: tagColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      avatar: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: tagColor,
          shape: BoxShape.circle,
        ),
      ),
      backgroundColor: tagColor.withValues(alpha: 0.1),
      side: BorderSide(
        color: tagColor.withValues(alpha: 0.3),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: 16,
        color: tagColor,
      ),
      onDeleted: () => _removeTag(tag),
    );
  }

  void _addTag(Tag tag) {
    setState(() {
      _selectedTags.add(tag);
    });
  }

  void _removeTag(Tag tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  void _clearTags() {
    setState(() {
      _selectedTags.clear();
    });
  }

  Future<void> _createAndAddTag(String tagName) async {
    try {
      final newTag = await ref.read(tagProvider.notifier).createTag(tagName);
      _addTag(newTag);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create tag: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _applyTags() async {
    setState(() => _isApplying = true);

    try {
      widget.onApply(_selectedTags.toList(), _action);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getSuccessMessage()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply tags: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isApplying = false);
      }
    }
  }

  String _getActionButtonText() {
    switch (_action) {
      case BulkTagAction.add:
        return 'Add Tags';
      case BulkTagAction.remove:
        return 'Remove Tags';
      case BulkTagAction.replace:
        return 'Replace Tags';
    }
  }

  String _getSuccessMessage() {
    final tagCount = _selectedTags.length;
    final docCount = widget.documents.length;
    
    switch (_action) {
      case BulkTagAction.add:
        return 'Added $tagCount tag${tagCount == 1 ? '' : 's'} to $docCount document${docCount == 1 ? '' : 's'}';
      case BulkTagAction.remove:
        return 'Removed $tagCount tag${tagCount == 1 ? '' : 's'} from $docCount document${docCount == 1 ? '' : 's'}';
      case BulkTagAction.replace:
        return 'Replaced tags for $docCount document${docCount == 1 ? '' : 's'}';
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

/// Actions that can be performed on multiple documents
enum BulkTagAction {
  add,
  remove,
  replace,
}