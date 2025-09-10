import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/library.dart';
import '../providers/library_provider.dart';
import '../utils/constants.dart';
import 'scan_progress_widget.dart';

/// Enhanced dialog for library deletion with scan progress handling
class LibraryDeletionDialog extends ConsumerStatefulWidget {
  final Library library;

  const LibraryDeletionDialog({super.key, required this.library});

  @override
  ConsumerState<LibraryDeletionDialog> createState() =>
      _LibraryDeletionDialogState();
}

class _LibraryDeletionDialogState extends ConsumerState<LibraryDeletionDialog> {
  bool _isDeleting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final scanProgress = ref.watch(scanProgressProvider(widget.library.id));
    final isScanning = scanProgress != null && scanProgress.status == 'running';

    return AlertDialog(
      title: const Text('Delete Library'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete the library "${widget.library.name}"?',
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 16),

            // Warning about active scan
            if (isScanning) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This library is currently being scanned. Deleting it will cancel the scan.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Show scan progress
              ScanProgressWidget(libraryId: widget.library.id),

              const SizedBox(height: 16),
            ],

            // General warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever,
                    color: colorScheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All cached documents and metadata will be removed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Library details
            Text(
              'Library Details:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            _buildDetailRow('Name', widget.library.name, theme),
            _buildDetailRow(
              'Type',
              _getLibraryTypeDisplayName(widget.library.type),
              theme,
            ),
            _buildDetailRow(
              'Created',
              _formatDate(widget.library.createdAt),
              theme,
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error,
                      color: colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: colorScheme.onErrorContainer,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _handleDelete,
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
              : Text(isScanning ? 'Cancel Scan & Delete' : 'Delete'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  String _getLibraryTypeDisplayName(LibraryType type) {
    switch (type) {
      case LibraryType.local:
        return 'Local Folder';
      case LibraryType.gdrive:
        return 'Google Drive';
      case LibraryType.onedrive:
        return 'OneDrive';
      case LibraryType.s3:
        return 'Amazon S3';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _handleDelete() async {
    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      // Cancel any running scan first
      final scanProgress = ref.read(scanProgressProvider(widget.library.id));
      if (scanProgress != null && scanProgress.status == 'running') {
        try {
          await ref
              .read(libraryProvider.notifier)
              .cancelScanJob(scanProgress.jobId);
        } catch (e) {
          // Continue with deletion even if scan cancellation fails
          AppLogger.warning('Failed to cancel scan during library deletion', e);
        }
      }

      // Delete the library
      await ref.read(libraryProvider.notifier).deleteLibrary(widget.library.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Library "${widget.library.name}" deleted successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to delete library: $e';
        _isDeleting = false;
      });
    }
  }
}
