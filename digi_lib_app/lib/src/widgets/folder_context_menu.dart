import 'package:flutter/material.dart';
import '../models/entities/folder_node.dart';

/// Context menu widget for folder and document actions
class FolderContextMenu extends StatelessWidget {
  final FolderNode node;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onAddTag;
  final VoidCallback onViewDetails;

  const FolderContextMenu({
    super.key,
    required this.node,
    required this.onRename,
    required this.onDelete,
    required this.onShare,
    required this.onAddTag,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  node.isFolder ? Icons.folder : Icons.insert_drive_file,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        node.isFolder ? 'Folder' : 'Document',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Actions
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('View Details'),
            onTap: () {
              Navigator.pop(context);
              onViewDetails();
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Rename'),
            onTap: () {
              Navigator.pop(context);
              onRename();
            },
          ),
          
          if (!node.isFolder) ...[
            ListTile(
              leading: const Icon(Icons.label_outline),
              title: const Text('Add Tags'),
              onTap: () {
                Navigator.pop(context);
                onAddTag();
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                onShare();
              },
            ),
          ],
          
          const Divider(),
          
          ListTile(
            leading: Icon(
              Icons.delete_outline,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(
                color: theme.colorScheme.error,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete();
            },
          ),
        ],
      ),
    );
  }
}