import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/entities/bookmark.dart';

/// List tile widget for displaying bookmark information
class BookmarkListTile extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool compact;
  final bool showSyncStatus;

  const BookmarkListTile({
    super.key,
    required this.bookmark,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.compact = false,
    this.showSyncStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 16,
        vertical: compact ? 2 : 4,
      ),
      elevation: compact ? 1 : 2,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 4 : 8,
        ),
        leading: _buildLeading(context),
        title: _buildTitle(context),
        subtitle: _buildSubtitle(context),
        trailing: _buildTrailing(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Container(
      width: compact ? 32 : 40,
      height: compact ? 32 : 40,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
      ),
      child: Center(
        child: Text(
          '${bookmark.pageNumber ?? '?'}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 12 : 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Page ${bookmark.pageNumber ?? 'Unknown'}',
            style: compact
                ? Theme.of(context).textTheme.bodyMedium
                : Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (showSyncStatus) _buildSyncStatusIcon(context),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final hasNote = bookmark.note != null && bookmark.note!.isNotEmpty;
    final createdAt = DateFormat.yMMMd().add_jm().format(bookmark.createdAt);

    if (!hasNote && compact) {
      return Text(
        createdAt,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasNote) ...[
          Text(
            bookmark.note!,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
        ],
        Text(
          createdAt,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (compact) {
      return const Icon(Icons.chevron_right);
    }

    if (onEdit != null || onDelete != null) {
      return PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'edit':
              onEdit?.call();
              break;
            case 'delete':
              onDelete?.call();
              break;
          }
        },
        itemBuilder: (context) => [
          if (onEdit != null)
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      );
    }

    return null;
  }

  Widget _buildSyncStatusIcon(BuildContext context) {
    // TODO: Implement actual sync status checking
    // For now, show a placeholder icon
    return Tooltip(
      message: 'Synced',
      child: Icon(
        Icons.cloud_done,
        size: 16,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

/// Compact bookmark chip for inline display
class BookmarkChip extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const BookmarkChip({
    super.key,
    required this.bookmark,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (onDelete != null) {
      return InputChip(
        avatar: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          radius: 12,
          child: Text(
            '${bookmark.pageNumber ?? '?'}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        label: Text(
          bookmark.note?.isNotEmpty == true
              ? bookmark.note!
              : 'Page ${bookmark.pageNumber ?? 'Unknown'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDelete,
      );
    } else {
      return ActionChip(
        avatar: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          radius: 12,
          child: Text(
            '${bookmark.pageNumber ?? '?'}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        label: Text(
          bookmark.note?.isNotEmpty == true
              ? bookmark.note!
              : 'Page ${bookmark.pageNumber ?? 'Unknown'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onPressed: onTap,
      );
    }
  }
}

/// Grid item for bookmark display in grid view
class BookmarkGridItem extends StatelessWidget {
  final Bookmark bookmark;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const BookmarkGridItem({
    super.key,
    required this.bookmark,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with page number and menu
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Page ${bookmark.pageNumber ?? '?'}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (onEdit != null || onDelete != null)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        if (onDelete != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete),
                              title: Text('Delete'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                      ],
                      child: const Icon(Icons.more_vert),
                    ),
                ],
              ),

              const SizedBox(height: 8),

              // Note content
              Expanded(
                child: bookmark.note?.isNotEmpty == true
                    ? Text(
                        bookmark.note!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'No note',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),

              const SizedBox(height: 8),

              // Created date
              Text(
                DateFormat.yMMMd().format(bookmark.createdAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
