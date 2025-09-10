import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/api/search_response.dart';
import '../../services/search_service.dart';
import '../../providers/search_provider.dart';
import '../../widgets/search_input_field.dart';
import '../../widgets/search_filters_panel.dart';
import '../../widgets/search_results_list.dart';
import '../../widgets/search_suggestions_list.dart';
import '../../widgets/search_history_list.dart';
import '../../widgets/save_search_dialog.dart';
import '../../services/saved_search_service.dart';
import '../../database/database_helper.dart';
import '../../utils/constants.dart';
import 'saved_searches_screen.dart';

/// Main search screen with input, filters, and results
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _currentQuery = '';
  SearchFilters? _currentFilters;
  bool _showFilters = false;
  bool _showSuggestions = false;
  bool _isSearching = false;

  UnifiedSearchResults? _searchResults;
  List<String> _searchSuggestions = [];
  List<String> _searchHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_searchFocusNode.hasFocus && _searchController.text.isEmpty) {
      setState(() {
        _showSuggestions = true;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final searchService = ref.read(searchServiceProvider);
      final history = await searchService.getSearchHistory();
      if (mounted) {
        setState(() {
          _searchHistory = history;
        });
      }
    } catch (e) {
      // Handle error silently for history loading
    }
  }

  Future<void> _onSearchChanged(String query) async {
    setState(() {
      _currentQuery = query;
    });

    if (query.trim().isEmpty) {
      setState(() {
        _showSuggestions = true;
        _searchResults = null;
        _searchSuggestions = [];
      });
      return;
    }

    // Get suggestions for partial queries
    if (query.length >= 2) {
      try {
        final searchService = ref.read(searchServiceProvider);
        final suggestions = await searchService.getSearchSuggestions(query);
        if (mounted && _currentQuery == query) {
          setState(() {
            _searchSuggestions = suggestions;
            _showSuggestions = true;
          });
        }
      } catch (e) {
        // Handle error silently for suggestions
      }
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showSuggestions = false;
      _errorMessage = null;
    });

    try {
      final searchService = ref.read(searchServiceProvider);

      // Save to history
      await searchService.saveSearchToHistory(query);

      // Perform search
      final results = await searchService.search(
        query,
        filters: _currentFilters,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });

        // Update history
        _loadSearchHistory();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _errorMessage = 'Search failed: ${e.toString()}';
        });
      }
    }
  }

  void _onSuggestionSelected(String suggestion) {
    _searchController.text = suggestion;
    _performSearch(suggestion);
  }

  void _onHistorySelected(String query) {
    _searchController.text = query;
    _performSearch(query);
  }

  void _onFiltersChanged(SearchFilters? filters) {
    setState(() {
      _currentFilters = filters;
    });

    // Re-search if we have a current query
    if (_currentQuery.isNotEmpty) {
      _performSearch(_currentQuery);
    }
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _currentQuery = '';
      _searchResults = null;
      _showSuggestions = true;
      _errorMessage = null;
    });
    _searchFocusNode.requestFocus();
  }

  Future<void> _clearHistory() async {
    try {
      final searchService = ref.read(searchServiceProvider);
      await searchService.clearSearchHistory();
      setState(() {
        _searchHistory = [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear history: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _navigateToSavedSearches,
            tooltip: 'Saved Searches',
          ),
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
            ),
            onPressed: _toggleFilters,
            tooltip: 'Filters',
          ),
          if (_searchResults != null && _searchResults!.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'save',
                  child: ListTile(
                    leading: Icon(Icons.bookmark_add),
                    title: Text('Save Search'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.download),
                    title: Text('Export Results'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share Results'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Search input section
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
              ),
            ),
            child: SearchInputField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onSearchChanged,
              onSubmitted: _performSearch,
              onClear: _clearSearch,
              isLoading: _isSearching,
            ),
          ),

          // Filters panel
          if (_showFilters)
            SearchFiltersPanel(
              filters: _currentFilters,
              onFiltersChanged: _onFiltersChanged,
            ),

          // Content area
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // Show error if present
    if (_errorMessage != null) {
      return _buildErrorState();
    }

    // Show search results if available
    if (_searchResults != null) {
      return SearchResultsList(
        results: _searchResults!,
        onResultTap: _onResultTap,
        onLoadMore: _onLoadMore,
      );
    }

    // Show suggestions or history when focused and no results
    if (_showSuggestions) {
      return _buildSuggestionsAndHistory();
    }

    // Show empty state
    return _buildEmptyState();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
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
              'Search Error',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _performSearch(_currentQuery),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsAndHistory() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          if (_searchSuggestions.isNotEmpty) ...[
            SearchSuggestionsList(
              suggestions: _searchSuggestions,
              query: _currentQuery,
              onSuggestionTap: _onSuggestionSelected,
            ),
            const Divider(),
          ],

          // Search history
          if (_searchHistory.isNotEmpty)
            SearchHistoryList(
              history: _searchHistory,
              onHistoryTap: _onHistorySelected,
              onClearHistory: _clearHistory,
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Search Your Library',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Find documents by title, author, content, or tags',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onResultTap(SearchResult result) {
    // Navigate to document reader
    Navigator.of(context).pushNamed(
      '/reader',
      arguments: {
        'documentId': result.document.id,
        'searchQuery': _currentQuery,
        'highlights': result.highlights,
      },
    );
  }

  void _navigateToSavedSearches() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (context) => const SavedSearchesScreen()),
    );

    if (result != null) {
      // Load the saved search
      final query = result['query'] as String;
      final filters = result['filters'] as SearchFilters?;

      _searchController.text = query;
      setState(() {
        _currentFilters = filters;
      });

      _performSearch(query);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'save':
        _saveCurrentSearch();
        break;
      case 'export':
        _exportResults();
        break;
      case 'share':
        _shareResults();
        break;
    }
  }

  Future<void> _saveCurrentSearch() async {
    if (_searchResults == null || _currentQuery.isEmpty) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) =>
          SaveSearchDialog(query: _currentQuery, filters: _currentFilters),
    );

    if (result != null) {
      try {
        final savedSearchService = SavedSearchService(DatabaseHelper.instance);

        await savedSearchService.saveSearch(
          name: result['name'] as String,
          query: result['query'] as String,
          filters: result['filters'] as SearchFilters?,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search saved successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save search: ${e.toString()}')),
          );
        }
      }
    }
  }

  Future<void> _exportResults() async {
    if (_searchResults == null || _searchResults!.results.isEmpty) return;

    final format = await _showExportFormatDialog();
    if (format == null) return;

    try {
      final savedSearchService = SavedSearchService(DatabaseHelper.instance);

      await savedSearchService.exportSearchResults(
        results: _searchResults!.results,
        format: format,
        query: _currentQuery,
      );

      // In a real app, you would save this to a file or share it
      // For now, just show a success message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Results exported as $format')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<String?> _showExportFormatDialog() async {
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV'),
              subtitle: const Text('Comma-separated values'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('JSON'),
              subtitle: const Text('JavaScript Object Notation'),
              onTap: () => Navigator.of(context).pop('json'),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('Text'),
              subtitle: const Text('Plain text format'),
              onTap: () => Navigator.of(context).pop('txt'),
            ),
          ],
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

  Future<void> _shareResults() async {
    if (_searchResults == null || _searchResults!.results.isEmpty) return;

    try {
      final savedSearchService = SavedSearchService(DatabaseHelper.instance);

      final shareData = await savedSearchService.shareSearchResults(
        results: _searchResults!.results,
        query: _currentQuery,
        filters: _currentFilters,
      );

      // In a real app, you would use the share plugin to share this data
      // For now, just show the share data in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share Results'),
            content: SingleChildScrollView(
              child: Text(
                'Query: ${shareData['query']}\n'
                'Results: ${shareData['results_count']}\n'
                'Exported: ${shareData['exported_at']}',
              ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Share failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _onLoadMore() async {
    if (_searchResults == null || _isSearching) return;

    final currentPage = _searchResults!.pagination.page;
    final totalPages = _searchResults!.pagination.totalPages;

    if (currentPage >= totalPages) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final searchService = ref.read(searchServiceProvider);
      final moreResults = await searchService.search(
        _currentQuery,
        filters: _currentFilters,
        page: currentPage + 1,
      );

      if (mounted) {
        setState(() {
          _searchResults = UnifiedSearchResults(
            query: _searchResults!.query,
            results: [..._searchResults!.results, ...moreResults.results],
            source: moreResults.source,
            pagination: moreResults.pagination,
            filters: _searchResults!.filters,
            hasLocalFallback: moreResults.hasLocalFallback,
            error: moreResults.error,
          );
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more results: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
