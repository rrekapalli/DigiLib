import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/sync_status_provider.dart';
import '../../widgets/sync_status_indicator.dart';
import '../../widgets/sync_progress_bar.dart';
import '../../widgets/offline_mode_indicator.dart';
import '../../widgets/sync_conflict_dialog.dart';
import '../../services/sync_service.dart';
import '../../services/job_queue_service.dart' as job_queue;
import '../../models/ui/sync_status_models.dart' as ui;
import '../../models/api/sync_models.dart';

/// Screen that displays comprehensive sync status and management options
class SyncStatusScreen extends ConsumerWidget {
  const SyncStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final combinedStatus = ref.watch(combinedSyncStatusProvider);
    final syncActions = ref.watch(syncActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: combinedStatus.isSyncing
                ? null
                : () => ref.read(syncActionsProvider.notifier).forceSyncNow(),
            tooltip: 'Force sync now',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(syncActionsProvider.notifier).forceSyncNow(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall status card
              _buildOverallStatusCard(context, combinedStatus),

              const SizedBox(height: 16.0),

              // Sync progress (if syncing)
              if (combinedStatus.isSyncing)
                SyncProgressBar(
                  syncProgress: SyncProgress(
                    status: _convertSyncStatus(
                      combinedStatus.syncProgress.status,
                    ),
                    totalChanges: combinedStatus.syncProgress.totalItems ?? 0,
                    processedChanges:
                        combinedStatus.syncProgress.processedItems ?? 0,
                    message: combinedStatus.syncProgress.currentOperation,
                    error: combinedStatus.syncProgress.error,
                  ),
                  showDetails: true,
                ),

              // Offline mode indicator
              if (combinedStatus.isOffline) ...[
                OfflineLimitationsCard(
                  pendingActions: combinedStatus.pendingActions,
                  onViewPendingActions: () =>
                      _showPendingActionsDialog(context, ref),
                ),
                const SizedBox(height: 16.0),
              ],

              // Conflicts section
              if (combinedStatus.hasConflicts) ...[
                _buildConflictsSection(context, ref, combinedStatus),
                const SizedBox(height: 16.0),
              ],

              // Job queue status
              _buildJobQueueSection(context, ref, combinedStatus),

              const SizedBox(height: 16.0),

              // Sync actions
              _buildSyncActionsSection(
                context,
                ref,
                combinedStatus,
                syncActions,
              ),

              const SizedBox(height: 16.0),

              // Sync history/statistics
              _buildSyncHistorySection(context, combinedStatus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallStatusCard(
    BuildContext context,
    CombinedSyncStatus status,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SyncStatusIndicator(
                  syncProgress: SyncProgress(
                    status: _convertSyncStatus(status.syncProgress.status),
                    totalChanges: status.syncProgress.totalItems ?? 0,
                    processedChanges: status.syncProgress.processedItems ?? 0,
                    message: status.syncProgress.currentOperation,
                    error: status.syncProgress.error,
                  ),
                  showText: false,
                  iconSize: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getOverallStatusTitle(status),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _getOverallStatusSubtitle(status),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!status.isOnline)
                  OfflineModeIndicator(
                    isOffline: true,
                    pendingActions: status.pendingActions,
                  ),
              ],
            ),

            if (status.hasIssues) ...[
              const SizedBox(height: 16.0),
              _buildIssuesSummary(context, status),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesSummary(BuildContext context, CombinedSyncStatus status) {
    final theme = Theme.of(context);
    final issues = <String>[];

    if (status.hasConflicts) {
      issues.add('${status.conflicts.length} sync conflicts');
    }
    if (status.failedActions > 0) {
      issues.add('${status.failedActions} failed actions');
    }
    if (status.syncProgress.status == ui.SyncStatus.error) {
      issues.add('Sync error');
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: theme.colorScheme.error, size: 20.0),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Issues: ${issues.join(', ')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictsSection(
    BuildContext context,
    WidgetRef ref,
    CombinedSyncStatus status,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.merge_type,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Sync Conflicts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              '${status.conflicts.length} items need conflict resolution.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showConflictHelpDialog(context),
                  child: const Text('Learn More'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () => _showConflictResolutionDialog(
                    context,
                    ref,
                    status.conflicts,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: const Text('Resolve Conflicts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobQueueSection(
    BuildContext context,
    WidgetRef ref,
    CombinedSyncStatus status,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.queue, color: theme.colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  'Action Queue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Queue statistics
            Row(
              children: [
                Expanded(
                  child: _buildQueueStat(
                    context,
                    'Pending',
                    '${status.pendingActions}',
                    Icons.pending_actions,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildQueueStat(
                    context,
                    'Processing',
                    '${status.jobQueueStatus.processingJobs}',
                    Icons.sync,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildQueueStat(
                    context,
                    'Failed',
                    '${status.failedActions}',
                    Icons.error,
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),

            if (status.jobQueueStatus.isActive ||
                status.jobQueueStatus.hasErrors) ...[
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status.jobQueueStatus.hasErrors)
                    TextButton(
                      onPressed: () => ref
                          .read(syncActionsProvider.notifier)
                          .retryFailedJobs(),
                      child: const Text('Retry Failed'),
                    ),
                  const SizedBox(width: 8.0),
                  TextButton(
                    onPressed: () => _showPendingActionsDialog(context, ref),
                    child: const Text('View Details'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.0),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        ],
      ),
    );
  }

  Widget _buildSyncActionsSection(
    BuildContext context,
    WidgetRef ref,
    CombinedSyncStatus status,
    AsyncValue<void> syncActions,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton.icon(
                  onPressed: status.isSyncing || !status.isOnline
                      ? null
                      : () => ref
                            .read(syncActionsProvider.notifier)
                            .forceSyncNow(),
                  icon: syncActions.isLoading
                      ? const SizedBox(
                          width: 16.0,
                          height: 16.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        )
                      : const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                ),

                if (status.jobQueueStatus.hasErrors)
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(syncActionsProvider.notifier)
                        .retryFailedJobs(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Failed'),
                  ),

                OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(syncActionsProvider.notifier).clearOldJobs(),
                  icon: const Icon(Icons.cleaning_services),
                  label: const Text('Clean Up'),
                ),
              ],
            ),

            if (syncActions.hasError) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 16.0,
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Action failed: ${syncActions.error}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
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
    );
  }

  Widget _buildSyncHistorySection(
    BuildContext context,
    CombinedSyncStatus status,
  ) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Information',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            _buildInfoRow(
              'Connection Status',
              status.isOnline ? 'Online' : 'Offline',
            ),
            _buildInfoRow(
              'Last Update',
              status.jobQueueStatus.lastUpdated?.toString() ?? 'Never',
            ),
            _buildInfoRow(
              'Total Actions',
              '${status.jobQueueStatus.totalJobs}',
            ),

            if (status.syncProgress.currentOperation != null)
              _buildInfoRow(
                'Current Status',
                status.syncProgress.currentOperation!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getOverallStatusTitle(CombinedSyncStatus status) {
    switch (status.healthStatus) {
      case SyncHealthStatus.healthy:
        return 'Everything is up to date';
      case SyncHealthStatus.syncing:
        return 'Synchronizing...';
      case SyncHealthStatus.offline:
        return 'Offline mode';
      case SyncHealthStatus.error:
        return 'Sync issues detected';
      case SyncHealthStatus.conflicts:
        return 'Conflicts need resolution';
    }
  }

  String _getOverallStatusSubtitle(CombinedSyncStatus status) {
    switch (status.healthStatus) {
      case SyncHealthStatus.healthy:
        return 'All your data is synchronized';
      case SyncHealthStatus.syncing:
        return 'Updating your data...';
      case SyncHealthStatus.offline:
        return '${status.pendingActions} actions pending';
      case SyncHealthStatus.error:
        return 'Some actions failed to sync';
      case SyncHealthStatus.conflicts:
        return '${status.conflicts.length} conflicts to resolve';
    }
  }

  void _showConflictResolutionDialog(
    BuildContext context,
    WidgetRef ref,
    List<SyncConflict> conflicts,
  ) {
    showDialog(
      context: context,
      builder: (context) => SyncConflictDialog(
        conflicts: conflicts,
        onResolveConflict: (conflictId, resolution) {
          ref
              .read(syncActionsProvider.notifier)
              .resolveConflict(
                conflictId,
                _convertJobQueueConflictResolution(resolution),
              );
        },
      ),
    );
  }

  void _showConflictHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Sync Conflicts'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sync conflicts occur when the same item is modified on multiple devices.',
              ),
              SizedBox(height: 16.0),
              Text(
                'Resolution Options:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text('• Use Server Version: Keep the version from the server'),
              Text('• Use Local Version: Keep your local changes'),
              Text('• Merge Changes: Combine both versions (when possible)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showPendingActionsDialog(BuildContext context, WidgetRef ref) {
    // TODO: Implement detailed pending actions dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Actions'),
        content: const Text(
          'This feature will show detailed information about pending sync actions.',
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

  /// Convert UI SyncStatus to service SyncStatus
  SyncStatus _convertSyncStatus(ui.SyncStatus uiStatus) {
    switch (uiStatus) {
      case ui.SyncStatus.idle:
        return SyncStatus.idle;
      case ui.SyncStatus.syncing:
        return SyncStatus.syncing;
      case ui.SyncStatus.completed:
        return SyncStatus.completed;
      case ui.SyncStatus.error:
        return SyncStatus.error;
      case ui.SyncStatus.paused:
        return SyncStatus.offline; // Map paused to offline
    }
  }

  /// Convert job queue ConflictResolution to UI ConflictResolution
  ui.ConflictResolution _convertJobQueueConflictResolution(
    job_queue.ConflictResolution jobResolution,
  ) {
    switch (jobResolution) {
      case job_queue.ConflictResolution.useLocal:
        return ui.ConflictResolution.useClient;
      case job_queue.ConflictResolution.useServer:
        return ui.ConflictResolution.useServer;
      case job_queue.ConflictResolution.merge:
        return ui.ConflictResolution.merge;
    }
  }
}
