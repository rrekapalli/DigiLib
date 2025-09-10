import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/comment.dart';
import '../../models/entities/document.dart';
import '../../providers/comment_provider.dart';
import '../../providers/reader_provider.dart';
import '../../widgets/comment_bubble.dart';
import '../../widgets/comment_creation_dialog.dart';
import '../../widgets/comment_edit_dialog.dart';

/// Screen for managing comments of a document
class CommentListScreen extends ConsumerStatefulWidget {
  final String documentId;
  final VoidCallback? onCommentSelected;

  const CommentListScreen({
    super.key,
    required this.documentId,
    this.onCommentSelected,
  });

  @override
  ConsumerState<CommentListScreen> createState() => _CommentListScreenState();
}

class _CommentListScreenState extends ConsumerState<CommentListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => CommentCreationDialog(
        documentId: widget.documentId,
        pageNumber: 1, // Default to page 1, user can change
        onCommentCreated: () {
          // Refresh comments list
          ref.invalidate(documentCommentsProvider(widget.documentId));
        },
      ),
    );
  }

  void _showEditCommentDialog(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => CommentEditDialog(
        comment: comment,
        onCommentUpdated: () {
          // Refresh comments list
          ref.invalidate(documentCommentsProvider(widget.documentId));
        },
      ),
    );
  }

  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: Text(
          'Are you sure you want to delete the comment on page ${comment.pageNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(commentNotifierProvider.notifier)
                  .deleteComment(comment.id, widget.documentId);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Comment deleted'),
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

  void _navigateToComment(Comment comment) {
    if (comment.pageNumber != null) {
      // Navigate to the comment page in the reader
      ref.read(readerStateProvider(widget.documentId).notifier)
          .goToPage(comment.pageNumber!);
      
      // Close the comment screen
      Navigator.of(context).pop();
      
      // Call callback if provided
      widget.onCommentSelected?.call();
    }
  }

  List<Comment> _filterComments(List<Comment> comments) {
    if (_searchQuery.isEmpty) return comments;
    
    return comments.where((comment) {
      final pageMatch = comment.pageNumber?.toString().contains(_searchQuery) ?? false;
      final contentMatch = comment.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      return pageMatch || contentMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final document = ref.watch(currentDocumentProvider(widget.documentId));
    final commentsAsync = ref.watch(documentCommentsProvider(widget.documentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search comments...',
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
        data: (doc) => _buildCommentsList(doc, commentsAsync),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCommentDialog,
        tooltip: 'Add Comment',
        child: const Icon(Icons.comment),
      ),
    );
  }

  Widget _buildErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
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

  Widget _buildCommentsList(Document document, AsyncValue<List<Comment>> commentsAsync) {
    return commentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _buildCommentsErrorView(error),
      data: (comments) {
        final filteredComments = _filterComments(comments);
        
        if (filteredComments.isEmpty) {
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
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
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
                    '${filteredComments.length} comment${filteredComments.length == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            // Comments list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredComments.length,
                itemBuilder: (context, index) {
                  final comment = filteredComments[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: CommentBubble(
                      comment: comment,
                      isExpanded: true,
                      onTap: () => _navigateToComment(comment),
                      onEdit: () => _showEditCommentDialog(comment),
                      onDelete: () => _deleteComment(comment),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCommentsErrorView(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.comment_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load comments',
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
              ref.invalidate(documentCommentsProvider(widget.documentId));
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
            Icons.comment_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty ? 'No comments found' : 'No comments yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty 
                ? 'Try adjusting your search terms'
                : 'Add comments to annotate your document',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateCommentDialog,
              icon: const Icon(Icons.comment),
              label: const Text('Add Comment'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact comment list widget for embedding in other screens
class CompactCommentList extends ConsumerWidget {
  final String documentId;
  final int maxItems;
  final VoidCallback? onViewAll;
  final Function(Comment)? onCommentTap;

  const CompactCommentList({
    super.key,
    required this.documentId,
    this.maxItems = 5,
    this.onViewAll,
    this.onCommentTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(documentCommentsProvider(documentId));

    return commentsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Failed to load comments',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (comments) {
        if (comments.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No comments',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final displayComments = comments.take(maxItems).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Comments (${comments.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (comments.length > maxItems && onViewAll != null)
                    TextButton(
                      onPressed: onViewAll,
                      child: const Text('View All'),
                    ),
                ],
              ),
            ),
            
            // Comment list
            ...displayComments.map((comment) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: CommentBubble(
                comment: comment,
                onTap: () => onCommentTap?.call(comment),
                showActions: false,
              ),
            )),
            
            if (comments.length > maxItems)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  '${comments.length - maxItems} more comment${comments.length - maxItems == 1 ? '' : 's'}',
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