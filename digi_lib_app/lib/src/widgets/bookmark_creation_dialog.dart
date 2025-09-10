import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmark_provider.dart';
import '../providers/reader_provider.dart';
import '../providers/auth_provider.dart';

/// Dialog for creating new bookmarks
class BookmarkCreationDialog extends ConsumerStatefulWidget {
  final String documentId;
  final int? initialPageNumber;
  final VoidCallback? onBookmarkCreated;

  const BookmarkCreationDialog({
    super.key,
    required this.documentId,
    this.initialPageNumber,
    this.onBookmarkCreated,
  });

  @override
  ConsumerState<BookmarkCreationDialog> createState() => _BookmarkCreationDialogState();
}

class _BookmarkCreationDialogState extends ConsumerState<BookmarkCreationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = TextEditingController();
  final _noteController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Set initial page number
    if (widget.initialPageNumber != null) {
      _pageController.text = widget.initialPageNumber.toString();
    } else {
      // Get current page from reader state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final readerState = ref.read(readerStateProvider(widget.documentId));
        readerState.whenData((state) {
          if (mounted && _pageController.text.isEmpty) {
            _pageController.text = state.currentPage.toString();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _createBookmark() async {
    if (!_formKey.currentState!.validate()) return;

    final pageNumber = int.tryParse(_pageController.text);
    if (pageNumber == null) {
      _showErrorSnackBar('Invalid page number');
      return;
    }

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showErrorSnackBar('User not authenticated');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if bookmark already exists at this page
      final existingBookmark = await ref.read(bookmarkAtPageProvider((
        documentId: widget.documentId,
        pageNumber: pageNumber,
      )).future);

      if (existingBookmark != null) {
        if (mounted) {
          _showConfirmReplaceDialog(existingBookmark.id, pageNumber, user.id);
        }
        return;
      }

      // Create new bookmark
      await ref.read(bookmarkNotifierProvider.notifier).addBookmark(
        widget.documentId,
        pageNumber,
        user.id,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onBookmarkCreated?.call();
        _showSuccessSnackBar('Bookmark created on page $pageNumber');
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('Failed to create bookmark: ${error.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConfirmReplaceDialog(String existingBookmarkId, int pageNumber, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bookmark Exists'),
        content: Text(
          'A bookmark already exists on page $pageNumber. Do you want to replace it?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isLoading = false;
              });
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                // Update existing bookmark
                await ref.read(bookmarkNotifierProvider.notifier).updateBookmark(
                  existingBookmarkId,
                  widget.documentId,
                  note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
                );

                if (mounted) {
                  Navigator.of(context).pop();
                  widget.onBookmarkCreated?.call();
                  _showSuccessSnackBar('Bookmark updated on page $pageNumber');
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
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
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
      title: const Text('Add Bookmark'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Page number field
            TextFormField(
              controller: _pageController,
              decoration: const InputDecoration(
                labelText: 'Page Number',
                hintText: 'Enter page number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.bookmark),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a page number';
                }
                final pageNumber = int.tryParse(value);
                if (pageNumber == null || pageNumber < 1) {
                  return 'Please enter a valid page number';
                }
                return null;
              },
              autofocus: widget.initialPageNumber == null,
            ),
            
            const SizedBox(height: 16),
            
            // Note field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Add a note for this bookmark...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
              maxLength: 500,
              autofocus: widget.initialPageNumber != null,
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
          onPressed: _isLoading ? null : _createBookmark,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Bookmark'),
        ),
      ],
    );
  }
}

/// Quick bookmark creation widget for inline use
class QuickBookmarkButton extends ConsumerWidget {
  final String documentId;
  final int pageNumber;
  final String? note;
  final VoidCallback? onBookmarkCreated;

  const QuickBookmarkButton({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.note,
    this.onBookmarkCreated,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasBookmarkAsync = ref.watch(hasBookmarkAtPageProvider((
      documentId: documentId,
      pageNumber: pageNumber,
    )));

    return hasBookmarkAsync.when(
      loading: () => const IconButton(
        onPressed: null,
        icon: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (error, stackTrace) => IconButton(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.bookmark_border),
        tooltip: 'Add bookmark',
      ),
      data: (hasBookmark) => IconButton(
        onPressed: hasBookmark 
            ? () => _showRemoveDialog(context, ref)
            : () => _showCreateDialog(context, ref),
        icon: Icon(hasBookmark ? Icons.bookmark : Icons.bookmark_border),
        tooltip: hasBookmark ? 'Remove bookmark' : 'Add bookmark',
        color: hasBookmark ? Theme.of(context).colorScheme.primary : null,
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => BookmarkCreationDialog(
        documentId: documentId,
        initialPageNumber: pageNumber,
        onBookmarkCreated: onBookmarkCreated,
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref) async {
    final bookmark = await ref.read(bookmarkAtPageProvider((
      documentId: documentId,
      pageNumber: pageNumber,
    )).future);

    if (bookmark == null || !context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Bookmark'),
        content: Text(
          'Are you sure you want to remove the bookmark from page $pageNumber?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              try {
                await ref.read(bookmarkNotifierProvider.notifier)
                    .deleteBookmark(bookmark.id, documentId);
                
                onBookmarkCreated?.call();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bookmark removed from page $pageNumber'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (error) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove bookmark: ${error.toString()}'),
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
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}