import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';
import '../providers/comment_provider.dart';
import '../screens/reader/bookmark_list_screen.dart';
import '../widgets/bookmark_creation_dialog.dart';
import '../widgets/comment_creation_dialog.dart';

/// Annotation toolbar for creating bookmarks, highlights, and comments
class AnnotationToolbar extends ConsumerStatefulWidget {
  final String documentId;
  final int currentPage;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onHighlightPressed;
  final VoidCallback? onCommentPressed;
  final VoidCallback? onAnnotationListPressed;
  final bool isVisible;

  const AnnotationToolbar({
    super.key,
    required this.documentId,
    required this.currentPage,
    this.onBookmarkPressed,
    this.onHighlightPressed,
    this.onCommentPressed,
    this.onAnnotationListPressed,
    this.isVisible = true,
  });

  @override
  ConsumerState<AnnotationToolbar> createState() => _AnnotationToolbarState();
}

class _AnnotationToolbarState extends ConsumerState<AnnotationToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => BookmarkCreationDialog(
        documentId: widget.documentId,
        initialPageNumber: widget.currentPage,
        onBookmarkCreated: () {
          // Refresh bookmark providers
          ref.invalidate(documentBookmarksProvider(widget.documentId));
          ref.invalidate(
            hasBookmarkAtPageProvider((
              documentId: widget.documentId,
              pageNumber: widget.currentPage,
            )),
          );
        },
      ),
    );
  }

  void _showCommentDialog() {
    showDialog(
      context: context,
      builder: (context) => CommentCreationDialog(
        documentId: widget.documentId,
        pageNumber: widget.currentPage,
        onCommentCreated: () {
          // Refresh comment providers
          ref.invalidate(
            pageCommentsProvider((
              documentId: widget.documentId,
              pageNumber: widget.currentPage,
            )),
          );
          ref.invalidate(documentCommentsProvider(widget.documentId));
        },
      ),
    );
  }

  void _showAnnotationsList() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookmarkListScreen(documentId: widget.documentId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return Positioned(
      right: 16,
      top: MediaQuery.of(context).size.height * 0.3,
      child: Column(
        children: [
          // Main annotation button
          FloatingActionButton(
            mini: true,
            onPressed: _toggleExpanded,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: const Icon(Icons.add),
            ),
          ),

          // Expanded toolbar
          AnimatedBuilder(
            animation: _slideAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -8 * _slideAnimation.value),
              child: Opacity(opacity: _slideAnimation.value, child: child),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),

                // Bookmark button
                _buildToolbarButton(
                  icon: Icons.bookmark_add,
                  label: 'Bookmark',
                  onPressed: _showBookmarkDialog,
                ),

                const SizedBox(height: 8),

                // Highlight button
                _buildToolbarButton(
                  icon: Icons.highlight,
                  label: 'Highlight',
                  onPressed: widget.onHighlightPressed,
                ),

                const SizedBox(height: 8),

                // Comment button
                _buildToolbarButton(
                  icon: Icons.comment,
                  label: 'Comment',
                  onPressed: _showCommentDialog,
                ),

                const SizedBox(height: 8),

                // Annotations list button
                _buildToolbarButton(
                  icon: Icons.list,
                  label: 'View All',
                  onPressed: _showAnnotationsList,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: label,
      child: FloatingActionButton(
        mini: true,
        onPressed: onPressed,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 2,
        child: Icon(icon, size: 20),
      ),
    );
  }
}

/// Bottom sheet for viewing all annotations
class _AnnotationsListSheet extends StatefulWidget {
  final String documentId;
  final int currentPage;

  const _AnnotationsListSheet({
    required this.documentId,
    required this.currentPage,
  });

  @override
  State<_AnnotationsListSheet> createState() => _AnnotationsListSheetState();
}

class _AnnotationsListSheetState extends State<_AnnotationsListSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Annotations',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Bookmarks'),
              Tab(text: 'Comments'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildBookmarksList(), _buildCommentsList()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookmarksList() {
    return Consumer(
      builder: (context, ref, child) {
        final bookmarksAsync = ref.watch(
          documentBookmarksProvider(widget.documentId),
        );

        return bookmarksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                Text('Failed to load bookmarks'),
                TextButton(
                  onPressed: () => ref.invalidate(
                    documentBookmarksProvider(widget.documentId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (bookmarks) {
            if (bookmarks.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 48),
                    SizedBox(height: 8),
                    Text('No bookmarks yet'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                final isCurrentPage = bookmark.pageNumber == widget.currentPage;

                return Card(
                  color: isCurrentPage
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      child: Text('${bookmark.pageNumber ?? '?'}'),
                    ),
                    title: Text('Page ${bookmark.pageNumber ?? 'Unknown'}'),
                    subtitle: bookmark.note?.isNotEmpty == true
                        ? Text(bookmark.note!)
                        : null,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to bookmark page
                      if (bookmark.pageNumber != null) {
                        // TODO: Navigate to page in reader
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCommentsList() {
    return Consumer(
      builder: (context, ref, child) {
        final commentsAsync = ref.watch(
          documentCommentsProvider(widget.documentId),
        );

        return commentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 8),
                Text('Failed to load comments'),
                TextButton(
                  onPressed: () => ref.invalidate(
                    documentCommentsProvider(widget.documentId),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (comments) {
            if (comments.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.comment_outlined, size: 48),
                    SizedBox(height: 8),
                    Text('No comments yet'),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: comments.length,
              itemBuilder: (context, index) {
                final comment = comments[index];
                final isCurrentPage = comment.pageNumber == widget.currentPage;

                return Card(
                  color: isCurrentPage
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                      child: Text('${comment.pageNumber ?? '?'}'),
                    ),
                    title: Text('Page ${comment.pageNumber ?? 'Unknown'}'),
                    subtitle: Text(
                      comment.content ?? 'No content',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      // Navigate to comment page
                      if (comment.pageNumber != null) {
                        // TODO: Navigate to page in reader
                      }
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Compact annotation toolbar for minimal UI
class CompactAnnotationToolbar extends StatelessWidget {
  final String documentId;
  final int currentPage;
  final VoidCallback? onBookmarkPressed;
  final VoidCallback? onCommentPressed;

  const CompactAnnotationToolbar({
    super.key,
    required this.documentId,
    required this.currentPage,
    this.onBookmarkPressed,
    this.onCommentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onBookmarkPressed,
            icon: const Icon(Icons.bookmark_add),
            iconSize: 20,
            tooltip: 'Add bookmark',
          ),
          IconButton(
            onPressed: onCommentPressed,
            icon: const Icon(Icons.comment),
            iconSize: 20,
            tooltip: 'Add comment',
          ),
        ],
      ),
    );
  }
}
