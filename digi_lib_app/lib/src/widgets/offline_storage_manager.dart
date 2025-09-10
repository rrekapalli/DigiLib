import 'package:flutter/material.dart';

/// Model for offline storage statistics
class OfflineStorageStats {
  final int totalDocuments;
  final int cachedDocuments;
  final int totalPages;
  final int cachedPages;
  final int totalSizeBytes;
  final int availableSpaceBytes;
  final int maxCacheSizeBytes;
  final DateTime? lastCleanup;

  const OfflineStorageStats({
    required this.totalDocuments,
    required this.cachedDocuments,
    required this.totalPages,
    required this.cachedPages,
    required this.totalSizeBytes,
    required this.availableSpaceBytes,
    required this.maxCacheSizeBytes,
    this.lastCleanup,
  });

  double get cacheUsagePercentage => 
      maxCacheSizeBytes > 0 ? (totalSizeBytes / maxCacheSizeBytes) : 0.0;

  double get documentCachePercentage =>
      totalDocuments > 0 ? (cachedDocuments / totalDocuments) : 0.0;

  double get pageCachePercentage =>
      totalPages > 0 ? (cachedPages / totalPages) : 0.0;

  bool get isNearLimit => cacheUsagePercentage > 0.8;
  bool get isAtLimit => cacheUsagePercentage > 0.95;
}

/// Widget for managing offline storage and cache
class OfflineStorageManager extends StatelessWidget {
  final OfflineStorageStats stats;
  final VoidCallback? onCleanupCache;
  final VoidCallback? onClearAllCache;
  final VoidCallback? onManageDocuments;
  final Function(int newLimitBytes)? onUpdateCacheLimit;

  const OfflineStorageManager({
    super.key,
    required this.stats,
    this.onCleanupCache,
    this.onClearAllCache,
    this.onManageDocuments,
    this.onUpdateCacheLimit,
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
                  Icons.storage,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8.0),
                Text(
                  'Offline Storage',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16.0),
            
            // Storage usage overview
            _buildStorageOverview(context),
            
            const SizedBox(height: 16.0),
            
            // Cache statistics
            _buildCacheStatistics(context),
            
            const SizedBox(height: 16.0),
            
            // Storage actions
            _buildStorageActions(context),
            
            if (stats.isNearLimit) ...[
              const SizedBox(height: 16.0),
              _buildStorageWarning(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStorageOverview(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Usage',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8.0),
        
        // Storage usage bar
        Container(
          height: 8.0,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: stats.cacheUsagePercentage.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getUsageColor(theme),
                borderRadius: BorderRadius.circular(4.0),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8.0),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_formatBytes(stats.totalSizeBytes)} used',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '${_formatBytes(stats.maxCacheSizeBytes)} limit',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCacheStatistics(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cache Statistics',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Documents',
                '${stats.cachedDocuments}/${stats.totalDocuments}',
                stats.documentCachePercentage,
                Icons.description,
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: _buildStatCard(
                context,
                'Pages',
                '${stats.cachedPages}/${stats.totalPages}',
                stats.pageCachePercentage,
                Icons.pages,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12.0),
        
        if (stats.lastCleanup != null)
          Text(
            'Last cleanup: ${_formatDateTime(stats.lastCleanup!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    double percentage,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24.0,
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4.0),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageActions(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Actions',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            if (onCleanupCache != null)
              ElevatedButton.icon(
                onPressed: onCleanupCache,
                icon: const Icon(Icons.cleaning_services),
                label: const Text('Clean Up'),
              ),
            
            if (onManageDocuments != null)
              OutlinedButton.icon(
                onPressed: onManageDocuments,
                icon: const Icon(Icons.manage_accounts),
                label: const Text('Manage'),
              ),
            
            OutlinedButton.icon(
              onPressed: () => _showCacheLimitDialog(context),
              icon: const Icon(Icons.settings),
              label: const Text('Settings'),
            ),
            
            if (onClearAllCache != null)
              OutlinedButton.icon(
                onPressed: () => _showClearAllConfirmation(context),
                icon: const Icon(Icons.delete_sweep),
                label: const Text('Clear All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStorageWarning(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: stats.isAtLimit 
            ? theme.colorScheme.errorContainer.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: stats.isAtLimit 
              ? theme.colorScheme.error.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            stats.isAtLimit ? Icons.error : Icons.warning,
            color: stats.isAtLimit ? theme.colorScheme.error : Colors.orange,
            size: 20.0,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.isAtLimit ? 'Storage Limit Reached' : 'Storage Nearly Full',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: stats.isAtLimit ? theme.colorScheme.error : Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  stats.isAtLimit 
                      ? 'Clear some cached content to free up space.'
                      : 'Consider cleaning up cached content or increasing the storage limit.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: stats.isAtLimit ? theme.colorScheme.error : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getUsageColor(ThemeData theme) {
    if (stats.isAtLimit) return theme.colorScheme.error;
    if (stats.isNearLimit) return Colors.orange;
    return theme.colorScheme.primary;
  }

  void _showCacheLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CacheLimitDialog(
        currentLimit: stats.maxCacheSizeBytes,
        onUpdateLimit: onUpdateCacheLimit,
      ),
    );
  }

  void _showClearAllConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Cache'),
        content: const Text(
          'This will remove all cached documents and pages. '
          'You will need to re-download content for offline access.\n\n'
          'Are you sure you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onClearAllCache?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
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

/// Dialog for setting cache size limit
class _CacheLimitDialog extends StatefulWidget {
  final int currentLimit;
  final Function(int newLimit)? onUpdateLimit;

  const _CacheLimitDialog({
    required this.currentLimit,
    this.onUpdateLimit,
  });

  @override
  State<_CacheLimitDialog> createState() => _CacheLimitDialogState();
}

class _CacheLimitDialogState extends State<_CacheLimitDialog> {
  late double _selectedLimit;
  final List<int> _presetLimits = [
    100 * 1024 * 1024,    // 100 MB
    500 * 1024 * 1024,    // 500 MB
    1024 * 1024 * 1024,   // 1 GB
    2 * 1024 * 1024 * 1024, // 2 GB
    5 * 1024 * 1024 * 1024, // 5 GB
  ];

  @override
  void initState() {
    super.initState();
    _selectedLimit = widget.currentLimit.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: const Text('Cache Size Limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set the maximum amount of storage to use for offline content.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16.0),
          
          Text(
            'Current limit: ${_formatBytes(_selectedLimit.toInt())}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16.0),
          
          // Preset options
          Text(
            'Quick Options:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          
          Wrap(
            spacing: 8.0,
            children: _presetLimits.map((limit) {
              return ChoiceChip(
                label: Text(_formatBytes(limit)),
                selected: _selectedLimit.toInt() == limit,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedLimit = limit.toDouble();
                    });
                  }
                },
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16.0),
          
          // Custom slider
          Text(
            'Custom Size:',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Slider(
            value: _selectedLimit,
            min: 50 * 1024 * 1024, // 50 MB minimum
            max: 10 * 1024 * 1024 * 1024, // 10 GB maximum
            divisions: 100,
            onChanged: (value) {
              setState(() {
                _selectedLimit = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onUpdateLimit?.call(_selectedLimit.toInt());
            Navigator.of(context).pop();
          },
          child: const Text('Update'),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}