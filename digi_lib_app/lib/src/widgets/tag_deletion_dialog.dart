import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/tag.dart';
import '../providers/tag_provider.dart';

/// Dialog for confirming tag deletion
class TagDeletionDialog extends ConsumerStatefulWidget {
  final Tag tag;

  const TagDeletionDialog({
    super.key,
    required this.tag,
  });

  @override
  ConsumerState<TagDeletionDialog> createState() => _TagDeletionDialogState();
}

class _TagDeletionDialogState extends ConsumerState<TagDeletionDialog> {
  bool _isDeleting = false;
  final int _mockUsageCount = 0; // In real implementation, this would be fetched

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      icon: Icon(
        Icons.warning,
        color: colorScheme.error,
        size: 32,
      ),
      title: const Text('Delete Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyMedium,
              children: [
                const TextSpan(text: 'Are you sure you want to delete the tag '),
                TextSpan(
                  text: '"${widget.tag.name}"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Usage information
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _mockUsageCount > 0 
                  ? colorScheme.errorContainer
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _mockUsageCount > 0 ? Icons.warning : Icons.info,
                      size: 16,
                      color: _mockUsageCount > 0 
                          ? colorScheme.onErrorContainer
                          : colorScheme.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Usage Information',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: _mockUsageCount > 0 
                            ? colorScheme.onErrorContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _mockUsageCount > 0
                      ? 'This tag is currently used by $_mockUsageCount document${_mockUsageCount == 1 ? '' : 's'}. '
                        'Deleting it will remove the tag from all associated documents.'
                      : 'This tag is not currently used by any documents.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _mockUsageCount > 0 
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Warning message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.errorContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: colorScheme.error.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delete_forever,
                  size: 16,
                  color: colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This action cannot be undone.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _deleteTag,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _deleteTag() async {
    setState(() => _isDeleting = true);

    try {
      await ref.read(tagProvider.notifier).deleteTag(widget.tag.id);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tag "${widget.tag.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete tag: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}