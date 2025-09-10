import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/document.dart';
import '../providers/reader_provider.dart';

/// Toolbar for the document reader with navigation and actions
class ReaderToolbar extends ConsumerWidget {
  final Document document;
  final VoidCallback? onFullscreenToggle;
  final VoidCallback? onSettingsToggle;
  final VoidCallback? onBookmarkToggle;
  final VoidCallback? onSharePressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onCollaborationPressed;
  final bool isFullscreen;

  const ReaderToolbar({
    super.key,
    required this.document,
    this.onFullscreenToggle,
    this.onSettingsToggle,
    this.onBookmarkToggle,
    this.onSharePressed,
    this.onSearchPressed,
    this.onCollaborationPressed,
    this.isFullscreen = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            document.title ?? document.filename ?? 'Unknown Document',
            style: Theme.of(context).textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
          if (document.author != null)
            Text(
              document.author!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      actions: [
        // Search button
        if (onSearchPressed != null)
          IconButton(
            onPressed: onSearchPressed,
            icon: const Icon(Icons.search),
            tooltip: 'Search in document',
          ),

        // Bookmark button
        if (onBookmarkToggle != null)
          IconButton(
            onPressed: onBookmarkToggle,
            icon: const Icon(
              Icons.bookmark_border,
            ), // TODO: Toggle based on bookmark state
            tooltip: 'Add bookmark',
          ),

        // Share button
        if (onSharePressed != null)
          IconButton(
            onPressed: onSharePressed,
            icon: const Icon(Icons.share),
            tooltip: 'Share document',
          ),

        // Collaboration button
        if (onCollaborationPressed != null)
          IconButton(
            onPressed: onCollaborationPressed,
            icon: const Icon(Icons.people),
            tooltip: 'Collaboration',
          ),

        // Fullscreen toggle
        if (onFullscreenToggle != null)
          IconButton(
            onPressed: onFullscreenToggle,
            icon: Icon(isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            tooltip: isFullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
          ),

        // Settings button
        if (onSettingsToggle != null)
          IconButton(
            onPressed: onSettingsToggle,
            icon: const Icon(Icons.settings),
            tooltip: 'Reader settings',
          ),

        // More options menu
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(context, ref, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: ListTile(
                leading: Icon(Icons.refresh),
                title: Text('Refresh'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'info',
              child: ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('Document info'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download for offline'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'refresh':
        ref.read(readerStateProvider(document.id).notifier).refresh();
        break;
      case 'info':
        _showDocumentInfo(context);
        break;
      case 'download':
        _showDownloadDialog(context);
        break;
    }
  }

  void _showDocumentInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Document Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Title', document.title ?? 'Unknown'),
              _buildInfoRow('Author', document.author ?? 'Unknown'),
              _buildInfoRow('Filename', document.filename ?? 'Unknown'),
              _buildInfoRow('Format', document.format ?? 'Unknown'),
              _buildInfoRow(
                'Pages',
                document.pageCount?.toString() ?? 'Unknown',
              ),
              if (document.sizeBytes != null)
                _buildInfoRow('Size', _formatFileSize(document.sizeBytes!)),
              if (document.yearPublished != null)
                _buildInfoRow('Year', document.yearPublished.toString()),
              if (document.isbn != null) _buildInfoRow('ISBN', document.isbn!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download for Offline'),
        content: const Text(
          'This will download the document and cache all pages for offline reading. '
          'This may take some time and use storage space.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startOfflineDownload(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }

  void _startOfflineDownload(BuildContext context) {
    // TODO: Implement offline download functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline download started...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Compact toolbar for embedded reader
class CompactReaderToolbar extends ConsumerWidget {
  final Document document;
  final VoidCallback? onClose;
  final VoidCallback? onFullscreen;

  const CompactReaderToolbar({
    super.key,
    required this.document,
    this.onClose,
    this.onFullscreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Document title
          Expanded(
            child: Text(
              document.title ?? document.filename ?? 'Unknown Document',
              style: Theme.of(context).textTheme.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Fullscreen button
          if (onFullscreen != null)
            IconButton(
              onPressed: onFullscreen,
              icon: const Icon(Icons.fullscreen),
              iconSize: 20,
              tooltip: 'Open in fullscreen',
            ),

          // Close button
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close),
              iconSize: 20,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
}
