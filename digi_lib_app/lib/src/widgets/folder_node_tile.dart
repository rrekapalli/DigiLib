import 'package:flutter/material.dart';
import '../models/entities/folder_node.dart';
import '../utils/file_utils.dart';

/// Widget for displaying a folder or document node in the browser
class FolderNodeTile extends StatelessWidget {
  final FolderNode node;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool selected) onSelectionChanged;
  final VoidCallback onContextMenu;

  const FolderNodeTile({
    super.key,
    required this.node,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
    required this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected 
          ? colorScheme.primaryContainer
          : colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox (in multi-select mode)
              if (isMultiSelectMode) ...[
                Checkbox(
                  value: isSelected,
                  onChanged: (value) => onSelectionChanged(value ?? false),
                ),
                const SizedBox(width: 8),
              ],
              
              // Icon
              _buildIcon(context),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      node.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Subtitle
                    _buildSubtitle(context),
                  ],
                ),
              ),
              
              // Trailing actions
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (node.isFolder) {
      return Icon(
        Icons.folder,
        size: 40,
        color: isSelected 
            ? colorScheme.onPrimaryContainer
            : colorScheme.primary,
      );
    } else {
      // Document icon based on file type
      final extension = node.document?.extension?.toLowerCase() ?? '';
      IconData iconData;
      Color iconColor;
      
      switch (extension) {
        case 'pdf':
          iconData = Icons.picture_as_pdf;
          iconColor = Colors.red;
          break;
        case 'epub':
          iconData = Icons.menu_book;
          iconColor = Colors.green;
          break;
        case 'docx':
        case 'doc':
          iconData = Icons.description;
          iconColor = Colors.blue;
          break;
        case 'txt':
          iconData = Icons.text_snippet;
          iconColor = Colors.grey;
          break;
        default:
          iconData = Icons.insert_drive_file;
          iconColor = colorScheme.onSurface.withValues(alpha: 0.7);
      }
      
      return Icon(
        iconData,
        size: 40,
        color: isSelected ? colorScheme.onPrimaryContainer : iconColor,
      );
    }
  }

  Widget _buildSubtitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    if (node.isFolder) {
      return Text(
        '${node.documentCount} ${node.documentCount == 1 ? 'item' : 'items'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      );
    } else {
      final document = node.document!;
      final subtitleParts = <String>[];
      
      // Add author if available
      if (document.author != null && document.author!.isNotEmpty) {
        subtitleParts.add(document.author!);
      }
      
      // Add file size if available
      if (document.sizeBytes != null) {
        subtitleParts.add(FileUtils.formatFileSize(document.sizeBytes!));
      }
      
      // Add page count if available
      if (document.pageCount != null) {
        subtitleParts.add('${document.pageCount} pages');
      }
      
      return Text(
        subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : 'Document',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  Widget _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Document status indicators
        if (!node.isFolder && node.document != null) ...[
          // Sync status
          if (node.document!.status == 'synced')
            Icon(
              Icons.cloud_done,
              size: 16,
              color: isSelected 
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : Colors.green,
            ),
          if (node.document!.status == 'syncing')
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isSelected 
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.primary,
              ),
            ),
          if (node.document!.status == 'error')
            Icon(
              Icons.error_outline,
              size: 16,
              color: isSelected 
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : Colors.red,
            ),
          const SizedBox(width: 8),
        ],
        
        // Context menu button
        if (!isMultiSelectMode)
          IconButton(
            onPressed: onContextMenu,
            icon: Icon(
              Icons.more_vert,
              color: isSelected 
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            iconSize: 20,
          ),
        
        // Folder navigation indicator
        if (node.isFolder && !isMultiSelectMode)
          Icon(
            Icons.chevron_right,
            color: isSelected 
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                : colorScheme.onSurface.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}