import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/bookmark.dart';
import '../providers/bookmark_provider.dart';

/// Dialog for editing existing bookmarks
class BookmarkEditDialog extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final VoidCallback? onBookmarkUpdated;

  const BookmarkEditDialog({
    super.key,
    required this.bookmark,
    this.onBookmarkUpdated,
  });

  @override
  ConsumerState<BookmarkEditDialog> createState() => _BookmarkEditDialogState();
}

class _BookmarkEditDialogState extends ConsumerState<BookmarkEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.bookmark.note ?? '');
    _noteController.addListener(_onNoteChanged);
  }

  @override
  void dispose() {
    _noteController.removeListener(_onNoteChanged);
    _noteController.dispose();
    super.dispose();
  }

  void _onNoteChanged() {
    final hasChanges = _noteController.text.trim() != (widget.bookmark.note ?? '');
    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  Future<void> _updateBookmark() async {
    if (!_formKey.currentState!.validate() || !_hasChanges) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newNote = _noteController.text.trim();
      await ref.read(bookmarkNotifierProvider.notifier).updateBookmark(
        widget.bookmark.id,
        widget.bookmark.docId,
        note: newNote.isEmpty ? null : newNote,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBookmarkUpdated?.call();
        _showSuccessSnackBar('Bookmark updated');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to update bookmark: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteBookmark() async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(bookmarkNotifierProvider.notifier).deleteBookmark(
        widget.bookmark.id,
        widget.bookmark.docId,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBookmarkUpdated?.call();
        _showSuccessSnackBar('Bookmark deleted');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to delete bookmark: ${error.toString()}');
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
        title: const Text('Delete Bookmark'),
        content: Text(
          'Are you sure you want to delete the bookmark on page ${widget.bookmark.pageNumber}?',
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
      title: Text('Edit Bookmark - Page ${widget.bookmark.pageNumber}'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Page ${widget.bookmark.pageNumber}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Created ${_formatDate(widget.bookmark.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Note field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Add a note for this bookmark...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 4,
              maxLength: 500,
              autofocus: true,
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
          onPressed: _isLoading ? null : _deleteBookmark,
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
          onPressed: (_isLoading || !_hasChanges) ? null : _updateBookmark,
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

/// Compact bookmark edit widget for inline editing
class InlineBookmarkEditor extends ConsumerStatefulWidget {
  final Bookmark bookmark;
  final VoidCallback? onSave;
  final VoidCallback? onCancel;

  const InlineBookmarkEditor({
    super.key,
    required this.bookmark,
    this.onSave,
    this.onCancel,
  });

  @override
  ConsumerState<InlineBookmarkEditor> createState() => _InlineBookmarkEditorState();
}

class _InlineBookmarkEditorState extends ConsumerState<InlineBookmarkEditor> {
  late final TextEditingController _noteController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.bookmark.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final newNote = _noteController.text.trim();
      await ref.read(bookmarkNotifierProvider.notifier).updateBookmark(
        widget.bookmark.id,
        widget.bookmark.docId,
        note: newNote.isEmpty ? null : newNote,
      );

      if (mounted) {
        widget.onSave?.call();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update bookmark: ${error.toString()}'),
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
                'Editing bookmark on page ${widget.bookmark.pageNumber}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Note field
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              hintText: 'Add a note for this bookmark...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            maxLines: 2,
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