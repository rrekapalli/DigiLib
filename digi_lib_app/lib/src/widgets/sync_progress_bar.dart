import 'package:flutter/material.dart';
import '../services/sync_service.dart';

/// Widget that displays sync progress with a progress bar and detailed information
class SyncProgressBar extends StatelessWidget {
  final SyncProgress syncProgress;
  final bool showDetails;
  final VoidCallback? onCancel;

  const SyncProgressBar({
    super.key,
    required this.syncProgress,
    this.showDetails = true,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (syncProgress.status == SyncStatus.idle) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _buildStatusIcon(theme),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getTitle(),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (syncProgress.message != null) ...[
                        const SizedBox(height: 4.0),
                        Text(
                          syncProgress.message!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onCancel != null && syncProgress.status == SyncStatus.syncing)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onCancel,
                    tooltip: 'Cancel sync',
                  ),
              ],
            ),
            
            if (syncProgress.status == SyncStatus.syncing) ...[
              const SizedBox(height: 12.0),
              _buildProgressIndicator(theme),
            ],
            
            if (showDetails && _shouldShowDetails()) ...[
              const SizedBox(height: 12.0),
              _buildDetails(theme),
            ],
            
            if (syncProgress.status == SyncStatus.error) ...[
              const SizedBox(height: 12.0),
              _buildErrorActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: 24.0,
          height: 24.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        );
      case SyncStatus.completed:
        return Icon(
          Icons.check_circle,
          size: 24.0,
          color: Colors.green,
        );
      case SyncStatus.error:
        return Icon(
          Icons.error,
          size: 24.0,
          color: theme.colorScheme.error,
        );
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: 24.0,
          color: Colors.orange,
        );
      case SyncStatus.idle:
      default:
        return Icon(
          Icons.cloud_done,
          size: 24.0,
          color: theme.colorScheme.onSurfaceVariant,
        );
    }
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    if (syncProgress.totalChanges > 0) {
      return Column(
        children: [
          LinearProgressIndicator(
            value: syncProgress.progress,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${syncProgress.processedChanges} of ${syncProgress.totalChanges} items',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                '${(syncProgress.progress * 100).toInt()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return LinearProgressIndicator(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
      );
    }
  }

  Widget _buildDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (syncProgress.totalChanges > 0) ...[
            _buildDetailRow('Total items:', '${syncProgress.totalChanges}'),
            _buildDetailRow('Processed:', '${syncProgress.processedChanges}'),
            _buildDetailRow('Remaining:', '${syncProgress.totalChanges - syncProgress.processedChanges}'),
          ],
          if (syncProgress.error != null) ...[
            const SizedBox(height: 8.0),
            Text(
              'Error: ${syncProgress.error}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
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

  Widget _buildErrorActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {
            // TODO: Show error details dialog
            _showErrorDetails(context);
          },
          child: const Text('View Details'),
        ),
        const SizedBox(width: 8.0),
        ElevatedButton(
          onPressed: () {
            // TODO: Trigger retry
            _retrySync(context);
          },
          child: const Text('Retry'),
        ),
      ],
    );
  }

  String _getTitle() {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return 'Synchronizing';
      case SyncStatus.completed:
        return 'Sync Complete';
      case SyncStatus.error:
        return 'Sync Failed';
      case SyncStatus.offline:
        return 'Offline Mode';
      case SyncStatus.idle:
      default:
        return 'Sync Status';
    }
  }

  bool _shouldShowDetails() {
    return syncProgress.status == SyncStatus.syncing ||
           syncProgress.status == SyncStatus.error ||
           (syncProgress.status == SyncStatus.completed && syncProgress.totalChanges > 0);
  }

  void _showErrorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (syncProgress.error != null) ...[
                const Text(
                  'Error Message:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                Text(syncProgress.error!),
                const SizedBox(height: 16.0),
              ],
              const Text(
                'Troubleshooting:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text('• Check your internet connection'),
              const Text('• Verify your account credentials'),
              const Text('• Try again in a few moments'),
              const Text('• Contact support if the problem persists'),
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

  void _retrySync(BuildContext context) {
    // TODO: Implement retry logic through a callback or provider
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retrying sync...'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}