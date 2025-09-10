import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entities/comment.dart';

/// Bubble widget for displaying individual comments
class CommentBubble extends StatelessWidget {
  final Comment comment;
  final bool isExpanded;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onExpand;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const CommentBubble({
    super.key,
    required this.comment,
    this.isExpanded = false,
    this.isSelected = false,
    this.onTap,
    this.onExpand,
    this.onEdit,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isExpanded ? 280 : 200,
        constraints: BoxConstraints(maxHeight: isExpanded ? 300 : 80),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  // Comment icon
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),

                  // Page indicator
                  Text(
                    'Page ${comment.pageNumber ?? '?'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(),

                  // Expand/collapse button
                  if (onExpand != null)
                    GestureDetector(
                      onTap: onExpand,
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Comment content
                    if (comment.content?.isNotEmpty == true)
                      Expanded(
                        child: Text(
                          comment.content!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Expanded(
                        child: Text(
                          'No content',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Timestamp
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    // Selected text indicator
                    if (comment.anchor != null && isExpanded)
                      _buildAnchorInfo(context),
                  ],
                ),
              ),
            ),

            // Actions
            if (showActions &&
                isExpanded &&
                (onEdit != null || onDelete != null))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                        iconSize: 16,
                        tooltip: 'Edit',
                      ),
                    if (onDelete != null)
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete),
                        iconSize: 16,
                        tooltip: 'Delete',
                        color: Theme.of(context).colorScheme.error,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnchorInfo(BuildContext context) {
    try {
      final anchor = comment.anchor!;
      final selectedText = anchor['selectedText'] as String?;

      if (selectedText?.isNotEmpty == true) {
        return Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected text:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '"$selectedText"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Ignore anchor parsing errors
    }

    return const SizedBox.shrink();
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat.MMMd().format(timestamp);
    }
  }
}

/// Compact comment chip for inline display
class CommentChip extends StatelessWidget {
  final Comment comment;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CommentChip({
    super.key,
    required this.comment,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (onDelete != null) {
      return InputChip(
        avatar: Icon(
          Icons.comment,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          comment.content?.isNotEmpty == true
              ? comment.content!
              : 'Comment on page ${comment.pageNumber ?? '?'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
      );
    } else {
      return ActionChip(
        avatar: Icon(
          Icons.comment,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        label: Text(
          comment.content?.isNotEmpty == true
              ? comment.content!
              : 'Comment on page ${comment.pageNumber ?? '?'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
      );
    }
  }
}

/// Thread view for displaying comment conversations
class CommentThread extends StatelessWidget {
  final List<Comment> comments;
  final Function(Comment)? onCommentTap;
  final Function(Comment)? onCommentEdit;
  final Function(Comment)? onCommentDelete;

  const CommentThread({
    super.key,
    required this.comments,
    this.onCommentTap,
    this.onCommentEdit,
    this.onCommentDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Center(child: Text('No comments in this thread'));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: comments.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final comment = comments[index];
        return CommentBubble(
          comment: comment,
          isExpanded: true,
          onTap: () => onCommentTap?.call(comment),
          onEdit: () => onCommentEdit?.call(comment),
          onDelete: () => onCommentDelete?.call(comment),
        );
      },
    );
  }
}

/// Floating comment indicator for pages with comments
class FloatingCommentIndicator extends StatelessWidget {
  final int commentCount;
  final VoidCallback? onTap;
  final Offset position;

  const FloatingCommentIndicator({
    super.key,
    required this.commentCount,
    this.onTap,
    this.position = const Offset(0, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              commentCount > 99 ? '99+' : commentCount.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
