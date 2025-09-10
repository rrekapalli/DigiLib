import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/comment.dart';
import '../providers/comment_provider.dart';

/// Dialog for editing existing comments
class CommentEditDialog extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onCommentUpdated;

  const CommentEditDialog({
    super.key,
    required this.comment,
    this.onCommentUpdated,
  });

  @override
  ConsumerState<CommentEditDialog> createState() => _CommentEditDialogState();
}

class _CommentEditDialogState extends ConsumerState<CommentEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _contentController;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.comment.content ?? '');
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final hasChanges = _contentController.text.trim() != (widget.comment.content ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _updateComment() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(commentNotifierProvider.notifier).updateComment(
        widget.comment.id,
        _contentController.text.trim(),
        widget.comment.docId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCommentUpdated?.call();
        _showSuccessSnackBar('Comment updated');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to update comment: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteComment() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(commentNotifierProvider.notifier).deleteComment(
        widget.comment.id,
        widget.comment.docId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onCommentUpdated?.call();
        _showSuccessSnackBar('Comment deleted');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete comment: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text(
          'Are you sure you want to delete this comment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
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
      title: Text('Edit Comment - Page ${widget.comment.pageNumber}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment info
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
                        Icons.comment,
                        color: Theme.of(context).colorScheme.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Page ${widget.comment.pageNumber}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Created ${_formatDate(widget.comment.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  
                  // Selected text (if anchor exists)
                  if (widget.comment.anchor != null) ...[
                    const SizedBox(height: 8),
                    _buildAnchorInfo(),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Content field
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
            
            const SizedBox(height: 8),
            
            // Change indicator
            if (_hasChanges)
              Row(
                children: [
                  Icon(
                    Icons.edit,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Unsaved changes',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
      actions: [
        // Delete button
        TextButton.icon(
          onPressed: _isLoading ? null : _deleteComment,
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
        
        const Spacer(),
        
        // Cancel button
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        
        // Save button
        ElevatedButton(
          onPressed: (_isLoading || !_hasChanges) ? null : _updateComment,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildAnchorInfo() {
    try {
      final anchor = widget.comment.anchor!;
      final selectedText = anchor['selectedText'] as String?;
      
      if (selectedText?.isNotEmpty == true) {
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            ),
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
              const SizedBox(height: 4),
              Text(
                '"$selectedText"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks == 1 ? '' : 's'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }
}

/// Inline comment editor for quick editing
class InlineCommentEditor extends ConsumerStatefulWidget {
  final Comment comment;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const InlineCommentEditor({
    super.key,
    required this.comment,
    this.onSave,
    this.onCancel,
  });

  @override
  ConsumerState<InlineCommentEditor> createState() => _InlineCommentEditorState();
}

class _InlineCommentEditorState extends ConsumerState<InlineCommentEditor> {
  late final TextEditingController _contentController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.comment.content ?? '');
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(commentNotifierProvider.notifier).updateComment(
        widget.comment.id,
        _contentController.text.trim(),
        widget.comment.docId,
      );

      if (mounted) {
        widget.onSave?.call();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update comment: ${error.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                Icons.edit,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Editing comment on page ${widget.comment.pageNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Content field
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
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}