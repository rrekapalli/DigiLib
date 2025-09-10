import 'package:flutter/material.dart';
import '../models/entities/document.dart';
import '../models/entities/tag.dart';
import 'share_indicator.dart';

/// Card widget for displaying document in grid view
class DocumentCard extends StatelessWidget {
  final Document document;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(bool selected) onSelectionChanged;
  final VoidCallback onContextMenu;
  final VoidCallback? onTagTap;
  final bool showThumbnail;
  final bool showMetadata;
  final bool showTags;
  final bool showShareIndicator;
  final List<Tag> tags;

  const DocumentCard({
    super.key,
    required this.document,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSelectionChanged,
    required this.onContextMenu,
    this.onTagTap,
    this.showThumbnail = true,
    this.showMetadata = true,
    this.showTags = true,
    this.showShareIndicator = true,
    this.tags = const [],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail section
            if (showThumbnail)
              Expanded(
                flex: 3,
                child: _buildThumbnail(context),
              ),
            
            // Content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selection checkbox and title
                    Row(
                      children: [
                        if (isMultiSelectMode) ...[
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (value) => onSelectionChanged(value ?? false),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            document.title ?? document.filename ?? 'Unknown Document',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: isSelected 
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Metadata
                    if (showMetadata) ...[
                      if (document.author != null && document.author!.isNotEmpty)
                        Text(
                          document.author!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected 
                                ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                                : colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      
                      const SizedBox(height: 2),
                      
                      Row(
                        children: [
                          // File type indicator
                          _buildFileTypeChip(context),
                          const SizedBox(width: 4),
                          // Share indicator
                          if (showShareIndicator)
                            ShareIndicator(
                              subjectId: document.id,
                              showCount: false,
                              size: 12,
                            ),
                          const Spacer(),
                          // Status indicator
                          _buildStatusIndicator(context),
                        ],
                      ),
                      
                      // Tags section
                      if (showTags && tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildTagsSection(context),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          // Thumbnail image or placeholder
          Center(
            child: document.imageUrl != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      document.imageUrl!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(context),
                    ),
                  )
                : _buildPlaceholderIcon(context),
          ),
          
          // Context menu button
          if (!isMultiSelectMode)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  onPressed: onContextMenu,
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    size: 18,
                  ),
                  iconSize: 18,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ),
            ),
          
          // Page count overlay
          if (document.pageCount != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${document.pageCount} pages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
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
    
    return Icon(
      iconData,
      size: 48,
      color: iconColor,
    );
  }

  Widget _buildFileTypeChip(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extension = document.extension?.toUpperCase() ?? 'DOC';
    
    return Container(
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
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    switch (document.status) {
      case 'synced':
        return Icon(
          Icons.cloud_done,
          size: 14,
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : Colors.green,
        );
      case 'syncing':
        return SizedBox(
          width: 14,
          height: 14,
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
          size: 14,
          color: isSelected 
              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
              : Colors.red,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTagsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Show up to 3 tags, with overflow indicator
    final visibleTags = tags.take(3).toList();
    final hasMoreTags = tags.length > 3;
    
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              ...visibleTags.map((tag) => _buildTagChip(context, tag)),
              if (hasMoreTags)
                GestureDetector(
                  onTap: onTagTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '+${tags.length - 3}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (!isMultiSelectMode)
          GestureDetector(
            onTap: onTagTap,
            child: Icon(
              Icons.label_outline,
              size: 16,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildTagChip(BuildContext context, Tag tag) {
    final theme = Theme.of(context);
    final tagColor = _getTagColor(tag.name);
    
    return GestureDetector(
      onTap: onTagTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected 
              ? tagColor.withValues(alpha: 0.2)
              : tagColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: tagColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          tag.name,
          style: theme.textTheme.bodySmall?.copyWith(
            color: tagColor,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getTagColor(String tagName) {
    final hash = tagName.hashCode;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    return colors[hash.abs() % colors.length];
  }
}