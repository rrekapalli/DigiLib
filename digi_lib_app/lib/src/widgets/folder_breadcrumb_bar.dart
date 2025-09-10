import 'package:flutter/material.dart';

/// Widget for displaying breadcrumb navigation in folder browser
class FolderBreadcrumbBar extends StatelessWidget {
  final List<String> breadcrumbs;
  final Function(String path) onBreadcrumbTap;

  const FolderBreadcrumbBar({
    super.key,
    required this.breadcrumbs,
    required this.onBreadcrumbTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.folder,
            size: 20,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      final path = breadcrumbs[i];
      final isLast = i == breadcrumbs.length - 1;
      final displayName = _getDisplayName(path, i);

      // Add breadcrumb item
      items.add(
        InkWell(
          onTap: isLast ? null : () => onBreadcrumbTap(path),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLast 
                    ? colorScheme.onSurface
                    : colorScheme.primary,
                fontWeight: isLast ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );

      // Add separator (except for last item)
      if (!isLast) {
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        );
      }
    }

    return items;
  }

  String _getDisplayName(String path, int index) {
    if (index == 0) {
      return 'Root'; // Root folder display name
    }
    
    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : 'Root';
  }
}