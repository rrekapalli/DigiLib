import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/saved_search.dart';
import '../../services/saved_search_service.dart';
import '../../services/search_service.dart';
import '../../widgets/saved_search_tile.dart';
import '../../widgets/save_search_dialog.dart';
import '../../utils/constants.dart';
import '../../database/database_helper.dart';

/// Screen for managing saved searches
class SavedSearchesScreen extends ConsumerStatefulWidget {
  const SavedSearchesScreen({super.key});

  @override
  ConsumerState<SavedSearchesScreen> createState() => _SavedSearchesScreenState();
}

class _SavedSearchesScreenState extends ConsumerState<SavedSearchesScreen> {
  List<SavedSearch> _savedSearches = [];
  List<SearchAnalytics> _searchAnalytics = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final savedSearchService = SavedSearchService(
        ref.read(databaseHelperProvider),
      );

      final searches = await savedSearchService.getSavedSearches();
      final analytics = await savedSearchService.getSearchAnalytics();

      if (mounted) {
        setState(() {
          _savedSearches = searches;
          _searchAnalytics = analytics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load saved searches: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _executeSavedSearch(SavedSearch savedSearch) async {
    try {
      final savedSearchService = SavedSearchService(
        ref.read(databaseHelperProvider),
      );

      // Update usage statistics
      await savedSearchService.useSavedSearch(savedSearch.id);

      // Navigate back to search screen with the saved search
      if (mounted) {
        Navigator.of(context).pop({
          'query': savedSearch.query,
          'filters': savedSearch.filters != null 
              ? SearchFilters(
                  libraryId: savedSearch.filters!['library_id'],
                  tags: savedSearch.filters!['tags']?.cast<String>(),
                  fileTypes: savedSearch.filters!['file_types']?.cast<String>(),
                  authors: savedSearch.filters!['authors']?.cast<String>(),
                  dateFrom: savedSearch.filters!['date_from'] != null 
                      ? DateTime.parse(savedSearch.filters!['date_from']) 
                      : null,
                  dateTo: savedSearch.filters!['date_to'] != null 
                      ? DateTime.parse(savedSearch.filters!['date_to']) 
                      : null,
                )
              : null,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to execute search: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteSavedSearch(SavedSearch savedSearch) async {
    final confirmed = await _showDeleteConfirmation(savedSearch.name);
    if (!confirmed) return;

    try {
      final savedSearchService = SavedSearchService(
        ref.read(databaseHelperProvider),
      );

      await savedSearchService.deleteSavedSearch(savedSearch.id);
      await _loadData(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete search: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _editSavedSearch(SavedSearch savedSearch) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => SaveSearchDialog(
        initialName: savedSearch.name,
        query: savedSearch.query,
        filters: savedSearch.filters != null 
            ? SearchFilters(
                libraryId: savedSearch.filters!['library_id'],
                tags: savedSearch.filters!['tags']?.cast<String>(),
                fileTypes: savedSearch.filters!['file_types']?.cast<String>(),
                authors: savedSearch.filters!['authors']?.cast<String>(),
                dateFrom: savedSearch.filters!['date_from'] != null 
                    ? DateTime.parse(savedSearch.filters!['date_from']) 
                    : null,
                dateTo: savedSearch.filters!['date_to'] != null 
                    ? DateTime.parse(savedSearch.filters!['date_to']) 
                    : null,
              )
            : null,
        isEditing: true,
      ),
    );

    if (result != null) {
      try {
        final savedSearchService = SavedSearchService(
          ref.read(databaseHelperProvider),
        );

        final updatedSearch = savedSearch.copyWith(
          name: result['name'] as String,
        );

        await savedSearchService.updateSavedSearch(updatedSearch);
        await _loadData(); // Refresh the list
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update search: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<bool> _showDeleteConfirmation(String searchName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Saved Search'),
        content: Text('Are you sure you want to delete "$searchName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Searches'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showAnalytics(),
            tooltip: 'Search Analytics',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_savedSearches.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: _savedSearches.length,
        itemBuilder: (context, index) {
          final savedSearch = _savedSearches[index];
          return SavedSearchTile(
            savedSearch: savedSearch,
            onTap: () => _executeSavedSearch(savedSearch),
            onEdit: () => _editSavedSearch(savedSearch),
            onDelete: () => _deleteSavedSearch(savedSearch),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
              'Error Loading Searches',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Saved Searches',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Save your frequent searches for quick access',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnalytics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildAnalyticsSheet(scrollController),
      ),
    );
  }

  Widget _buildAnalyticsSheet(ScrollController scrollController) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.defaultBorderRadius),
          topRight: Radius.circular(AppConstants.defaultBorderRadius),
        ),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Row(
              children: [
                Text(
                  'Search Analytics',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Analytics content
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.defaultPadding,
              ),
              itemCount: _searchAnalytics.length,
              itemBuilder: (context, index) {
                final analytics = _searchAnalytics[index];
                return _buildAnalyticsTile(analytics);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTile(SearchAnalytics analytics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              analytics.query,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAnalyticsChip(
                  'Searches: ${analytics.searchCount}',
                  colorScheme.primaryContainer,
                  colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                _buildAnalyticsChip(
                  'Avg Results: ${analytics.avgResultCount.toStringAsFixed(1)}',
                  colorScheme.secondaryContainer,
                  colorScheme.onSecondaryContainer,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Last searched: ${_formatDate(analytics.lastSearched)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsChip(String text, Color backgroundColor, Color textColor) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}

// Add missing provider
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});