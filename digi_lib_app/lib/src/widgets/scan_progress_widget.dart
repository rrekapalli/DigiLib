import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/library_provider.dart';

/// Widget displaying scan progress for a library
class ScanProgressWidget extends ConsumerWidget {
  final String libraryId;
  final VoidCallback? onCancel;

  const ScanProgressWidget({
    super.key,
    required this.libraryId,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanProgress = ref.watch(scanProgressProvider(libraryId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (scanProgress == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getScanStatusIcon(scanProgress.status),
                  color: _getScanStatusColor(scanProgress.status, colorScheme),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Library Scan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (scanProgress.status == 'running' && onCancel != null) ...[
                  TextButton(
                    onPressed: onCancel,
                    child: const Text('Cancel'),
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    _getScanStatusText(scanProgress.status),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getScanStatusColor(scanProgress.status, colorScheme),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (scanProgress.status == 'running') ...[
                  Text(
                    '${scanProgress.progress}%',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            
            if (scanProgress.status == 'running') ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: scanProgress.progress / 100,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ],
            
            if (scanProgress.error != null) ...[
              const SizedBox(height: 12),
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
                        scanProgress.error!,
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
            
            const SizedBox(height: 8),
            
            Text(
              'Started ${_formatTime(scanProgress.timestamp)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getScanStatusIcon(String status) {
    switch (status) {
      case 'running':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'queued':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Color _getScanStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'running':
      case 'queued':
        return colorScheme.primary;
      case 'completed':
        return Colors.green;
      case 'failed':
        return colorScheme.error;
      case 'cancelled':
        return colorScheme.onSurface.withValues(alpha: 0.6);
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _getScanStatusText(String status) {
    switch (status) {
      case 'running':
        return 'Scanning for documents...';
      case 'completed':
        return 'Scan completed successfully';
      case 'failed':
        return 'Scan failed';
      case 'cancelled':
        return 'Scan was cancelled';
      case 'queued':
        return 'Scan queued for processing';
      default:
        return 'Unknown scan status';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}