import 'package:flutter/material.dart';

/// Widget that displays offline mode status and limitations
class OfflineModeIndicator extends StatelessWidget {
  final bool isOffline;
  final int? pendingActions;
  final VoidCallback? onTap;
  final bool showBanner;

  const OfflineModeIndicator({
    super.key,
    required this.isOffline,
    this.pendingActions,
    this.onTap,
    this.showBanner = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) {
      return const SizedBox.shrink();
    }

    if (showBanner) {
      return _buildBanner(context);
    } else {
      return _buildIndicator(context);
    }
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);

    return MaterialBanner(
      backgroundColor: Colors.orange.shade50,
      content: Row(
        children: [
          Icon(Icons.cloud_off, color: Colors.orange.shade700, size: 20.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You\'re offline',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _getOfflineMessage(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onTap,
          child: Text(
            'View Details',
            style: TextStyle(color: Colors.orange.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.orange.shade300, width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 16.0, color: Colors.orange.shade700),
            const SizedBox(width: 6.0),
            Text(
              'Offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (pendingActions != null && pendingActions! > 0) ...[
              const SizedBox(width: 4.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Text(
                  '$pendingActions',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getOfflineMessage() {
    if (pendingActions != null && pendingActions! > 0) {
      return 'You have $pendingActions pending actions that will sync when you\'re back online.';
    }
    return 'Some features are limited. Changes will sync when you\'re back online.';
  }
}

/// Widget that shows offline limitations and available features
class OfflineLimitationsCard extends StatelessWidget {
  final int? pendingActions;
  final VoidCallback? onViewPendingActions;

  const OfflineLimitationsCard({
    super.key,
    this.pendingActions,
    this.onViewPendingActions,
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
                  Icons.cloud_off,
                  color: Colors.orange.shade700,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Text(
                  'Offline Mode',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16.0),

            Text(
              'Available Features:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildFeatureList(
              context,
              available: [
                'Browse cached documents',
                'Read downloaded content',
                'Create bookmarks and comments',
                'Search local content',
                'View reading progress',
              ],
            ),

            const SizedBox(height: 16.0),

            Text(
              'Limited Features:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8.0),
            _buildFeatureList(
              context,
              available: [
                'Global search (server-side)',
                'Library scanning',
                'Sharing documents',
                'Cloud synchronization',
                'Account settings',
              ],
              isLimited: true,
            ),

            if (pendingActions != null && pendingActions! > 0) ...[
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 20.0,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          'Pending Actions: $pendingActions',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Your changes are saved locally and will be synchronized when you\'re back online.',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (onViewPendingActions != null) ...[
                      const SizedBox(height: 8.0),
                      TextButton(
                        onPressed: onViewPendingActions,
                        child: const Text('View Pending Actions'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureList(
    BuildContext context, {
    required List<String> available,
    bool isLimited = false,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: available.map((feature) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Row(
            children: [
              Icon(
                isLimited ? Icons.block : Icons.check_circle,
                size: 16.0,
                color: isLimited ? theme.colorScheme.error : Colors.green,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  feature,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLimited
                        ? theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          )
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
