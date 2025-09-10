import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/offline_availability_indicator.dart';
import '../../widgets/offline_storage_manager.dart';
import '../../widgets/offline_action_queue_display.dart';
import '../../widgets/download_for_offline_dialog.dart';
import '../../providers/sync_status_provider.dart';
import '../../services/job_queue_service.dart';

/// Screen for managing offline content and storage
class OfflineManagementScreen extends ConsumerStatefulWidget {
  const OfflineManagementScreen({super.key});

  @override
  ConsumerState<OfflineManagementScreen> createState() =>
      _OfflineManagementScreenState();
}

class _OfflineManagementScreenState
    extends ConsumerState<OfflineManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final combinedStatus = ref.watch(combinedSyncStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.storage), text: 'Storage'),
            Tab(icon: Icon(Icons.download), text: 'Downloads'),
            Tab(icon: Icon(Icons.queue), text: 'Actions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Storage tab
          _buildStorageTab(context, combinedStatus),

          // Downloads tab
          _buildDownloadsTab(context),

          // Actions tab
          _buildActionsTab(context, combinedStatus),
        ],
      ),
    );
  }

  Widget _buildStorageTab(BuildContext context, CombinedSyncStatus status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Storage overview
          OfflineStorageManager(
            stats: _getMockStorageStats(), // TODO: Get real stats from provider
            onCleanupCache: _cleanupCache,
            onClearAllCache: _clearAllCache,
            onManageDocuments: _manageDocuments,
            onUpdateCacheLimit: _updateCacheLimit,
          ),

          const SizedBox(height: 16.0),

          // Storage breakdown
          _buildStorageBreakdown(context),

          const SizedBox(height: 16.0),

          // Cache settings
          _buildCacheSettings(context),
        ],
      ),
    );
  }

  Widget _buildDownloadsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Download status overview
          _buildDownloadOverview(context),

          const SizedBox(height: 16.0),

          // Downloaded documents list
          _buildDownloadedDocumentsList(context),
        ],
      ),
    );
  }

  Widget _buildActionsTab(BuildContext context, CombinedSyncStatus status) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action queue display
          OfflineActionQueueDisplay(
            queueStatus: JobQueueStatus(
              pendingJobs: status.jobQueueStatus.pendingJobs,
              processingJobs: status.jobQueueStatus.processingJobs,
              failedJobs: status.jobQueueStatus.failedJobs,
              lastUpdated: status.jobQueueStatus.lastUpdated ?? DateTime.now(),
            ),
            pendingJobs:
                _getMockPendingJobs(), // TODO: Get real jobs from provider
            failedJobs:
                _getMockFailedJobs(), // TODO: Get real jobs from provider
            onRetryFailed: _retryFailedJobs,
            onClearCompleted: _clearCompletedJobs,
            onCancelJob: _cancelJob,
            onRetryJob: _retryJob,
          ),

          const SizedBox(height: 16.0),

          // Action history
          _buildActionHistory(context),
        ],
      ),
    );
  }

  Widget _buildStorageBreakdown(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            _buildBreakdownItem('Document Pages', '450 MB', 0.6, Colors.blue),
            _buildBreakdownItem('Thumbnails', '120 MB', 0.16, Colors.green),
            _buildBreakdownItem('Text Content', '80 MB', 0.11, Colors.orange),
            _buildBreakdownItem('Metadata', '50 MB', 0.07, Colors.purple),
            _buildBreakdownItem('Other', '50 MB', 0.07, Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownItem(
    String label,
    String size,
    double percentage,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12.0,
            height: 12.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(child: Text(label)),
          Text(
            size,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8.0),
          SizedBox(
            width: 60.0,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheSettings(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            SwitchListTile(
              title: const Text('Auto-cleanup'),
              subtitle: const Text('Automatically remove old cached content'),
              value: true, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update setting
              },
            ),

            SwitchListTile(
              title: const Text('Wi-Fi only downloads'),
              subtitle: const Text('Only download content when on Wi-Fi'),
              value: true, // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update setting
              },
            ),

            ListTile(
              title: const Text('Cache quality'),
              subtitle: const Text('Medium quality (150 DPI)'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _showCacheQualityDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOverview(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.download, color: theme.colorScheme.primary),
                const SizedBox(width: 8.0),
                Text(
                  'Download Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            Row(
              children: [
                Expanded(
                  child: _buildDownloadStat(
                    'Available Offline',
                    '12',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildDownloadStat('Downloading', '2', Colors.orange),
                ),
                Expanded(
                  child: _buildDownloadStat(
                    'Failed',
                    '1',
                    theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadStat(String label, String count, Color color) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12.0),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadedDocumentsList(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Downloaded Documents',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            // Mock downloaded documents
            ..._getMockDownloadedDocuments().map(
              (doc) => OfflineAvailabilityCard(
                documentId: doc['id'],
                documentTitle: doc['title'],
                status: doc['status'],
                progress: doc['progress'],
                cachedPages: doc['cachedPages'],
                totalPages: doc['totalPages'],
                cacheSizeBytes: doc['cacheSizeBytes'],
                lastCached: doc['lastCached'],
                onDownload: () => _downloadDocument(doc['id']),
                onRemove: () => _removeDocument(doc['id']),
                onRetry: () => _retryDownload(doc['id']),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionHistory(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16.0),

            // Mock action history
            ..._getMockActionHistory().map(
              (action) => ListTile(
                leading: Icon(action['icon'], color: action['color']),
                title: Text(action['title']),
                subtitle: Text(action['subtitle']),
                trailing: Text(
                  action['time'],
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Mock data methods (TODO: Replace with real data from providers)
  OfflineStorageStats _getMockStorageStats() {
    return const OfflineStorageStats(
      totalDocuments: 50,
      cachedDocuments: 15,
      totalPages: 2500,
      cachedPages: 750,
      totalSizeBytes: 750 * 1024 * 1024, // 750 MB
      availableSpaceBytes: 2 * 1024 * 1024 * 1024, // 2 GB
      maxCacheSizeBytes: 1024 * 1024 * 1024, // 1 GB
      lastCleanup: null,
    );
  }

  List<Job> _getMockPendingJobs() {
    return [
      Job(
        id: 'job1',
        type: JobType.createBookmark,
        payload: {'documentId': 'doc1', 'pageNumber': 5},
        status: JobStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Job(
        id: 'job2',
        type: JobType.updateReadingProgress,
        payload: {'documentId': 'doc2', 'pageNumber': 10},
        status: JobStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  List<Job> _getMockFailedJobs() {
    return [
      Job(
        id: 'job3',
        type: JobType.createComment,
        payload: {'documentId': 'doc3', 'content': 'Test comment'},
        status: JobStatus.failed,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        attempts: 3,
        lastError: 'Network timeout',
      ),
    ];
  }

  List<Map<String, dynamic>> _getMockDownloadedDocuments() {
    return [
      {
        'id': 'doc1',
        'title': 'Flutter Development Guide',
        'status': OfflineAvailabilityStatus.available,
        'cachedPages': 150,
        'totalPages': 150,
        'cacheSizeBytes': 45 * 1024 * 1024,
        'lastCached': DateTime.now().subtract(const Duration(days: 2)),
      },
      {
        'id': 'doc2',
        'title': 'Dart Programming Language',
        'status': OfflineAvailabilityStatus.downloading,
        'progress': 0.65,
        'cachedPages': 65,
        'totalPages': 100,
        'cacheSizeBytes': 20 * 1024 * 1024,
      },
      {
        'id': 'doc3',
        'title': 'Mobile App Architecture',
        'status': OfflineAvailabilityStatus.failed,
        'cachedPages': 0,
        'totalPages': 200,
      },
    ];
  }

  List<Map<String, dynamic>> _getMockActionHistory() {
    return [
      {
        'icon': Icons.bookmark,
        'color': Colors.blue,
        'title': 'Bookmark created',
        'subtitle': 'Flutter Development Guide - Page 25',
        'time': '2 min ago',
      },
      {
        'icon': Icons.comment,
        'color': Colors.green,
        'title': 'Comment added',
        'subtitle': 'Dart Programming Language - Page 15',
        'time': '5 min ago',
      },
      {
        'icon': Icons.timeline,
        'color': Colors.orange,
        'title': 'Reading progress updated',
        'subtitle': 'Mobile App Architecture - Page 50',
        'time': '10 min ago',
      },
    ];
  }

  // Action methods
  void _cleanupCache() {
    // TODO: Implement cache cleanup
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cache cleanup started...')));
  }

  void _clearAllCache() {
    // TODO: Implement clear all cache
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('All cache cleared')));
  }

  void _manageDocuments() {
    // TODO: Navigate to document management screen
  }

  void _updateCacheLimit(int newLimitBytes) {
    // TODO: Update cache limit setting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cache limit updated to ${_formatBytes(newLimitBytes)}'),
      ),
    );
  }

  void _retryFailedJobs() {
    // TODO: Retry failed jobs
    ref.read(syncActionsProvider.notifier).retryFailedJobs();
  }

  void _clearCompletedJobs() {
    // TODO: Clear completed jobs
    ref.read(syncActionsProvider.notifier).clearOldJobs();
  }

  void _cancelJob(String jobId) {
    // TODO: Cancel specific job
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Job $jobId cancelled')));
  }

  void _retryJob(String jobId) {
    // TODO: Retry specific job
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Job $jobId retried')));
  }

  void _downloadDocument(String documentId) {
    showDialog(
      context: context,
      builder: (context) => DownloadForOfflineDialog(
        documentId: documentId,
        documentTitle: 'Sample Document',
        totalPages: 100,
        onDownload: (options) {
          // TODO: Start download with options
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Download started for $documentId')),
          );
        },
      ),
    );
  }

  void _removeDocument(String documentId) {
    // TODO: Remove document from offline storage
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Document $documentId removed from offline storage'),
      ),
    );
  }

  void _retryDownload(String documentId) {
    // TODO: Retry failed download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Retrying download for $documentId')),
    );
  }

  void _showCacheQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cache Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('High (300 DPI)'),
              subtitle: const Text('Best quality, larger files'),
              value: 'high',
              groupValue: 'medium', // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update setting
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Medium (150 DPI)'),
              subtitle: const Text('Good balance'),
              value: 'medium',
              groupValue: 'medium', // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update setting
                Navigator.of(context).pop();
              },
            ),
            RadioListTile<String>(
              title: const Text('Low (75 DPI)'),
              subtitle: const Text('Smaller files, lower quality'),
              value: 'low',
              groupValue: 'medium', // TODO: Get from settings
              onChanged: (value) {
                // TODO: Update setting
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
