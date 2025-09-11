import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../models/api/create_share_request.dart';
import '../providers/share_provider.dart';

class ShareDialog extends ConsumerStatefulWidget {
  final String subjectId;
  final ShareSubjectType subjectType;
  final String subjectTitle;

  const ShareDialog({
    super.key,
    required this.subjectId,
    required this.subjectType,
    required this.subjectTitle,
  });

  @override
  ConsumerState<ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends ConsumerState<ShareDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  SharePermission _selectedPermission = SharePermission.view;
  bool _isCreatingShare = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existingShares = ref.watch(sharesBySubjectProvider(widget.subjectId));

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.subjectType == ShareSubjectType.document
                      ? Icons.description
                      : Icons.folder,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share ${widget.subjectType.name}',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        widget.subjectTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Add People'),
                Tab(text: 'Manage Access'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAddPeopleTab(),
                  _buildManageAccessTab(existingShares),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPeopleTab() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email input
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email address',
              hintText: 'Enter email to share with',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Permission selection
          Text(
            'Permission Level',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioGroup<SharePermission>(
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedPermission = value;
                });
              }
            },
            child: Column(
              children: SharePermission.values.map((permission) {
                return RadioListTile<SharePermission>(
                  title: Text(_getPermissionTitle(permission)),
                  subtitle: Text(_getPermissionDescription(permission)),
                  value: permission,
                );
              }).toList(),
            ),
          ),
          const Spacer(),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isCreatingShare ? null : _createShare,
                child: _isCreatingShare
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Share'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManageAccessTab(AsyncValue<List<Share>> existingShares) {
    return existingShares.when(
      data: (shares) {
        if (shares.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No shares yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Use the "Add People" tab to share this item',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Share link section
            _buildShareLinkSection(),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Existing shares list
            Expanded(
              child: ListView.builder(
                itemCount: shares.length,
                itemBuilder: (context, index) {
                  final share = shares[index];
                  return _buildShareListTile(share);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading shares: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(sharesBySubjectProvider(widget.subjectId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareLinkSection() {
    final shareLink = 'https://app.example.com/shared/${widget.subjectId}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Text(
                  'Share Link',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      shareLink,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _copyShareLink(shareLink),
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy link',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anyone with this link can view this ${widget.subjectType.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareListTile(Share share) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(share.granteeEmail?.substring(0, 1).toUpperCase() ?? '?'),
      ),
      title: Text(share.granteeEmail ?? 'Unknown user'),
      subtitle: Text(_getPermissionTitle(share.permission)),
      trailing: PopupMenuButton<String>(
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
    );
  }

  String _getPermissionTitle(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Viewer';
      case SharePermission.comment:
        return 'Commenter';
      case SharePermission.full:
        return 'Editor';
    }
  }

  String _getPermissionDescription(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'Can view and download';
      case SharePermission.comment:
        return 'Can view, comment, and download';
      case SharePermission.full:
        return 'Can view, comment, edit, and share';
    }
  }

  Future<void> _createShare() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCreatingShare = true;
    });

    try {
      final request = CreateShareRequest(
        subjectId: widget.subjectId,
        subjectType: widget.subjectType,
        granteeEmail: _emailController.text.trim(),
        permission: _selectedPermission,
      );

      // TODO: Get current user ID from auth provider
      final shareNotifier = ref.read(
        shareNotifierProvider('current-user-id').notifier,
      );
      await shareNotifier.createShare(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Shared with ${_emailController.text}'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form and switch to manage tab
        _emailController.clear();
        _selectedPermission = SharePermission.view;
        _tabController.animateTo(1);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create share: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingShare = false;
        });
      }
    }
  }

  Future<void> _copyShareLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share link copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
                      title: Text(_getPermissionTitle(permission)),
                      subtitle: Text(_getPermissionDescription(permission)),
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
          'They will no longer be able to access this ${widget.subjectType.name}.',
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
