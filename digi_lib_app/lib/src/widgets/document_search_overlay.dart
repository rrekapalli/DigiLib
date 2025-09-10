import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/api/search_response.dart';
import '../services/search_service.dart';
import '../providers/search_provider.dart';
import '../utils/constants.dart';

/// Overlay for searching within a document
class DocumentSearchOverlay extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback onClose;
  final ValueChanged<SearchHighlight>? onHighlightTap;

  const DocumentSearchOverlay({
    super.key,
    required this.documentId,
    required this.onClose,
    this.onHighlightTap,
  });

  @override
  ConsumerState<DocumentSearchOverlay> createState() =>
      _DocumentSearchOverlayState();
}

class _DocumentSearchOverlayState extends ConsumerState<DocumentSearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  DocumentSearchResults? _searchResults;
  bool _isSearching = false;
  String _currentQuery = '';
  int _currentHighlightIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _currentQuery = '';
        _currentHighlightIndex = 0;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _currentQuery = query;
    });

    try {
      final searchService = ref.read(searchServiceProvider);
      final results = await searchService.searchInDocument(
        widget.documentId,
        query,
      );

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _currentHighlightIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: ${e.toString()}')),
        );
      }
    }
  }

  void _navigateToHighlight(int index) {
    if (_searchResults == null || _searchResults!.highlights.isEmpty) return;

    final clampedIndex = index.clamp(0, _searchResults!.highlights.length - 1);
    setState(() {
      _currentHighlightIndex = clampedIndex;
    });

    final highlight = _searchResults!.highlights[clampedIndex];
    widget.onHighlightTap?.call(highlight);
  }

  void _previousHighlight() {
    if (_searchResults == null || _searchResults!.highlights.isEmpty) return;
    _navigateToHighlight(_currentHighlightIndex - 1);
  }

  void _nextHighlight() {
    if (_searchResults == null || _searchResults!.highlights.isEmpty) return;
    _navigateToHighlight(_currentHighlightIndex + 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with search input
            Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                  topRight: Radius.circular(AppConstants.defaultBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _performSearch,
                      onSubmitted: _performSearch,
                      decoration: InputDecoration(
                        hintText: 'Search in document...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                    tooltip: 'Close search',
                  ),
                ],
              ),
            ),

            // Search results and navigation
            if (_searchResults != null) ...[
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    // Results summary and navigation
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _searchResults!.highlights.isEmpty
                                ? 'No matches found'
                                : '${_currentHighlightIndex + 1} of ${_searchResults!.highlights.length}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (_searchResults!.highlights.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_up),
                            onPressed: _currentHighlightIndex > 0
                                ? _previousHighlight
                                : null,
                            tooltip: 'Previous match',
                          ),
                          IconButton(
                            icon: const Icon(Icons.keyboard_arrow_down),
                            onPressed:
                                _currentHighlightIndex <
                                    _searchResults!.highlights.length - 1
                                ? _nextHighlight
                                : null,
                            tooltip: 'Next match',
                          ),
                        ],
                      ],
                    ),

                    // Current highlight details
                    if (_searchResults!.highlights.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _buildCurrentHighlight(),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentHighlight() {
    if (_searchResults == null || _searchResults!.highlights.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final highlight = _searchResults!.highlights[_currentHighlightIndex];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Page ${highlight.pageNumber}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => widget.onHighlightTap?.call(highlight),
                child: const Text('Go to page'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHighlightedText(highlight.context, _currentQuery),
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (query.isEmpty) {
      return Text(
        text,
        style: theme.textTheme.bodySmall,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int index = lowerText.indexOf(lowerQuery);

    while (index != -1) {
      // Add text before match
      if (index > start) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: theme.textTheme.bodySmall,
          ),
        );
      }

      // Add highlighted match
      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: theme.textTheme.bodySmall?.copyWith(
            backgroundColor: colorScheme.primary,
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    // Add remaining text
    if (start < text.length) {
      spans.add(
        TextSpan(text: text.substring(start), style: theme.textTheme.bodySmall),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
