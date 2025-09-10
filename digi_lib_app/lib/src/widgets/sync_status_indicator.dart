import 'package:flutter/material.dart';
import '../services/sync_service.dart';

/// Widget that displays the current sync status with appropriate icons and colors
class SyncStatusIndicator extends StatelessWidget {
  final SyncProgress syncProgress;
  final bool showText;
  final double iconSize;
  final VoidCallback? onTap;

  const SyncStatusIndicator({
    super.key,
    required this.syncProgress,
    this.showText = true,
    this.iconSize = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: _getBackgroundColor(theme),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: _getBorderColor(theme), width: 1.0),
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
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return SizedBox(
          width: iconSize,
          height: iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(_getIconColor(theme)),
          ),
        );
      case SyncStatus.completed:
        return Icon(
          Icons.check_circle,
          size: iconSize,
          color: _getIconColor(theme),
        );
      case SyncStatus.error:
        return Icon(Icons.error, size: iconSize, color: _getIconColor(theme));
      case SyncStatus.offline:
        return Icon(
          Icons.cloud_off,
          size: iconSize,
          color: _getIconColor(theme),
        );
      case SyncStatus.idle:
      default:
        return Icon(
          Icons.cloud_done,
          size: iconSize,
          color: _getIconColor(theme),
        );
    }
  }

  String _getStatusText() {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        if (syncProgress.message != null) {
          return syncProgress.message!;
        }
        if (syncProgress.totalChanges > 0) {
          return 'Syncing ${syncProgress.processedChanges}/${syncProgress.totalChanges}';
        }
        return 'Syncing...';
      case SyncStatus.completed:
        return 'Synced';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline';
      case SyncStatus.idle:
      default:
        return 'Up to date';
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return theme.colorScheme.primary;
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.offline:
        return Colors.orange;
      case SyncStatus.idle:
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getTextColor(ThemeData theme) {
    switch (syncProgress.status) {
      case SyncStatus.error:
        return theme.colorScheme.error;
      case SyncStatus.offline:
        return Colors.orange;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  Color _getBackgroundColor(ThemeData theme) {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
      case SyncStatus.completed:
        return Colors.green.withValues(alpha: 0.1);
      case SyncStatus.error:
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      case SyncStatus.offline:
        return Colors.orange.withOpacity(0.1);
      case SyncStatus.idle:
      default:
        return theme.colorScheme.surfaceContainerHighest.withOpacity(0.3);
    }
  }

  Color _getBorderColor(ThemeData theme) {
    switch (syncProgress.status) {
      case SyncStatus.syncing:
        return theme.colorScheme.primary.withOpacity(0.3);
      case SyncStatus.completed:
        return Colors.green.withOpacity(0.3);
      case SyncStatus.error:
        return theme.colorScheme.error.withOpacity(0.3);
      case SyncStatus.offline:
        return Colors.orange.withOpacity(0.3);
      case SyncStatus.idle:
      default:
        return theme.colorScheme.outline.withOpacity(0.3);
    }
  }
}
