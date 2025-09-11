import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../providers/share_provider.dart';
import 'permission_restricted_widget.dart';
import 'collaboration_activity_feed.dart';
import 'share_dialog.dart';

class SharedDocumentOverlay extends ConsumerStatefulWidget {
  final String documentId;
  final String documentTitle;
  final String userEmail;
  final VoidCallback? onClose;

  const SharedDocumentOverlay({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.userEmail,
    this.onClose,
  });

  @override
  ConsumerState<SharedDocumentOverlay> createState() =>
      _SharedDocumentOverlayState();
}

class _SharedDocumentOverlayState extends ConsumerState<SharedDocumentOverlay>
    with TickerProviderStateMixin {
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
    final theme = Theme.of(context);
    final sharesAsync = ref.watch(sharesBySubjectProvider(widget.documentId));

    return Container(
      width: 400,
      height: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.people),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Collaboration', style: theme.textTheme.titleMedium),
                      Text(
                        widget.documentTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.onClose != null)
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),

          // Tab bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'People'),
              Tab(text: 'Activity'),
              Tab(text: 'Settings'),
            ],
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPeopleTab(sharesAsync),
                _buildActivityTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleTab(AsyncValue<List<Share>> sharesAsync) {
    return sharesAsync.when(
      data: (shares) => Column(
        children: [
          // Add people button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: PermissionRestrictedWidget(
                subjectId: widget.documentId,
                userEmail: widget.userEmail,
                requiredPermission: SharePermission.full,
                fallback: const SizedBox.shrink(),
                child: ElevatedButton.icon(
                  onPressed: _showShareDialog,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add People'),
                ),
              ),
            ),
          ),

          // Current shares list
          Expanded(
            child: shares.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No one else has access',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: shares.length,
                    itemBuilder: (context, index) {
                      final share = shares[index];
                      return _buildShareListTile(share);
                    },
                  ),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(sharesBySubjectProvider(widget.documentId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CollaborationActivityFeed(
        subjectId: widget.documentId,
        maxItems: 20,
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Collaboration Settings',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),

          // Shared annotation visibility toggle
          SharedAnnotationVisibilityToggle(
            documentId: widget.documentId,
            userEmail: widget.userEmail,
          ),
          const SizedBox(height: 16),

          // Permission-based settings
          PermissionRestrictedWidget(
            subjectId: widget.documentId,
            userEmail: widget.userEmail,
            requiredPermission: SharePermission.full,
            fallback: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.lock, size: 32, color: Colors.grey),
                    const SizedBox(height: 8),
                    Text(
                      'Editor Access Required',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You need editor permissions to change collaboration settings.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  title: const Text('Allow Comments'),
                  subtitle: const Text(
                    'Let viewers add comments to this document',
                  ),
                  value: true, // TODO: Get from document settings
                  onChanged: (value) {
                    // TODO: Update document settings
                  },
                  secondary: const Icon(Icons.comment),
                ),
                SwitchListTile(
                  title: const Text('Allow Downloads'),
                  subtitle: const Text('Let viewers download this document'),
                  value: true, // TODO: Get from document settings
                  onChanged: (value) {
                    // TODO: Update document settings
                  },
                  secondary: const Icon(Icons.download),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Disable Link Sharing'),
                  subtitle: const Text('Remove public access via link'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showDisableLinkSharingDialog,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareListTile(Share share) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(share.granteeEmail?.substring(0, 1).toUpperCase() ?? '?'),
        ),
        title: Text(share.granteeEmail ?? 'Unknown user'),
        subtitle: Text(_getPermissionLabel(share.permission)),
        trailing: PermissionRestrictedWidget(
          subjectId: widget.documentId,
          userEmail: widget.userEmail,
          requiredPermission: SharePermission.full,
          fallback: const SizedBox.shrink(),
          child: PopupMenuButton<String>(
            onSelected: (value) => _handleShareAction(value, share),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'change_permission',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Change Permission'),
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.remove_circle_outline),
                  title: Text('Remove Access'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => ShareDialog(
        subjectId: widget.documentId,
        subjectType: ShareSubjectType.document,
        subjectTitle: widget.documentTitle,
      ),
    );
  }

  void _handleShareAction(String action, Share share) {
    switch (action) {
      case 'change_permission':
        _showChangePermissionDialog(share);
        break;
      case 'remove':
        _showRemoveShareDialog(share);
        break;
    }
  }

  void _showChangePermissionDialog(Share share) {
    SharePermission selectedPermission = share.permission;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Permission'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Change permission for ${share.granteeEmail}'),
              const SizedBox(height: 16),
              RadioGroup<SharePermission>(
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedPermission = value;
                    });
                  }
                },
                child: Column(
                  children: SharePermission.values.map((permission) {
                    return RadioListTile<SharePermission>(
                      title: Text(_getPermissionLabel(permission)),
                      value: permission,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _updateSharePermission(share.id, selectedPermission);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveShareDialog(Share share) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Access'),
        content: Text(
          'Are you sure you want to remove access for ${share.granteeEmail}? '
          'They will no longer be able to access this document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _removeShare(share.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showDisableLinkSharingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Link Sharing'),
        content: const Text(
          'This will disable public access via the share link. '
          'Only people with explicit permissions will be able to access this document.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement disable link sharing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link sharing disabled')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateSharePermission(
    String shareId,
    SharePermission permission,
  ) async {
    try {
      // TODO: Get current user ID from auth provider
      final shareNotifier = ref.read(
        shareNotifierProvider('current-user-id').notifier,
      );
      await shareNotifier.updateSharePermission(shareId, permission);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update permission: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeShare(String shareId) async {
    try {
      // TODO: Get current user ID from auth provider
      final shareNotifier = ref.read(
        shareNotifierProvider('current-user-id').notifier,
      );
      await shareNotifier.deleteShare(shareId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove access: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
