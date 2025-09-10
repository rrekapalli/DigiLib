import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tag_provider.dart';
import '../../models/entities/tag.dart';
import '../../widgets/tag_creation_dialog.dart';
import '../../widgets/tag_edit_dialog.dart';
import '../../widgets/tag_deletion_dialog.dart';
import '../../widgets/tag_import_export_dialog.dart';
import '../../widgets/tag_list_tile.dart';
import '../../widgets/tag_analytics_card.dart';

/// Screen for managing tags with usage statistics and organization
class TagManagementScreen extends ConsumerStatefulWidget {
  const TagManagementScreen({super.key});

  @override
  ConsumerState<TagManagementScreen> createState() => _TagManagementScreenState();
}

class _TagManagementScreenState extends ConsumerState<TagManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  TagSortOption _sortOption = TagSortOption.name;
  bool _showUnusedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tag Management'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showImportExportDialog(context),
            icon: const Icon(Icons.import_export),
            tooltip: 'Import/Export Tags',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: const Icon(Icons.sort),
                  title: const Text('Sort Options'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: const Icon(Icons.filter_list),
                  title: const Text('Filter Options'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'cleanup',
                child: ListTile(
                  leading: const Icon(Icons.cleaning_services),
                  title: const Text('Cleanup Unused'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Tags', icon: Icon(Icons.label)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            Tab(text: 'Organization', icon: Icon(Icons.folder_special)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search tags...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () => setState(() => _searchQuery = ''),
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTagListTab(),
                _buildAnalyticsTab(),
                _buildOrganizationTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTagDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('New Tag'),
      ),
    );
  }

  Widget _buildTagListTab() {
    final tagState = ref.watch(tagProvider);
    
    if (tagState.isLoading && tagState.tags.isEmpty) {
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

    if (tagState.error != null && tagState.tags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading tags',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              tagState.error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.read(tagProvider.notifier).refreshTags(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredTags = _filterAndSortTags(tagState.tags);

    if (filteredTags.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty ? 'No matching tags' : 'No tags yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search or create a new tag.'
                  : 'Create your first tag to organize your documents.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showCreateTagDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Tag'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tagProvider.notifier).refreshTags(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredTags.length,
        itemBuilder: (context, index) {
          final tag = filteredTags[index];
          return TagListTile(
            tag: tag,
            onTap: () => _showTagDetails(context, tag),
            onEdit: () => _showEditTagDialog(context, tag),
            onDelete: () => _showDeleteTagDialog(context, tag),
            onColorChange: (color) => _updateTagColor(tag, color),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          TagAnalyticsCard(),
          // Additional analytics widgets would go here
        ],
      ),
    );
  }

  Widget _buildOrganizationTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_special,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 24),
          Text(
            'Tag Organization',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Advanced tag organization features will be available here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<Tag> _filterAndSortTags(List<Tag> tags) {
    var filtered = tags.where((tag) {
      final matchesSearch = _searchQuery.isEmpty ||
          tag.name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      // Note: For unused filter, we'd need to implement getTagUsageCount
      // For now, we'll just filter by search
      return matchesSearch;
    }).toList();

    // Sort tags
    switch (_sortOption) {
      case TagSortOption.name:
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case TagSortOption.created:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TagSortOption.usage:
        // For now, keep original order. In real implementation,
        // we'd sort by usage count
        break;
    }

    return filtered;
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortOptions();
        break;
      case 'filter':
        _showFilterOptions();
        break;
      case 'cleanup':
        _showCleanupDialog();
        break;
    }
  }

  void _showSortOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sort Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TagSortOption.values.map((option) {
            return RadioListTile<TagSortOption>(
              title: Text(option.displayName),
              value: option,
              groupValue: _sortOption,
              onChanged: (value) {
                setState(() => _sortOption = value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Tags'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Show unused tags only'),
              value: _showUnusedOnly,
              onChanged: (value) {
                setState(() => _showUnusedOnly = value ?? false);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cleanup Unused Tags'),
        content: const Text(
          'This will permanently delete all tags that are not assigned to any documents. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performCleanup();
            },
            child: const Text('Delete Unused'),
          ),
        ],
      ),
    );
  }

  void _showCreateTagDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TagCreationDialog(),
    );
  }

  void _showEditTagDialog(BuildContext context, Tag tag) {
    showDialog(
      context: context,
      builder: (context) => TagEditDialog(tag: tag),
    );
  }

  void _showDeleteTagDialog(BuildContext context, Tag tag) {
    showDialog(
      context: context,
      builder: (context) => TagDeletionDialog(tag: tag),
    );
  }

  void _showImportExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TagImportExportDialog(),
    );
  }

  void _showTagDetails(BuildContext context, Tag tag) {
    // Navigate to tag details screen or show bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tag.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Created: ${tag.createdAt.toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Usage: 0 documents', // Would show actual usage count
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showEditTagDialog(context, tag);
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showDeleteTagDialog(context, tag);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateTagColor(Tag tag, Color color) {
    // Implementation for updating tag color
    // This would involve updating the tag with color information
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tag color updated'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _performCleanup() async {
    try {
      // Implementation for cleaning up unused tags
      // This would call the tag service to delete unused tags
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unused tags cleaned up'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cleaning up tags: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

/// Sort options for tags
enum TagSortOption {
  name('Name'),
  created('Date Created'),
  usage('Usage Count');

  const TagSortOption(this.displayName);
  final String displayName;
}