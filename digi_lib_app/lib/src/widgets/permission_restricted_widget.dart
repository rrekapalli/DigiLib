import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/share.dart';
import '../providers/share_provider.dart';

class PermissionRestrictedWidget extends ConsumerWidget {
  final String subjectId;
  final String userEmail;
  final SharePermission requiredPermission;
  final Widget child;
  final Widget? fallback;
  final bool showFallbackMessage;

  const PermissionRestrictedWidget({
    super.key,
    required this.subjectId,
    required this.userEmail,
    required this.requiredPermission,
    required this.child,
    this.fallback,
    this.showFallbackMessage = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(
      sharePermissionProvider((subjectId: subjectId, userEmail: userEmail)),
    );

    return permissionAsync.when(
      data: (userPermission) {
        if (_hasPermission(userPermission, requiredPermission)) {
          return child;
        }

        return fallback ?? _buildDefaultFallback(context);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => fallback ?? _buildDefaultFallback(context),
    );
  }

  bool _hasPermission(
    SharePermission? userPermission,
    SharePermission required,
  ) {
    if (userPermission == null) return false;

    // Permission hierarchy: full > comment > view
    switch (required) {
      case SharePermission.view:
        return true; // All permissions include view
      case SharePermission.comment:
        return userPermission == SharePermission.comment ||
            userPermission == SharePermission.full;
      case SharePermission.full:
        return userPermission == SharePermission.full;
    }
  }

  Widget _buildDefaultFallback(BuildContext context) {
    if (!showFallbackMessage) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            _getPermissionMessage(requiredPermission),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _getPermissionMessage(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'View access required';
      case SharePermission.comment:
        return 'Comment access required';
      case SharePermission.full:
        return 'Edit access required';
    }
  }
}

class ConditionalActionButton extends ConsumerWidget {
  final String subjectId;
  final String userEmail;
  final SharePermission requiredPermission;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;

  const ConditionalActionButton({
    super.key,
    required this.subjectId,
    required this.userEmail,
    required this.requiredPermission,
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissionAsync = ref.watch(
      sharePermissionProvider((subjectId: subjectId, userEmail: userEmail)),
    );

    return permissionAsync.when(
      data: (userPermission) {
        final hasPermission = _hasPermission(
          userPermission,
          requiredPermission,
        );

        return Tooltip(
          message:
              tooltip ??
              (hasPermission
                  ? ''
                  : 'Requires ${_getPermissionLabel(requiredPermission)} permission'),
          child: ElevatedButton(
            onPressed: hasPermission ? onPressed : null,
            child: child,
          ),
        );
      },
      loading: () => ElevatedButton(onPressed: null, child: child),
      error: (_, __) => ElevatedButton(onPressed: null, child: child),
    );
  }

  bool _hasPermission(
    SharePermission? userPermission,
    SharePermission required,
  ) {
    if (userPermission == null) return false;

    switch (required) {
      case SharePermission.view:
        return true;
      case SharePermission.comment:
        return userPermission == SharePermission.comment ||
            userPermission == SharePermission.full;
      case SharePermission.full:
        return userPermission == SharePermission.full;
    }
  }

  String _getPermissionLabel(SharePermission permission) {
    switch (permission) {
      case SharePermission.view:
        return 'view';
      case SharePermission.comment:
        return 'comment';
      case SharePermission.full:
        return 'edit';
    }
  }
}

class SharedAnnotationVisibilityToggle extends ConsumerStatefulWidget {
  final String documentId;
  final String userEmail;

  const SharedAnnotationVisibilityToggle({
    super.key,
    required this.documentId,
    required this.userEmail,
  });

  @override
  ConsumerState<SharedAnnotationVisibilityToggle> createState() =>
      _SharedAnnotationVisibilityToggleState();
}

class _SharedAnnotationVisibilityToggleState
    extends ConsumerState<SharedAnnotationVisibilityToggle> {
  bool _showSharedAnnotations = true;

  @override
  Widget build(BuildContext context) {
    final isSharedAsync = ref.watch(
      isSharedProvider((
        subjectId: widget.documentId,
        userEmail: widget.userEmail,
      )),
    );

    return isSharedAsync.when(
      data: (isShared) {
        if (!isShared) {
          return const SizedBox.shrink();
        }

        return SwitchListTile(
          title: const Text('Show Shared Annotations'),
          subtitle: const Text(
            'Display comments and bookmarks from other users',
          ),
          value: _showSharedAnnotations,
          onChanged: (value) {
            setState(() {
              _showSharedAnnotations = value;
            });
            // TODO: Update annotation visibility in reader
          },
          secondary: const Icon(Icons.visibility),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class CollaborationStatusBar extends ConsumerWidget {
  final String subjectId;
  final String userEmail;

  const CollaborationStatusBar({
    super.key,
    required this.subjectId,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharesCountAsync = ref.watch(sharesCountProvider(subjectId));
    final permissionAsync = ref.watch(
      sharePermissionProvider((subjectId: subjectId, userEmail: userEmail)),
    );
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          sharesCountAsync.when(
            data: (count) {
              if (count == 0) {
                return const Row(
                  children: [
                    Icon(Icons.lock, size: 16),
                    SizedBox(width: 4),
                    Text('Private'),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(Icons.people, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Shared with $count ${count == 1 ? 'person' : 'people'}',
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Spacer(),
          permissionAsync.when(
            data: (permission) {
              if (permission == null) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getPermissionColor(permission).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPermissionColor(
                      permission,
                    ).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Your access: ${_getPermissionLabel(permission)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _getPermissionColor(permission),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
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
