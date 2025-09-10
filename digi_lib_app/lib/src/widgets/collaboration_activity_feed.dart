import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../models/ui/share_event.dart';
import '../providers/share_provider.dart';

enum ActivityType {
  shareCreated,
  shareUpdated,
  shareRevoked,
  commentAdded,
  bookmarkAdded,
  documentViewed,
}

class ActivityItem {
  final String id;
  final ActivityType type;
  final String userId;
  final String userEmail;
  final String subjectId;
  final ShareSubjectType subjectType;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime timestamp;

  const ActivityItem({
    required this.id,
    required this.type,
    required this.userId,
    required this.userEmail,
    required this.subjectId,
    required this.subjectType,
    this.description,
    this.metadata,
    required this.timestamp,
  });
}

class CollaborationActivityFeed extends ConsumerStatefulWidget {
  final String? subjectId; // If null, shows all activities
  final int maxItems;

  const CollaborationActivityFeed({
    super.key,
    this.subjectId,
    this.maxItems = 50,
  });

  @override
  ConsumerState<CollaborationActivityFeed> createState() =>
      _CollaborationActivityFeedState();
}

class _CollaborationActivityFeedState
    extends ConsumerState<CollaborationActivityFeed> {
  @override
  Widget build(BuildContext context) {
    // Listen to share events to build activity feed
    final shareEventsAsync = ref.watch(shareEventsProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.timeline),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _showFullActivityFeed,
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: shareEventsAsync.when(
              data: (event) =>
                  _buildActivityList([_convertShareEventToActivity(event)]),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => _buildErrorState(error.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<ActivityItem> activities) {
    if (activities.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timeline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No recent activity', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityTile(activity);
      },
    );
  }

  Widget _buildActivityTile(ActivityItem activity) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActivityColor(
          activity.type,
        ).withValues(alpha: 0.1),
        child: Icon(
          _getActivityIcon(activity.type),
          color: _getActivityColor(activity.type),
          size: 20,
        ),
      ),
      title: Text(_getActivityTitle(activity)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (activity.description != null) Text(activity.description!),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                activity.subjectType == ShareSubjectType.document
                    ? Icons.description
                    : Icons.folder,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _getSubjectTitle(activity.subjectId),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(activity.timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _handleActivityTap(activity),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Error loading activity'),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  ActivityItem _convertShareEventToActivity(ShareEvent event) {
    ActivityType activityType;
    String description;

    switch (event.type) {
      case ShareEventType.created:
        activityType = ActivityType.shareCreated;
        description = 'Shared with ${event.share.granteeEmail}';
        break;
      case ShareEventType.updated:
        activityType = ActivityType.shareUpdated;
        description = 'Updated permissions for ${event.share.granteeEmail}';
        break;
      case ShareEventType.deleted:
        activityType = ActivityType.shareRevoked;
        description = 'Revoked access for ${event.share.granteeEmail}';
        break;
      case ShareEventType.permissionChanged:
        activityType = ActivityType.shareUpdated;
        description = 'Changed permissions for ${event.share.granteeEmail}';
        break;
      case ShareEventType.error:
        activityType = ActivityType.shareUpdated; // Use updated as fallback
        description = 'Share operation failed for ${event.share.granteeEmail}';
        break;
    }

    return ActivityItem(
      id: event.share.id,
      type: activityType,
      userId: event.share.ownerId,
      userEmail: event.share.granteeEmail ?? 'Unknown',
      subjectId: event.share.subjectId,
      subjectType: event.share.subjectType,
      description: description,
      timestamp: event.timestamp,
    );
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.shareCreated:
        return Icons.person_add;
      case ActivityType.shareUpdated:
        return Icons.edit;
      case ActivityType.shareRevoked:
        return Icons.person_remove;
      case ActivityType.commentAdded:
        return Icons.comment;
      case ActivityType.bookmarkAdded:
        return Icons.bookmark_add;
      case ActivityType.documentViewed:
        return Icons.visibility;
    }
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.shareCreated:
        return Colors.green;
      case ActivityType.shareUpdated:
        return Colors.blue;
      case ActivityType.shareRevoked:
        return Colors.red;
      case ActivityType.commentAdded:
        return Colors.orange;
      case ActivityType.bookmarkAdded:
        return Colors.purple;
      case ActivityType.documentViewed:
        return Colors.grey;
    }
  }

  String _getActivityTitle(ActivityItem activity) {
    switch (activity.type) {
      case ActivityType.shareCreated:
        return 'New share created';
      case ActivityType.shareUpdated:
        return 'Share permissions updated';
      case ActivityType.shareRevoked:
        return 'Share access revoked';
      case ActivityType.commentAdded:
        return 'Comment added';
      case ActivityType.bookmarkAdded:
        return 'Bookmark added';
      case ActivityType.documentViewed:
        return 'Document viewed';
    }
  }

  String _getSubjectTitle(String subjectId) {
    // TODO: Fetch actual subject title from document/folder service
    return 'Item ${subjectId.substring(0, 8)}...';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

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

  void _handleActivityTap(ActivityItem activity) {
    // TODO: Navigate to the relevant item or show details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Opening ${activity.subjectType.name} ${activity.subjectId}',
        ),
      ),
    );
  }

  void _showFullActivityFeed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const FullActivityFeedScreen()),
    );
  }
}

class FullActivityFeedScreen extends ConsumerWidget {
  const FullActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Feed'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implement activity filtering
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: const CollaborationActivityFeed(maxItems: 100),
    );
  }
}

class ActivityFilterDialog extends StatefulWidget {
  final Set<ActivityType> selectedTypes;
  final DateTimeRange? dateRange;

  const ActivityFilterDialog({
    super.key,
    required this.selectedTypes,
    this.dateRange,
  });

  @override
  State<ActivityFilterDialog> createState() => _ActivityFilterDialogState();
}

class _ActivityFilterDialogState extends State<ActivityFilterDialog> {
  late Set<ActivityType> _selectedTypes;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedTypes = Set.from(widget.selectedTypes);
    _dateRange = widget.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Activity'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Types',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...ActivityType.values.map((type) {
              return CheckboxListTile(
                title: Text(_getActivityTypeLabel(type)),
                value: _selectedTypes.contains(type),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedTypes.add(type);
                    } else {
                      _selectedTypes.remove(type);
                    }
                  });
                },
              );
            }),
            const SizedBox(height: 16),
            Text('Date Range', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                _dateRange == null
                    ? 'All time'
                    : '${_dateRange!.start.day}/${_dateRange!.start.month} - ${_dateRange!.end.day}/${_dateRange!.end.month}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDateRange,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _selectedTypes.clear();
              _selectedTypes.addAll(ActivityType.values);
              _dateRange = null;
            });
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop({'types': _selectedTypes, 'dateRange': _dateRange});
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  String _getActivityTypeLabel(ActivityType type) {
    switch (type) {
      case ActivityType.shareCreated:
        return 'Shares Created';
      case ActivityType.shareUpdated:
        return 'Shares Updated';
      case ActivityType.shareRevoked:
        return 'Shares Revoked';
      case ActivityType.commentAdded:
        return 'Comments Added';
      case ActivityType.bookmarkAdded:
        return 'Bookmarks Added';
      case ActivityType.documentViewed:
        return 'Documents Viewed';
    }
  }

  Future<void> _selectDateRange() async {
    final dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (dateRange != null) {
      setState(() {
        _dateRange = dateRange;
      });
    }
  }
}
