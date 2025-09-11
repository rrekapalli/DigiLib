import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Text selection overlay for document pages
class TextSelectionOverlay extends ConsumerStatefulWidget {
  final String documentId;
  final int pageNumber;
  final String? pageText;
  final VoidCallback? onSelectionChanged;
  final Function(String selectedText, Rect selectionRect)? onTextSelected;

  const TextSelectionOverlay({
    super.key,
    required this.documentId,
    required this.pageNumber,
    this.pageText,
    this.onSelectionChanged,
    this.onTextSelected,
  });

  @override
  ConsumerState<TextSelectionOverlay> createState() =>
      _TextSelectionOverlayState();
}

class _TextSelectionOverlayState extends ConsumerState<TextSelectionOverlay> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _selectedText;
  Rect? _selectionRect;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _textController.text = widget.pageText ?? '';
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _clearSelection();
    }
  }

  void _onSelectionChanged() {
    final selection = _textController.selection;

    if (selection.isValid && !selection.isCollapsed) {
      final selectedText = _textController.text.substring(
        selection.start,
        selection.end,
      );

      setState(() {
        _selectedText = selectedText;
        _isSelecting = true;
      });

      // Calculate selection rectangle (simplified)
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final rect = Rect.fromLTWH(
          50, // Approximate position
          100 + (selection.start / 50) * 20, // Rough line calculation
          200, // Approximate width
          20, // Line height
        );

        setState(() {
          _selectionRect = rect;
        });

        widget.onTextSelected?.call(selectedText, rect);
      }

      widget.onSelectionChanged?.call();
    } else {
      _clearSelection();
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedText = null;
      _selectionRect = null;
      _isSelecting = false;
    });
  }

  void _copyToClipboard() {
    if (_selectedText != null) {
      Clipboard.setData(ClipboardData(text: _selectedText!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text copied to clipboard'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      _clearSelection();
    }
  }

  void _addBookmark() {
    if (_selectedText != null && _selectionRect != null) {
      _showBookmarkDialog();
    }
  }

  void _addComment() {
    if (_selectedText != null && _selectionRect != null) {
      _showCommentDialog();
    }
  }

  void _showBookmarkDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Bookmark'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected text:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedText!.length > 100
                    ? '${_selectedText!.substring(0, 100)}...'
                    : _selectedText!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSubmitted: (note) {
                Navigator.of(context).pop();
                _createBookmark(note);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createBookmark('');
            },
            child: const Text('Add Bookmark'),
          ),
        ],
      ),
    );
  }

  void _showCommentDialog() {
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Comment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected text:',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _selectedText!.length > 100
                    ? '${_selectedText!.substring(0, 100)}...'
                    : _selectedText!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
                hintText: 'Enter your comment...',
              ),
              maxLines: 4,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isNotEmpty) {
                Navigator.of(context).pop();
                _createComment(commentController.text);
              }
            },
            child: const Text('Add Comment'),
          ),
        ],
      ),
    );
  }

  void _createBookmark(String note) {
    // TODO: Implement bookmark creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _clearSelection();
  }

  void _createComment(String comment) {
    // TODO: Implement comment creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comment added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Invisible text field for selection
        Positioned.fill(
          child: Opacity(
            opacity: 0.01, // Nearly invisible but still interactive
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: Colors.transparent,
                fontSize: 14,
                height: 1.4,
              ),
              onChanged: (_) => _onSelectionChanged(),
              onTap: _onSelectionChanged,
            ),
          ),
        ),

        // Selection toolbar
        if (_isSelecting && _selectionRect != null)
          Positioned(
            left: _selectionRect!.left,
            top: _selectionRect!.top - 50,
            child: _buildSelectionToolbar(),
          ),
      ],
    );
  }

  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
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
          IconButton(
            onPressed: _copyToClipboard,
            icon: Icon(
              Icons.copy,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            tooltip: 'Copy',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: _addBookmark,
            icon: Icon(
              Icons.bookmark_add,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            tooltip: 'Add bookmark',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: _addComment,
            icon: Icon(
              Icons.comment,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            tooltip: 'Add comment',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: _clearSelection,
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onInverseSurface,
              size: 20,
            ),
            tooltip: 'Clear selection',
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Text selection info model
class TextSelection {
  final String text;
  final int startOffset;
  final int endOffset;
  final Rect boundingRect;
  final int pageNumber;

  const TextSelection({
    required this.text,
    required this.startOffset,
    required this.endOffset,
    required this.boundingRect,
    required this.pageNumber,
  });

  Map<String, dynamic> toAnchor() {
    return {
      'type': 'text_selection',
      'page_number': pageNumber,
      'start_offset': startOffset,
      'end_offset': endOffset,
      'bounding_rect': {
        'left': boundingRect.left,
        'top': boundingRect.top,
        'width': boundingRect.width,
        'height': boundingRect.height,
      },
      'selected_text': text,
    };
  }

  factory TextSelection.fromAnchor(Map<String, dynamic> anchor) {
    final rect = anchor['bounding_rect'] as Map<String, dynamic>;
    return TextSelection(
      text: anchor['selected_text'] as String,
      startOffset: anchor['start_offset'] as int,
      endOffset: anchor['end_offset'] as int,
      pageNumber: anchor['page_number'] as int,
      boundingRect: Rect.fromLTWH(
        rect['left'] as double,
        rect['top'] as double,
        rect['width'] as double,
        rect['height'] as double,
      ),
    );
  }
}
