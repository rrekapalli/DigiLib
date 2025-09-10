import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/reader_provider.dart';

/// Find in document widget for searching text within the current document
class FindInDocument extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback? onClose;
  final Function(String query, List<SearchMatch> matches)? onSearchResults;

  const FindInDocument({
    super.key,
    required this.documentId,
    this.onClose,
    this.onSearchResults,
  });

  @override
  ConsumerState<FindInDocument> createState() => _FindInDocumentState();
}

class _FindInDocumentState extends ConsumerState<FindInDocument> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  List<SearchMatch> _matches = [];
  int _currentMatchIndex = -1;
  bool _isSearching = false;
  bool _caseSensitive = false;
  bool _wholeWords = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _matches.clear();
        _currentMatchIndex = -1;
      });
      return;
    }

    if (query.length >= 2) {
      _performSearch(query);
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      // TODO: Implement actual document text search
      // This would typically involve:
      // 1. Getting text content for all pages
      // 2. Searching through the text with the given options
      // 3. Creating SearchMatch objects with page numbers and positions

      // Mock search results for now
      await Future.delayed(const Duration(milliseconds: 300));

      final matches = _mockSearch(query);

      setState(() {
        _matches = matches;
        _currentMatchIndex = matches.isNotEmpty ? 0 : -1;
        _isSearching = false;
      });

      widget.onSearchResults?.call(query, matches);

      // Navigate to first match
      if (matches.isNotEmpty) {
        _goToMatch(0);
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
        _matches.clear();
        _currentMatchIndex = -1;
      });
    }
  }

  List<SearchMatch> _mockSearch(String query) {
    // Mock implementation - replace with actual search
    final mockMatches = <SearchMatch>[];

    // Simulate finding matches across different pages
    for (int page = 1; page <= 5; page++) {
      for (int i = 0; i < (page % 3 + 1); i++) {
        mockMatches.add(
          SearchMatch(
            pageNumber: page,
            text: query,
            context:
                'This is some context text containing $query in the document.',
            startOffset: 40 + i * 10,
            endOffset: 40 + i * 10 + query.length,
            boundingRect: Rect.fromLTWH(
              50 + i * 20,
              100 + i * 25,
              query.length * 8.0,
              20,
            ),
          ),
        );
      }
    }

    return mockMatches;
  }

  void _goToMatch(int index) {
    if (index < 0 || index >= _matches.length) return;

    final match = _matches[index];
    setState(() {
      _currentMatchIndex = index;
    });

    // Navigate to the page containing the match
    ref
        .read(readerStateProvider(widget.documentId).notifier)
        .goToPage(match.pageNumber);
  }

  void _nextMatch() {
    if (_matches.isEmpty) return;
    final nextIndex = (_currentMatchIndex + 1) % _matches.length;
    _goToMatch(nextIndex);
  }

  void _previousMatch() {
    if (_matches.isEmpty) return;
    final prevIndex = _currentMatchIndex <= 0
        ? _matches.length - 1
        : _currentMatchIndex - 1;
    _goToMatch(prevIndex);
  }

  void _toggleCaseSensitive() {
    setState(() {
      _caseSensitive = !_caseSensitive;
    });

    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  void _toggleWholeWords() {
    setState(() {
      _wholeWords = !_wholeWords;
    });

    if (_searchController.text.isNotEmpty) {
      _performSearch(_searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input row
          Row(
            children: [
              // Search field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  decoration: InputDecoration(
                    hintText: 'Find in document...',
                    prefixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _nextMatch(),
                ),
              ),

              const SizedBox(width: 8),

              // Navigation buttons
              IconButton(
                onPressed: _matches.isEmpty ? null : _previousMatch,
                icon: const Icon(Icons.keyboard_arrow_up),
                tooltip: 'Previous match',
              ),
              IconButton(
                onPressed: _matches.isEmpty ? null : _nextMatch,
                icon: const Icon(Icons.keyboard_arrow_down),
                tooltip: 'Next match',
              ),

              // Close button
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
                tooltip: 'Close search',
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Search options and results
          Row(
            children: [
              // Search options
              Expanded(
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Aa'),
                      selected: _caseSensitive,
                      onSelected: (_) => _toggleCaseSensitive(),
                      tooltip: 'Case sensitive',
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('\\b'),
                      selected: _wholeWords,
                      onSelected: (_) => _toggleWholeWords(),
                      tooltip: 'Whole words',
                    ),
                  ],
                ),
              ),

              // Results counter
              if (_matches.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentMatchIndex + 1} of ${_matches.length}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                )
              else if (_searchController.text.isNotEmpty && !_isSearching)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'No matches',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact find widget for overlay use
class CompactFindWidget extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback? onClose;

  const CompactFindWidget({super.key, required this.documentId, this.onClose});

  @override
  ConsumerState<CompactFindWidget> createState() => _CompactFindWidgetState();
}

class _CompactFindWidgetState extends ConsumerState<CompactFindWidget> {
  final TextEditingController _searchController = TextEditingController();
  final int _matchCount = 0;
  final int _currentMatch = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 200,
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Find...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (_matchCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$_currentMatch/$_matchCount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_up),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }
}

/// Search match model
class SearchMatch {
  final int pageNumber;
  final String text;
  final String context;
  final int startOffset;
  final int endOffset;
  final Rect boundingRect;

  const SearchMatch({
    required this.pageNumber,
    required this.text,
    required this.context,
    required this.startOffset,
    required this.endOffset,
    required this.boundingRect,
  });

  /// Get highlighted context with the match emphasized
  String get highlightedContext {
    final beforeMatch = context.substring(0, startOffset);
    final afterMatch = context.substring(endOffset);
    return '$beforeMatch**$text**$afterMatch';
  }

  @override
  String toString() {
    return 'SearchMatch(page: $pageNumber, text: "$text", context: "$context")';
  }
}

/// Search highlight overlay for marking matches on pages
class SearchHighlightOverlay extends StatelessWidget {
  final List<SearchMatch> matches;
  final int currentPageNumber;
  final int? selectedMatchIndex;

  const SearchHighlightOverlay({
    super.key,
    required this.matches,
    required this.currentPageNumber,
    this.selectedMatchIndex,
  });

  @override
  Widget build(BuildContext context) {
    final pageMatches = matches
        .where((match) => match.pageNumber == currentPageNumber)
        .toList();

    if (pageMatches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: pageMatches.asMap().entries.map((entry) {
        final match = entry.value;
        final isSelected =
            selectedMatchIndex != null &&
            matches.indexOf(match) == selectedMatchIndex;

        return Positioned(
          left: match.boundingRect.left,
          top: match.boundingRect.top,
          width: match.boundingRect.width,
          height: match.boundingRect.height,
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.orange.withValues(alpha: 0.6)
                  : Colors.yellow.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }
}
