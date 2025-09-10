import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/bookmark.dart';
import '../../models/entities/document.dart';
import '../../providers/bookmark_provider.dart';
import '../../providers/reader_provider.dart';
import '../../widgets/bookmark_list_tile.dart';
import '../../widgets/bookmark_creation_dialog.dart';
import '../../widgets/bookmark_edit_dialog.dart';

/// Screen for managing bookmarks of a document
class BookmarkListScreen extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback? onBookmarkSelected;

  const BookmarkListScreen({
    super.key,
    required this.documentId,
    this.onBookmarkSelected,
  });

  @override
  ConsumerState<BookmarkListScreen> createState() => _BookmarkListScreenState();
}

class _BookmarkListScreenState extends ConsumerState<BookmarkListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => BookmarkCreationDialog(
        documentId: widget.documentId,
        onBookmarkCreated: () {
          // Refresh bookmarks list
          ref.invalidate(documentBookmarksProvider(widget.documentId));
        },
      ),
    );
  }

  void _showEditBookmarkDialog(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => BookmarkEditDialog(
        bookmark: bookmark,
        onBookmarkUpdated: () {
          // Refresh bookmarks list
          ref.invalidate(documentBookmarksProvider(widget.documentId));
        },
      ),
    );
  }

  void _deleteBookmark(Bookmark bookmark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bookmark'),
        content: Text(
          'Are you sure you want to delete the bookmark on page ${bookmark.pageNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(context).pop();
              await ref
                  .read(bookmarkNotifierProvider.notifier)
                  .deleteBookmark(bookmark.id, widget.documentId);

              if (mounted) {
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Bookmark deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToBookmark(Bookmark bookmark) {
    if (bookmark.pageNumber != null) {
      // Navigate to the bookmark page in the reader
      ref
          .read(readerStateProvider(widget.documentId).notifier)
          .goToPage(bookmark.pageNumber!);

      // Close the bookmark screen
      Navigator.of(context).pop();

      // Call callback if provided
      widget.onBookmarkSelected?.call();
    }
  }

  List<Bookmark> _filterBookmarks(List<Bookmark> bookmarks) {
    if (_searchQuery.isEmpty) return bookmarks;

    return bookmarks.where((bookmark) {
      final pageMatch =
          bookmark.pageNumber?.toString().contains(_searchQuery) ?? false;
      final noteMatch =
          bookmark.note?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
          false;
      return pageMatch || noteMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(currentDocumentProvider(widget.documentId));
    final bookmarksAsync = ref.watch(
      documentBookmarksProvider(widget.documentId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search bookmarks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: document.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorView(error),
        data: (doc) => _buildBookmarksList(doc, bookmarksAsync),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateBookmarkDialog,
        tooltip: 'Add Bookmark',
        child: const Icon(Icons.bookmark_add),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load document',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList(
    Document document,
    AsyncValue<List<Bookmark>> bookmarksAsync,
  ) {
    return bookmarksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildBookmarksErrorView(error),
      data: (bookmarks) {
        final filteredBookmarks = _filterBookmarks(bookmarks);

        if (filteredBookmarks.isEmpty) {
          return _buildEmptyView();
        }

        return Column(
          children: [
            // Document info header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title ?? document.filename ?? 'Unknown Document',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredBookmarks.length} bookmark${filteredBookmarks.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Bookmarks list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredBookmarks.length,
                itemBuilder: (context, index) {
                  final bookmark = filteredBookmarks[index];
                  return BookmarkListTile(
                    bookmark: bookmark,
                    onTap: () => _navigateToBookmark(bookmark),
                    onEdit: () => _showEditBookmarkDialog(bookmark),
                    onDelete: () => _deleteBookmark(bookmark),
                    showSyncStatus: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBookmarksErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Failed to load bookmarks',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(documentBookmarksProvider(widget.documentId));
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No bookmarks found' : 'No bookmarks yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search terms'
                : 'Add bookmarks to save your favorite pages',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateBookmarkDialog,
              icon: const Icon(Icons.bookmark_add),
              label: const Text('Add Bookmark'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact bookmark list widget for embedding in other screens
class CompactBookmarkList extends ConsumerWidget {
  final String documentId;
  final int maxItems;
  final VoidCallback? onViewAll;
  final Function(Bookmark)? onBookmarkTap;

  const CompactBookmarkList({
    super.key,
    required this.documentId,
    this.maxItems = 5,
    this.onViewAll,
    this.onBookmarkTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(documentBookmarksProvider(documentId));

    return bookmarksAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load bookmarks',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No bookmarks',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final displayBookmarks = bookmarks.take(maxItems).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Bookmarks (${bookmarks.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (bookmarks.length > maxItems && onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('View All'),
                    ),
                ],
              ),
            ),

            // Bookmark list
            ...displayBookmarks.map(
              (bookmark) => BookmarkListTile(
                bookmark: bookmark,
                onTap: () => onBookmarkTap?.call(bookmark),
                compact: true,
              ),
            ),

            if (bookmarks.length > maxItems)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  '${bookmarks.length - maxItems} more bookmark${bookmarks.length - maxItems == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
