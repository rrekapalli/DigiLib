import 'package:flutter/material.dart';
import '../models/entities/document.dart';
import '../utils/file_utils.dart';
import 'share_indicator.dart';

/// List tile widget for displaying document in list view
class DocumentListTile extends StatelessWidget {
  final Document document;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool selected) onSelectionChanged;
  final VoidCallback onContextMenu;
  final bool showThumbnail;
  final bool showMetadata;
  final bool showShareIndicator;

  const DocumentListTile({
    super.key,
    required this.document,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
    required this.onContextMenu,
    this.showThumbnail = true,
    this.showMetadata = true,
    this.showShareIndicator = true,
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
                const SizedBox(width: 12),
              ],
              
              // Thumbnail
              if (showThumbnail)
                _buildThumbnail(context),
              
              if (showThumbnail)
                const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      document.title ?? document.filename ?? 'Unknown Document',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected 
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    if (showMetadata) ...[
                      const SizedBox(height: 4),
                      
                      // Author
                      if (document.author != null && document.author!.isNotEmpty)
                        Text(
                          document.author!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected 
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 4),
                      
                      // Metadata row
                      _buildMetadataRow(context),
                    ],
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

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 60,
      height: 80,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: document.imageUrl != null
            ? Image.network(
                document.imageUrl!,
                width: 60,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(context),
              )
            : _buildPlaceholderIcon(context),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = document.extension?.toLowerCase() ?? '';
    
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
        iconColor = colorScheme.onSurface.withValues(alpha: 0.5);
    }
    
    return Center(
      child: Icon(
        iconData,
        size: 32,
        color: iconColor,
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final metadataItems = <Widget>[];
    
    // File type
    final extension = document.extension?.toUpperCase() ?? 'DOC';
    metadataItems.add(
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.1)
              : colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          extension,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? colorScheme.onPrimaryContainer
                : colorScheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
    
    // Share indicator
    if (showShareIndicator) {
      metadataItems.add(
        ShareIndicator(
          subjectId: document.id,
          showCount: true,
          size: 12,
        ),
      );
    }
    
    // File size
    if (document.sizeBytes != null) {
      metadataItems.add(
        Text(
          FileUtils.formatFileSize(document.sizeBytes!),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    
    // Page count
    if (document.pageCount != null) {
      metadataItems.add(
        Text(
          '${document.pageCount} pages',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    
    // Year published
    if (document.yearPublished != null) {
      metadataItems.add(
        Text(
          '${document.yearPublished}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isSelected 
                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                : colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: metadataItems,
    );
  }

  Widget _buildTrailing(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Status indicator
        _buildStatusIndicator(context),
        
        const SizedBox(height: 8),
        
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
        
        // Last modified date
        if (showMetadata)
          Text(
            _formatDate(document.updatedAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isSelected 
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                  : colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    switch (document.status) {
      case 'synced':
        return Icon(
          Icons.cloud_done,
          size: 16,
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : Colors.green,
        );
      case 'syncing':
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: isSelected 
                ? colorScheme.onPrimaryContainer
                : colorScheme.primary,
          ),
        );
      case 'error':
        return Icon(
          Icons.error_outline,
          size: 16,
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : Colors.red,
        );
      default:
        return const SizedBox(width: 16, height: 16);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}