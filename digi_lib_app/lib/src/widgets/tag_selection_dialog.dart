import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../models/entities/document.dart';
import '../providers/tag_provider.dart';
import '../widgets/tag_creation_dialog.dart';

/// Dialog for selecting tags for a document
class TagSelectionDialog extends ConsumerStatefulWidget {
  final Document document;
  final List<Tag> currentTags;
  final Function(List<Tag> selectedTags) onTagsSelected;

  const TagSelectionDialog({
    super.key,
    required this.document,
    required this.currentTags,
    required this.onTagsSelected,
  });

  @override
  ConsumerState<TagSelectionDialog> createState() => _TagSelectionDialogState();
}

class _TagSelectionDialogState extends ConsumerState<TagSelectionDialog> {
  final _searchController = TextEditingController();
  final Set<String> _selectedTagIds = <String>{};
  String _searchQuery = '';
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    // Initialize with current tags
    _selectedTagIds.addAll(widget.currentTags.map((tag) => tag.id));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tagState = ref.watch(tagProvider);

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
                        'Select Tags',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.document.title ?? widget.document.filename ?? 'Unknown Document',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
            
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      onPressed: () => _showCreateTagDialog(),
                      icon: const Icon(Icons.add),
                      tooltip: 'Create new tag',
                    ),
                  ],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Selected tags count
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedTagIds.length} tag${_selectedTagIds.length == 1 ? '' : 's'} selected',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tag list
            Expanded(
              child: _buildTagList(tagState),
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
                TextButton(
                  onPressed: _isApplying ? null : _clearSelection,
                  child: const Text('Clear All'),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isApplying ? null : _applyTags,
                  child: _isApplying
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagList(TagState tagState) {
    if (tagState.isLoading && tagState.tags.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (tagState.error != null && tagState.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tags',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              tagState.error!,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => ref.read(tagProvider.notifier).refreshTags(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTags = _filterTags(tagState.tags);

    if (filteredTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No matching tags' : 'No tags available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or create a new tag.'
                  : 'Create your first tag to get started.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showCreateTagDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Create Tag'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredTags.length,
      itemBuilder: (context, index) {
        final tag = filteredTags[index];
        final isSelected = _selectedTagIds.contains(tag.id);
        final tagColor = _getTagColor(tag.name);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) => _toggleTag(tag.id, value ?? false),
            title: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: tagColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tag.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Created ${_formatDate(tag.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: tagColor.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '0', // Mock usage count
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<Tag> _filterTags(List<Tag> tags) {
    if (_searchQuery.isEmpty) {
      return tags;
    }
    
    return tags.where((tag) {
      return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleTag(String tagId, bool selected) {
    setState(() {
      if (selected) {
        _selectedTagIds.add(tagId);
      } else {
        _selectedTagIds.remove(tagId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTagIds.clear();
    });
  }

  void _showCreateTagDialog() {
    showDialog(
      context: context,
      builder: (context) => const TagCreationDialog(),
    ).then((_) {
      // Refresh tags after creation
      ref.read(tagProvider.notifier).refreshTags();
    });
  }

  Future<void> _applyTags() async {
    setState(() => _isApplying = true);

    try {
      final tagState = ref.read(tagProvider);
      final selectedTags = tagState.tags
          .where((tag) => _selectedTagIds.contains(tag.id))
          .toList();

      widget.onTagsSelected(selectedTags);
      
      if (mounted) {
        Navigator.of(context).pop();
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
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