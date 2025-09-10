import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../providers/tag_provider.dart';

/// Widget for filtering documents by tags
class TagFilterWidget extends ConsumerStatefulWidget {
  final List<Tag> selectedTags;
  final Function(List<Tag> tags) onTagsChanged;
  final bool showClearAll;

  const TagFilterWidget({
    super.key,
    required this.selectedTags,
    required this.onTagsChanged,
    this.showClearAll = true,
  });

  @override
  ConsumerState<TagFilterWidget> createState() => _TagFilterWidgetState();
}

class _TagFilterWidgetState extends ConsumerState<TagFilterWidget> {
  bool _isExpanded = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

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

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ListTile(
            leading: Icon(
              Icons.filter_list,
              color: colorScheme.primary,
            ),
            title: Text(
              'Filter by Tags',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: widget.selectedTags.isNotEmpty
                ? Text(
                    '${widget.selectedTags.length} tag${widget.selectedTags.length == 1 ? '' : 's'} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.selectedTags.isNotEmpty && widget.showClearAll)
                  TextButton(
                    onPressed: _clearAllTags,
                    child: const Text('Clear All'),
                  ),
                IconButton(
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
          ),
          
          // Selected tags (always visible)
          if (widget.selectedTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.selectedTags.map((tag) {
                  return _buildSelectedTagChip(tag);
                }).toList(),
              ),
            ),
          
          // Expanded content
          if (_isExpanded) ...[
            const Divider(height: 1),
            
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search tags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  isDense: true,
                ),
              ),
            ),
            
            // Available tags
            Container(
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildTagList(tagState),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedTagChip(Tag tag) {
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

  Widget _buildTagList(TagState tagState) {
    if (tagState.isLoading && tagState.tags.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (tagState.error != null && tagState.tags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Error loading tags',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                tagState.error!,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final availableTags = _getAvailableTags(tagState.tags);

    if (availableTags.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.label_outline,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                _searchQuery.isNotEmpty ? 'No matching tags' : 'No tags available',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try adjusting your search'
                    : 'Create tags to filter documents',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: availableTags.length,
      itemBuilder: (context, index) {
        final tag = availableTags[index];
        final tagColor = _getTagColor(tag.name);
        
        return CheckboxListTile(
          dense: true,
          value: false, // Not selected (available tags)
          onChanged: (value) => _addTag(tag),
          title: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: tagColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tag.name,
                  style: Theme.of(context).textTheme.bodyMedium,
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: tagColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '0', // Mock usage count
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: tagColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  List<Tag> _getAvailableTags(List<Tag> allTags) {
    final selectedTagIds = widget.selectedTags.map((tag) => tag.id).toSet();
    
    var availableTags = allTags.where((tag) {
      return !selectedTagIds.contains(tag.id);
    }).toList();

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      availableTags = availableTags.where((tag) {
        return tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort alphabetically
    availableTags.sort((a, b) => a.name.compareTo(b.name));

    return availableTags;
  }

  void _addTag(Tag tag) {
    final updatedTags = [...widget.selectedTags, tag];
    widget.onTagsChanged(updatedTags);
  }

  void _removeTag(Tag tag) {
    final updatedTags = widget.selectedTags.where((t) => t.id != tag.id).toList();
    widget.onTagsChanged(updatedTags);
  }

  void _clearAllTags() {
    widget.onTagsChanged([]);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
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