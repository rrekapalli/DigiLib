import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/comment_provider.dart';
import '../providers/auth_provider.dart';
import '../services/comment_service.dart';

/// Dialog for creating new comments
class CommentCreationDialog extends ConsumerStatefulWidget {
  final String documentId;
  final int pageNumber;
  final TextSelectionAnchor? anchor;
  final VoidCallback? onCommentCreated;

  const CommentCreationDialog({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.anchor,
    this.onCommentCreated,
  });

  @override
  ConsumerState<CommentCreationDialog> createState() => _CommentCreationDialogState();
}

class _CommentCreationDialogState extends ConsumerState<CommentCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createComment() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(commentNotifierProvider.notifier).addComment(
        widget.documentId,
        widget.pageNumber,
        _contentController.text.trim(),
        user.id,
        anchor: widget.anchor,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCommentCreated?.call();
        _showSuccessSnackBar('Comment added to page ${widget.pageNumber}');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to create comment: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Comment - Page ${widget.pageNumber}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected text info (if anchor exists)
            if (widget.anchor != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.format_quote,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Selected text:',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '"${widget.anchor!.selectedText}"',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Comment content field
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                hintText: 'Enter your comment...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment),
              ),
              maxLines: 4,
              maxLength: 1000,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a comment';
                }
                if (value.trim().length < 3) {
                  return 'Comment must be at least 3 characters long';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createComment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Comment'),
        ),
      ],
    );
  }
}

/// Quick comment creation widget for inline use
class QuickCommentButton extends ConsumerWidget {
  final String documentId;
  final int pageNumber;
  final TextSelectionAnchor? anchor;
  final VoidCallback? onCommentCreated;

  const QuickCommentButton({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.anchor,
    this.onCommentCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => _showCreateDialog(context),
      icon: const Icon(Icons.comment),
      tooltip: 'Add comment',
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CommentCreationDialog(
        documentId: documentId,
        pageNumber: pageNumber,
        anchor: anchor,
        onCommentCreated: onCommentCreated,
      ),
    );
  }
}

/// Floating comment creation button
class FloatingCommentButton extends StatelessWidget {
  final String documentId;
  final int pageNumber;
  final TextSelectionAnchor? anchor;
  final VoidCallback? onCommentCreated;

  const FloatingCommentButton({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.anchor,
    this.onCommentCreated,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      onPressed: () => _showCreateDialog(context),
      tooltip: 'Add Comment',
      child: const Icon(Icons.comment),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CommentCreationDialog(
        documentId: documentId,
        pageNumber: pageNumber,
        anchor: anchor,
        onCommentCreated: onCommentCreated,
      ),
    );
  }
}

/// Inline comment creation widget
class InlineCommentCreator extends ConsumerStatefulWidget {
  final String documentId;
  final int pageNumber;
  final TextSelectionAnchor? anchor;
  final VoidCallback? onCommentCreated;
  final VoidCallback? onCancel;

  const InlineCommentCreator({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.anchor,
    this.onCommentCreated,
    this.onCancel,
  });

  @override
  ConsumerState<InlineCommentCreator> createState() => _InlineCommentCreatorState();
}

class _InlineCommentCreatorState extends ConsumerState<InlineCommentCreator> {
  final _contentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _createComment() async {
    if (_contentController.text.trim().isEmpty) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(commentNotifierProvider.notifier).addComment(
        widget.documentId,
        widget.pageNumber,
        _contentController.text.trim(),
        user.id,
        anchor: widget.anchor,
      );

      if (mounted) {
        widget.onCommentCreated?.call();
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to create comment: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.comment,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Adding comment to page ${widget.pageNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          // Selected text (if anchor exists)
          if (widget.anchor != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '"${widget.anchor!.selectedText}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          const SizedBox(height: 8),
          
          // Comment field
          TextField(
            controller: _contentController,
            decoration: const InputDecoration(
              hintText: 'Enter your comment...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 3,
            autofocus: true,
          ),
          
          const SizedBox(height: 8),
          
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : widget.onCancel,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isLoading ? null : _createComment,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}