import 'package:flutter/material.dart';
import '../models/api/search_response.dart';
import '../services/search_service.dart';
import '../utils/constants.dart';
import '../widgets/search_result_tile.dart';

/// List widget for displaying search results with pagination
class SearchResultsList extends StatefulWidget {
  final UnifiedSearchResults results;
  final ValueChanged<SearchResult> onResultTap;
  final VoidCallback? onLoadMore;

  const SearchResultsList({
    super.key,
    required this.results,
    required this.onResultTap,
    this.onLoadMore,
  });

  @override
  State<SearchResultsList> createState() => _SearchResultsListState();
}

class _SearchResultsListState extends State<SearchResultsList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || widget.onLoadMore == null) return;

    final pagination = widget.results.pagination;
    if (pagination.page >= pagination.totalPages) return;

    setState(() {
      _isLoadingMore = true;
    });

    widget.onLoadMore!();

    // Reset loading state after a delay to prevent rapid calls
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.results.isEmpty) {
      return _buildEmptyResults();
    }

    return Column(
      children: [
        // Results header
        _buildResultsHeader(),

        // Results list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: widget.results.length + (_hasMoreResults() ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < widget.results.length) {
                return SearchResultTile(
                  result: widget.results.results[index],
                  query: widget.results.query,
                  onTap: () =>
                      widget.onResultTap(widget.results.results[index]),
                );
              } else {
                return _buildLoadMoreIndicator();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pagination = widget.results.pagination;

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${pagination.total} results for "${widget.results.query}"',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildSourceIndicator(),
            ],
          ),

          if (widget.results.hasLocalFallback || widget.results.hadError) ...[
            const SizedBox(height: 8),
            _buildStatusIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isGlobal = widget.results.isFromGlobalSearch;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGlobal
            ? colorScheme.primaryContainer
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGlobal ? Icons.cloud : Icons.storage,
            size: 16,
            color: isGlobal
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isGlobal ? 'Global' : 'Local',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isGlobal
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (widget.results.hasLocalFallback) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.warningContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber,
              size: 16,
              color: colorScheme.onWarningContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Using local search due to network issues',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onWarningContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (widget.results.hadError) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search completed with errors',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmptyResults() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text('No Results Found', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filters',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (widget.results.filters != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  // This would need to be handled by the parent widget
                  // For now, just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Clear filters to see more results'),
                    ),
                  );
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(AppConstants.defaultPadding),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return const SizedBox(height: AppConstants.defaultPadding);
  }

  bool _hasMoreResults() {
    final pagination = widget.results.pagination;
    return pagination.page < pagination.totalPages;
  }
}

// Extension to add warning container colors if not available
extension ColorSchemeExtension on ColorScheme {
  Color get warningContainer => brightness == Brightness.light
      ? const Color(0xFFFFF8E1)
      : const Color(0xFF3E2723);

  Color get onWarningContainer => brightness == Brightness.light
      ? const Color(0xFF8A6914)
      : const Color(0xFFFFCC02);
}
