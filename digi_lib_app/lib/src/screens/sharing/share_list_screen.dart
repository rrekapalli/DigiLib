import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/entities/share.dart';
import '../../providers/share_provider.dart';
import '../../widgets/share_dialog.dart';

class ShareListScreen extends ConsumerStatefulWidget {
  const ShareListScreen({super.key});

  @override
  ConsumerState<ShareListScreen> createState() => _ShareListScreenState();
}

class _ShareListScreenState extends ConsumerState<ShareListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharing & Collaboration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.share), text: 'My Shares'),
            Tab(icon: Icon(Icons.people), text: 'Shared with Me'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildMySharesTab(), _buildSharedWithMeTab()],
      ),
    );
  }

  Widget _buildMySharesTab() {
    // TODO: Get current user ID from auth provider
    final sharesAsync = ref.watch(shareNotifierProvider('current-user-id'));

    return sharesAsync.when(
      data: (shares) {
        if (shares.isEmpty) {
          return _buildEmptyState(
            icon: Icons.share_outlined,
            title: 'No shares yet',
            subtitle: 'Documents and folders you share will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref
                .read(shareNotifierProvider('current-user-id').notifier)
                .refresh();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shares.length,
            itemBuilder: (context, index) {
              final share = shares[index];
              return _buildShareCard(share, isOwner: true);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () => ref
            .read(shareNotifierProvider('current-user-id').notifier)
            .refresh(),
      ),
    );
  }

  Widget _buildSharedWithMeTab() {
    final sharedWithMeAsync = ref.watch(sharedWithMeProvider);

    return sharedWithMeAsync.when(
      data: (shares) {
        if (shares.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            title: 'Nothing shared with you',
            subtitle: 'Documents and folders shared with you will appear here',
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.refresh(sharedWithMeProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shares.length,
            itemBuilder: (context, index) {
              final share = shares[index];
              return _buildShareCard(share, isOwner: false);
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(
        error: error.toString(),
        onRetry: () => ref.refresh(sharedWithMeProvider),
      ),
    );
  }

  Widget _buildShareCard(Share share, {required bool isOwner}) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openSharedItem(share),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Subject type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      share.subjectType == ShareSubjectType.document
                          ? Icons.description
                          : Icons.folder,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Subject info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSubjectTitle(share),
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          share.subjectType.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Permission badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPermissionColor(
                        share.permission,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getPermissionColor(
                          share.permission,
                        ).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      _getPermissionLabel(share.permission),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _getPermissionColor(share.permission),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Actions menu
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleShareAction(value, share),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'manage',
                          child: ListTile(
                            leading: Icon(Icons.settings),
                            title: Text('Manage Access'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'copy_link',
                          child: ListTile(
                            leading: Icon(Icons.link),
                            title: Text('Copy Link'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'revoke',
                          child: ListTile(
                            leading: Icon(Icons.remove_circle_outline),
                            title: Text('Revoke Access'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Share details
              Row(
                children: [
                  if (isOwner) ...[
                    Icon(
                      Icons.person_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Shared with ${share.granteeEmail}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.person,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Shared by owner',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(share.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState({
    required String error,
    required VoidCallback onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error loading shares',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  String _getSubjectTitle(Share share) {
    // TODO: Fetch actual subject title from document/folder service
    return 'Subject ${share.subjectId.substring(0, 8)}...';
  }

  String _getPermissionLabel(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Viewer';
      case SharePermission.comment:
        return 'Commenter';
      case SharePermission.full:
        return 'Editor';
    }
  }

  Color _getPermissionColor(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return Colors.blue;
      case SharePermission.comment:
        return Colors.orange;
      case SharePermission.full:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _openSharedItem(Share share) {
    // TODO: Navigate to the shared document or folder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${share.subjectType.name} ${share.subjectId}'),
      ),
    );
  }

  void _handleShareAction(String action, Share share) {
    switch (action) {
      case 'manage':
        _showManageShareDialog(share);
        break;
      case 'copy_link':
        _copyShareLink(share);
        break;
      case 'revoke':
        _revokeShare(share);
        break;
    }
  }

  void _showManageShareDialog(Share share) {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        subjectId: share.subjectId,
        subjectType: share.subjectType,
        subjectTitle: _getSubjectTitle(share),
      ),
    );
  }

  void _copyShareLink(Share share) {
    // TODO: Generate and copy actual share link
    final link = 'https://app.example.com/shared/${share.subjectId}';

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share link copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _revokeShare(Share share) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Access'),
        content: Text(
          'Are you sure you want to revoke access for ${share.granteeEmail}? '
          'They will no longer be able to access this ${share.subjectType.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              try {
                // TODO: Get current user ID from auth provider
                final shareNotifier = ref.read(
                  shareNotifierProvider('current-user-id').notifier,
                );
                await shareNotifier.deleteShare(share.id);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Access revoked successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to revoke access: $error'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
