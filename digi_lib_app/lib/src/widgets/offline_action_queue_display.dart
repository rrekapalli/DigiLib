import 'package:flutter/material.dart';
import '../services/job_queue_service.dart';

/// Widget that displays the status of offline action queue
class OfflineActionQueueDisplay extends StatelessWidget {
  final JobQueueStatus queueStatus;
  final List<Job>? pendingJobs;
  final List<Job>? failedJobs;
  final VoidCallback? onRetryFailed;
  final VoidCallback? onClearCompleted;
  final Function(String jobId)? onCancelJob;
  final Function(String jobId)? onRetryJob;

  const OfflineActionQueueDisplay({
    super.key,
    required this.queueStatus,
    this.pendingJobs,
    this.failedJobs,
    this.onRetryFailed,
    this.onClearCompleted,
    this.onCancelJob,
    this.onRetryJob,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.queue,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Offline Action Queue',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Queue status overview
            _buildQueueOverview(context),
            
            if (queueStatus.hasWork || queueStatus.hasErrors) ...[
              const SizedBox(height: 16.0),
              
              // Pending jobs section
              if (queueStatus.pendingJobs > 0) ...[
                _buildPendingJobsSection(context),
                const SizedBox(height: 12.0),
              ],
              
              // Failed jobs section
              if (queueStatus.failedJobs > 0) ...[
                _buildFailedJobsSection(context),
                const SizedBox(height: 12.0),
              ],
              
              // Actions
              _buildQueueActions(context),
            ],
            
            if (!queueStatus.hasWork && !queueStatus.hasErrors) ...[
              const SizedBox(height: 8.0),
              _buildEmptyState(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQueueOverview(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: _buildStatusCard(
            context,
            'Pending',
            queueStatus.pendingJobs.toString(),
            Icons.pending_actions,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildStatusCard(
            context,
            'Processing',
            queueStatus.processingJobs.toString(),
            Icons.sync,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildStatusCard(
            context,
            'Failed',
            queueStatus.failedJobs.toString(),
            Icons.error,
            theme.colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingJobsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.pending_actions,
              size: 20.0,
              color: Colors.blue,
            ),
            const SizedBox(width: 8.0),
            Text(
              'Pending Actions (${queueStatus.pendingJobs})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        
        if (pendingJobs != null && pendingJobs!.isNotEmpty) ...[
          ...pendingJobs!.take(3).map((job) => _buildJobTile(context, job)),
          if (pendingJobs!.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '... and ${pendingJobs!.length - 3} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Actions will be processed when you\'re back online.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFailedJobsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.error,
              size: 20.0,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8.0),
            Text(
              'Failed Actions (${queueStatus.failedJobs})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8.0),
        
        if (failedJobs != null && failedJobs!.isNotEmpty) ...[
          ...failedJobs!.take(3).map((job) => _buildJobTile(context, job, showError: true)),
          if (failedJobs!.length > 3)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '... and ${failedJobs!.length - 3} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'Some actions failed to sync. They will be retried automatically.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildJobTile(BuildContext context, Job job, {bool showError = false}) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Row(
        children: [
          Icon(
            _getJobTypeIcon(job.type),
            size: 16.0,
            color: showError 
                ? theme.colorScheme.error 
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getJobTypeDescription(job.type),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (showError && job.lastError != null) ...[
                  const SizedBox(height: 2.0),
                  Text(
                    job.lastError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontSize: 10.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Text(
                  _formatJobTime(job.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.0,
                  ),
                ),
              ],
            ),
          ),
          if (showError && onRetryJob != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 16.0),
              onPressed: () => onRetryJob!(job.id),
              tooltip: 'Retry',
            ),
          if (onCancelJob != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16.0),
              onPressed: () => onCancelJob!(job.id),
              tooltip: 'Cancel',
            ),
        ],
      ),
    );
  }

  Widget _buildQueueActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (queueStatus.failedJobs > 0 && onRetryFailed != null)
          TextButton.icon(
            onPressed: onRetryFailed,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Failed'),
          ),
        
        const SizedBox(width: 8.0),
        
        if (onClearCompleted != null)
          TextButton.icon(
            onPressed: onClearCompleted,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Clean Up'),
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'All actions are up to date. No pending or failed actions.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getJobTypeIcon(JobType type) {
    switch (type) {
      case JobType.createBookmark:
      case JobType.updateBookmark:
      case JobType.deleteBookmark:
        return Icons.bookmark;
      case JobType.createComment:
      case JobType.updateComment:
      case JobType.deleteComment:
        return Icons.comment;
      case JobType.updateReadingProgress:
      case JobType.deleteReadingProgress:
        return Icons.timeline;
      case JobType.createTag:
      case JobType.deleteTag:
      case JobType.addTagToDocument:
      case JobType.removeTagFromDocument:
        return Icons.label;
      case JobType.createShare:
      case JobType.updateShare:
      case JobType.deleteShare:
        return Icons.share;
      case JobType.createLibrary:
      case JobType.deleteLibrary:
      case JobType.scanLibrary:
        return Icons.folder;
    }
  }

  String _getJobTypeDescription(JobType type) {
    switch (type) {
      case JobType.createBookmark:
        return 'Create bookmark';
      case JobType.updateBookmark:
        return 'Update bookmark';
      case JobType.deleteBookmark:
        return 'Delete bookmark';
      case JobType.createComment:
        return 'Create comment';
      case JobType.updateComment:
        return 'Update comment';
      case JobType.deleteComment:
        return 'Delete comment';
      case JobType.updateReadingProgress:
        return 'Update reading progress';
      case JobType.deleteReadingProgress:
        return 'Delete reading progress';
      case JobType.createTag:
        return 'Create tag';
      case JobType.deleteTag:
        return 'Delete tag';
      case JobType.addTagToDocument:
        return 'Add tag to document';
      case JobType.removeTagFromDocument:
        return 'Remove tag from document';
      case JobType.createShare:
        return 'Create share';
      case JobType.updateShare:
        return 'Update share';
      case JobType.deleteShare:
        return 'Delete share';
      case JobType.createLibrary:
        return 'Create library';
      case JobType.deleteLibrary:
        return 'Delete library';
      case JobType.scanLibrary:
        return 'Scan library';
    }
  }

  String _formatJobTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Compact widget for showing queue status in app bars or status areas
class CompactOfflineActionQueueIndicator extends StatelessWidget {
  final JobQueueStatus queueStatus;
  final VoidCallback? onTap;

  const CompactOfflineActionQueueIndicator({
    super.key,
    required this.queueStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (!queueStatus.hasWork && !queueStatus.hasErrors) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
            Icon(
              _getStatusIcon(),
              size: 16.0,
              color: _getIconColor(theme),
            ),
            const SizedBox(width: 4.0),
            Text(
              _getStatusText(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getTextColor(theme),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    if (queueStatus.hasErrors) return Icons.error;
    if (queueStatus.processingJobs > 0) return Icons.sync;
    return Icons.pending_actions;
  }

  String _getStatusText() {
    if (queueStatus.hasErrors) {
      return '${queueStatus.failedJobs} failed';
    }
    if (queueStatus.processingJobs > 0) {
      return 'Processing ${queueStatus.processingJobs}';
    }
    return '${queueStatus.pendingJobs} pending';
  }

  Color _getIconColor(ThemeData theme) {
    if (queueStatus.hasErrors) return theme.colorScheme.error;
    if (queueStatus.processingJobs > 0) return Colors.orange;
    return Colors.blue;
  }

  Color _getTextColor(ThemeData theme) {
    return _getIconColor(theme);
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (queueStatus.hasErrors) return theme.colorScheme.errorContainer.withOpacity(0.1);
    if (queueStatus.processingJobs > 0) return Colors.orange.withOpacity(0.1);
    return Colors.blue.withOpacity(0.1);
  }

  Color _getBorderColor(ThemeData theme) {
    if (queueStatus.hasErrors) return theme.colorScheme.error.withOpacity(0.3);
    if (queueStatus.processingJobs > 0) return Colors.orange.withOpacity(0.3);
    return Colors.blue.withOpacity(0.3);
  }
}