import 'package:flutter/material.dart';
import '../models/entities/saved_search.dart';
import '../utils/constants.dart';

/// Tile widget for displaying a saved search
class SavedSearchTile extends StatelessWidget {
  final SavedSearch savedSearch;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const SavedSearchTile({
    super.key,
    required this.savedSearch,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      savedSearch.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleMenuAction(value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    child: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Query
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        savedSearch.query,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Filters (if any)
              if (savedSearch.filters != null && savedSearch.filters!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildFiltersDisplay(context),
              ],

              const SizedBox(height: 12),

              // Metadata row
              Row(
                children: [
                  // Usage stats
                  if (savedSearch.useCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Used ${savedSearch.useCount} times',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],

                  // Last used
                  if (savedSearch.lastUsedAt != null) ...[
                    Text(
                      'Last used ${_formatDate(savedSearch.lastUsedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Never used',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Created date
                  Text(
                    'Created ${_formatDate(savedSearch.createdAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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

  Widget _buildFiltersDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filters = savedSearch.filters!;

    final filterChips = <Widget>[];

    // Library filter
    if (filters['library_id'] != null) {
      filterChips.add(_buildFilterChip(
        context,
        'Library',
        Icons.folder,
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ));
    }

    // Tags filter
    final tags = filters['tags'] as List<dynamic>?;
    if (tags != null && tags.isNotEmpty) {
      filterChips.add(_buildFilterChip(
        context,
        '${tags.length} tags',
        Icons.label,
        colorScheme.tertiaryContainer,
        colorScheme.onTertiaryContainer,
      ));
    }

    // File types filter
    final fileTypes = filters['file_types'] as List<dynamic>?;
    if (fileTypes != null && fileTypes.isNotEmpty) {
      filterChips.add(_buildFilterChip(
        context,
        fileTypes.join(', ').toUpperCase(),
        Icons.description,
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ));
    }

    // Date range filter
    if (filters['date_from'] != null || filters['date_to'] != null) {
      filterChips.add(_buildFilterChip(
        context,
        'Date range',
        Icons.date_range,
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ));
    }

    if (filterChips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: filterChips,
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    IconData icon,
    Color backgroundColor,
    Color textColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}