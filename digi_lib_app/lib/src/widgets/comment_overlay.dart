import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/comment.dart';
import '../models/ui/text_selection_anchor.dart';
import '../services/comment_service.dart';
import '../providers/comment_provider.dart';
import '../widgets/comment_bubble.dart';
import '../widgets/comment_creation_dialog.dart';
import '../widgets/comment_edit_dialog.dart';

/// Overlay widget for displaying and managing comments on a page
class CommentOverlay extends ConsumerStatefulWidget {
  final String documentId;
  final int pageNumber;
  final Size pageSize;
  final bool isVisible;
  final VoidCallback? onCommentAdded;

  const CommentOverlay({
    super.key,
    required this.documentId,
    required this.pageNumber,
    required this.pageSize,
    this.isVisible = true,
    this.onCommentAdded,
  });

  @override
  ConsumerState<CommentOverlay> createState() => _CommentOverlayState();
}

class _CommentOverlayState extends ConsumerState<CommentOverlay> {
  final Set<String> _expandedComments = {};
  String? _selectedCommentId;

  void _showCreateCommentDialog({TextSelectionAnchor? anchor}) {
    showDialog(
      context: context,
      builder: (context) => CommentCreationDialog(
        documentId: widget.documentId,
        pageNumber: widget.pageNumber,
        anchor: anchor,
        onCommentCreated: () {
          widget.onCommentAdded?.call();
          // Refresh comments
          ref.invalidate(
            pageCommentsProvider((
              documentId: widget.documentId,
              pageNumber: widget.pageNumber,
            )),
          );
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
          // Refresh comments
          ref.invalidate(
            pageCommentsProvider((
              documentId: widget.documentId,
              pageNumber: widget.pageNumber,
            )),
          );
        },
      ),
    );
  }

  void _toggleCommentExpansion(String commentId) {
    setState(() {
      if (_expandedComments.contains(commentId)) {
        _expandedComments.remove(commentId);
      } else {
        _expandedComments.add(commentId);
      }
    });
  }

  void _selectComment(String commentId) {
    setState(() {
      _selectedCommentId = _selectedCommentId == commentId ? null : commentId;
    });
  }

  Offset _getCommentPosition(Comment comment, Size pageSize) {
    // If comment has anchor data, position based on text selection
    if (comment.anchor != null) {
      try {
        final anchor = TextSelectionAnchor.fromJson(comment.anchor!);
        // For now, position comments on the right side of the page
        // In a real implementation, you'd calculate position based on text layout
        return Offset(
          pageSize.width * 0.8,
          pageSize.height * 0.1 + (_expandedComments.length * 60.0),
        );
      } catch (e) {
        // Fallback to default position if anchor data is invalid
      }
    }

    // Default position for comments without anchors
    return Offset(
      pageSize.width * 0.8,
      pageSize.height * 0.1 + (comment.hashCode % 5) * 80.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final commentsAsync = ref.watch(
      pageCommentsProvider((
        documentId: widget.documentId,
        pageNumber: widget.pageNumber,
      )),
    );

    return commentsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (comments) => Stack(
        children: [
          // Comment bubbles positioned on the page
          ...comments.map((comment) {
            final position = _getCommentPosition(comment, widget.pageSize);
            final isExpanded = _expandedComments.contains(comment.id);
            final isSelected = _selectedCommentId == comment.id;

            return Positioned(
              left: position.dx,
              top: position.dy,
              child: CommentBubble(
                comment: comment,
                isExpanded: isExpanded,
                isSelected: isSelected,
                onTap: () => _selectComment(comment.id),
                onExpand: () => _toggleCommentExpansion(comment.id),
                onEdit: () => _showEditCommentDialog(comment),
                onDelete: () => _deleteComment(comment),
              ),
            );
          }),

          // Floating action button for adding comments
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              onPressed: () => _showCreateCommentDialog(),
              tooltip: 'Add Comment',
              child: const Icon(Icons.comment),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                await ref
                    .read(commentNotifierProvider.notifier)
                    .deleteComment(comment.id, widget.documentId);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Comment deleted'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to delete comment: ${error.toString()}',
                      ),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
}

/// Compact comment indicator for showing comment count
class CommentIndicator extends ConsumerWidget {
  final String documentId;
  final int pageNumber;
  final VoidCallback? onTap;

  const CommentIndicator({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentCountAsync = ref.watch(
      pageCommentCountProvider((
        documentId: documentId,
        pageNumber: pageNumber,
      )),
    );

    return commentCountAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.comment,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Text selection handler for creating anchored comments
class TextSelectionCommentHandler extends StatefulWidget {
  final Widget child;
  final String documentId;
  final int pageNumber;
  final Function(TextSelectionAnchor)? onCommentRequested;

  const TextSelectionCommentHandler({
    super.key,
    required this.child,
    required this.documentId,
    required this.pageNumber,
    this.onCommentRequested,
  });

  @override
  State<TextSelectionCommentHandler> createState() =>
      _TextSelectionCommentHandlerState();
}

class _TextSelectionCommentHandlerState
    extends State<TextSelectionCommentHandler> {
  String? _selectedText;
  Offset? _selectionPosition;

  void _handleTextSelection(String selectedText, Offset position) {
    setState(() {
      _selectedText = selectedText;
      _selectionPosition = position;
    });

    // Show comment creation option
    _showSelectionMenu(selectedText, position);
  }

  void _showSelectionMenu(String selectedText, Offset position) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 100,
        position.dy + 50,
      ),
      items: [
        PopupMenuItem(
          child: const ListTile(
            leading: Icon(Icons.comment),
            title: Text('Add Comment'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            final anchor = TextSelectionAnchor(
              startOffset:
                  0, // In real implementation, calculate from text layout
              endOffset: selectedText.length,
              selectedText: selectedText,
            );
            widget.onCommentRequested?.call(anchor);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) {
        // In a real implementation, you'd detect text selection here
        // For now, simulate text selection
        _handleTextSelection('Selected text', details.globalPosition);
      },
      child: widget.child,
    );
  }
}
