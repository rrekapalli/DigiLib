import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../providers/share_provider.dart';

class ShareIndicator extends ConsumerWidget {
  final String subjectId;
  final bool showCount;
  final double size;

  const ShareIndicator({
    super.key,
    required this.subjectId,
    this.showCount = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesCountAsync = ref.watch(sharesCountProvider(subjectId));
    final theme = Theme.of(context);

    return sharesCountAsync.when(
      data: (count) {
        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: showCount ? 6 : 4,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people,
                size: size,
                color: theme.colorScheme.onPrimaryContainer,
              ),
              if (showCount && count > 1) ...[
                const SizedBox(width: 2),
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: size * 0.75,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class SharePermissionBadge extends StatelessWidget {
  final SharePermission permission;
  final double size;

  const SharePermissionBadge({
    super.key,
    required this.permission,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getPermissionColor(permission);
    final label = _getPermissionLabel(permission);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.5,
        vertical: size * 0.25,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(size * 0.75),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  String _getPermissionLabel(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'View';
      case SharePermission.comment:
        return 'Comment';
      case SharePermission.full:
        return 'Edit';
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
}

class SharedDocumentIndicator extends ConsumerWidget {
  final String documentId;
  final String userEmail;

  const SharedDocumentIndicator({
    super.key,
    required this.documentId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(sharePermissionProvider((
      subjectId: documentId,
      userEmail: userEmail,
    )));

    return permissionAsync.when(
      data: (permission) {
        if (permission == null) {
          return const SizedBox.shrink();
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.share,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 4),
            SharePermissionBadge(
              permission: permission,
              size: 10,
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class ShareStatusChip extends ConsumerWidget {
  final String subjectId;
  final VoidCallback? onTap;

  const ShareStatusChip({
    super.key,
    required this.subjectId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesCountAsync = ref.watch(sharesCountProvider(subjectId));
    final theme = Theme.of(context);

    return sharesCountAsync.when(
      data: (count) {
        if (count == 0) {
          return ActionChip(
            avatar: const Icon(Icons.share, size: 16),
            label: const Text('Share'),
            onPressed: onTap,
          );
        }

        return ActionChip(
          avatar: const Icon(Icons.people, size: 16),
          label: Text('Shared ($count)'),
          backgroundColor: theme.colorScheme.primaryContainer,
          onPressed: onTap,
        );
      },
      loading: () => ActionChip(
        avatar: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        label: const Text('Share'),
        onPressed: null,
      ),
      error: (_, __) => ActionChip(
        avatar: const Icon(Icons.share, size: 16),
        label: const Text('Share'),
        onPressed: onTap,
      ),
    );
  }
}