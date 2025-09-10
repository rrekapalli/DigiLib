import 'package:flutter/material.dart';

/// Enum for offline availability status
enum OfflineAvailabilityStatus {
  available,      // Document is fully cached and available offline
  partial,        // Some pages are cached
  notAvailable,   // Document is not cached
  downloading,    // Currently downloading for offline access
  failed,         // Download failed
}

/// Widget that indicates whether a document is available offline
class OfflineAvailabilityIndicator extends StatelessWidget {
  final OfflineAvailabilityStatus status;
  final double? progress; // For downloading status (0.0 to 1.0)
  final int? cachedPages;
  final int? totalPages;
  final bool showText;
  final double iconSize;
  final VoidCallback? onTap;

  const OfflineAvailabilityIndicator({
    super.key,
    required this.status,
    this.progress,
    this.cachedPages,
    this.totalPages,
    this.showText = false,
    this.iconSize = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: showText ? 8.0 : 4.0,
          vertical: 4.0,
        ),
        decoration: BoxDecoration(
          color: _getBackgroundColor(theme),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: _getBorderColor(theme),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(theme),
            if (showText) ...[
              const SizedBox(width: 6.0),
              Text(
                _getStatusText(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getTextColor(theme),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return Icon(
          Icons.offline_pin,
          size: iconSize,
          color: Colors.green,
        );
      case OfflineAvailabilityStatus.partial:
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.offline_pin_outlined,
              size: iconSize,
              color: Colors.orange,
            ),
            if (cachedPages != null && totalPages != null)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: iconSize * 0.4,
                  height: 2.0,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: cachedPages! / totalPages!,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(1.0),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      case OfflineAvailabilityStatus.downloading:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            value: progress,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        );
      case OfflineAvailabilityStatus.failed:
        return Icon(
          Icons.cloud_off,
          size: iconSize,
          color: theme.colorScheme.error,
        );
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return Icon(
          Icons.cloud_outlined,
          size: iconSize,
          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
        );
    }
  }

  String _getStatusText() {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return 'Available offline';
      case OfflineAvailabilityStatus.partial:
        if (cachedPages != null && totalPages != null) {
          return '$cachedPages/$totalPages pages cached';
        }
        return 'Partially cached';
      case OfflineAvailabilityStatus.downloading:
        if (progress != null) {
          return 'Downloading ${(progress! * 100).toInt()}%';
        }
        return 'Downloading...';
      case OfflineAvailabilityStatus.failed:
        return 'Download failed';
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return 'Online only';
    }
  }

  Color _getTextColor(ThemeData theme) {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return Colors.green;
      case OfflineAvailabilityStatus.partial:
        return Colors.orange;
      case OfflineAvailabilityStatus.downloading:
        return theme.colorScheme.primary;
      case OfflineAvailabilityStatus.failed:
        return theme.colorScheme.error;
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return Colors.green.withOpacity(0.1);
      case OfflineAvailabilityStatus.partial:
        return Colors.orange.withOpacity(0.1);
      case OfflineAvailabilityStatus.downloading:
        return theme.colorScheme.primaryContainer.withOpacity(0.1);
      case OfflineAvailabilityStatus.failed:
        return theme.colorScheme.errorContainer.withOpacity(0.1);
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    }
  }

  Color _getBorderColor(ThemeData theme) {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return Colors.green.withOpacity(0.3);
      case OfflineAvailabilityStatus.partial:
        return Colors.orange.withOpacity(0.3);
      case OfflineAvailabilityStatus.downloading:
        return theme.colorScheme.primary.withOpacity(0.3);
      case OfflineAvailabilityStatus.failed:
        return theme.colorScheme.error.withOpacity(0.3);
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return theme.colorScheme.outline.withOpacity(0.3);
    }
  }
}

/// Widget that shows detailed offline availability information
class OfflineAvailabilityCard extends StatelessWidget {
  final String documentId;
  final String documentTitle;
  final OfflineAvailabilityStatus status;
  final double? progress;
  final int? cachedPages;
  final int? totalPages;
  final int? cacheSizeBytes;
  final DateTime? lastCached;
  final VoidCallback? onDownload;
  final VoidCallback? onRemove;
  final VoidCallback? onRetry;

  const OfflineAvailabilityCard({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.status,
    this.progress,
    this.cachedPages,
    this.totalPages,
    this.cacheSizeBytes,
    this.lastCached,
    this.onDownload,
    this.onRemove,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                OfflineAvailabilityIndicator(
                  status: status,
                  progress: progress,
                  cachedPages: cachedPages,
                  totalPages: totalPages,
                  iconSize: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _getStatusDescription(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (_shouldShowProgress()) ...[
              const SizedBox(height: 12.0),
              _buildProgressIndicator(theme),
            ],
            
            if (_shouldShowDetails()) ...[
              const SizedBox(height: 12.0),
              _buildDetailsSection(theme),
            ],
            
            if (_shouldShowActions()) ...[
              const SizedBox(height: 12.0),
              _buildActionsSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    if (status != OfflineAvailabilityStatus.downloading || progress == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading for offline access...',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${(progress! * 100).toInt()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          if (cachedPages != null && totalPages != null)
            _buildDetailRow('Pages cached:', '$cachedPages of $totalPages'),
          if (cacheSizeBytes != null)
            _buildDetailRow('Cache size:', _formatBytes(cacheSizeBytes!)),
          if (lastCached != null)
            _buildDetailRow('Last cached:', _formatDateTime(lastCached!)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (status == OfflineAvailabilityStatus.failed && onRetry != null)
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        
        if (status == OfflineAvailabilityStatus.notAvailable && onDownload != null)
          ElevatedButton.icon(
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        
        if ((status == OfflineAvailabilityStatus.available || 
             status == OfflineAvailabilityStatus.partial) && onRemove != null) ...[
          const SizedBox(width: 8.0),
          OutlinedButton.icon(
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Remove'),
          ),
        ],
      ],
    );
  }

  String _getStatusDescription() {
    switch (status) {
      case OfflineAvailabilityStatus.available:
        return 'Fully available offline';
      case OfflineAvailabilityStatus.partial:
        if (cachedPages != null && totalPages != null) {
          return '$cachedPages of $totalPages pages cached';
        }
        return 'Partially available offline';
      case OfflineAvailabilityStatus.downloading:
        return 'Downloading for offline access';
      case OfflineAvailabilityStatus.failed:
        return 'Failed to download for offline access';
      case OfflineAvailabilityStatus.notAvailable:
      default:
        return 'Not available offline';
    }
  }

  bool _shouldShowProgress() {
    return status == OfflineAvailabilityStatus.downloading && progress != null;
  }

  bool _shouldShowDetails() {
    return status == OfflineAvailabilityStatus.available ||
           status == OfflineAvailabilityStatus.partial ||
           (status == OfflineAvailabilityStatus.downloading && progress != null);
  }

  bool _shouldShowActions() {
    return onDownload != null || onRemove != null || onRetry != null;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}