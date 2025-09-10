import 'package:flutter/material.dart';
import '../models/entities/document.dart';
import '../utils/file_utils.dart';

/// Detailed view widget for document information
class DocumentDetailView extends StatelessWidget {
  final Document document;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final VoidCallback? onAddTag;
  final VoidCallback? onOpen;

  const DocumentDetailView({
    super.key,
    required this.document,
    this.onEdit,
    this.onShare,
    this.onDelete,
    this.onAddTag,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              if (onShare != null)
                const PopupMenuItem(
                  value: 'share',
                  child: ListTile(
                    leading: Icon(Icons.share),
                    title: Text('Share'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              if (onAddTag != null)
                const PopupMenuItem(
                  value: 'add_tag',
                  child: ListTile(
                    leading: Icon(Icons.label),
                    title: Text('Add Tags'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuDivider(),
              if (onDelete != null)
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with thumbnail and basic info
            _buildHeaderSection(context),
            
            const SizedBox(height: 24),
            
            // Action buttons
            _buildActionButtons(context),
            
            const SizedBox(height: 24),
            
            // Metadata sections
            _buildBasicInfoSection(context),
            
            const SizedBox(height: 16),
            
            _buildFileInfoSection(context),
            
            const SizedBox(height: 16),
            
            _buildPublicationInfoSection(context),
            
            const SizedBox(height: 16),
            
            _buildSystemInfoSection(context),
            
            if (document.metadataJson != null && document.metadataJson!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAdditionalMetadataSection(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: document.imageUrl != null
                ? Image.network(
                    document.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholderIcon(context),
                  )
                : _buildPlaceholderIcon(context),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Basic info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                document.title ?? document.filename ?? 'Unknown Document',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Author
              if (document.author != null && document.author!.isNotEmpty)
                Text(
                  'by ${document.author}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Status and type chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatusChip(context),
                  _buildTypeChip(context),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        if (onOpen != null)
          Expanded(
            child: FilledButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open Document'),
            ),
          ),
        
        if (onOpen != null && (onShare != null || onEdit != null))
          const SizedBox(width: 12),
        
        if (onShare != null)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onShare,
              icon: const Icon(Icons.share),
              label: const Text('Share'),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return _buildSection(
      context,
      title: 'Basic Information',
      children: [
        if (document.title != null)
          _buildInfoRow('Title', document.title!),
        if (document.author != null)
          _buildInfoRow('Author', document.author!),
        if (document.filename != null)
          _buildInfoRow('Filename', document.filename!),
        if (document.renamedName != null)
          _buildInfoRow('Display Name', document.renamedName!),
      ],
    );
  }

  Widget _buildFileInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'File Information',
      children: [
        if (document.extension != null)
          _buildInfoRow('Format', document.extension!.toUpperCase()),
        if (document.sizeBytes != null)
          _buildInfoRow('Size', FileUtils.formatFileSize(document.sizeBytes!)),
        if (document.pageCount != null)
          _buildInfoRow('Pages', '${document.pageCount}'),
        if (document.sha256 != null)
          _buildInfoRow('Checksum', document.sha256!, isMonospace: true),
      ],
    );
  }

  Widget _buildPublicationInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'Publication Information',
      children: [
        if (document.isbn != null)
          _buildInfoRow('ISBN', document.isbn!),
        if (document.yearPublished != null)
          _buildInfoRow('Year Published', '${document.yearPublished}'),
      ],
    );
  }

  Widget _buildSystemInfoSection(BuildContext context) {
    return _buildSection(
      context,
      title: 'System Information',
      children: [
        _buildInfoRow('Created', _formatDateTime(document.createdAt)),
        _buildInfoRow('Modified', _formatDateTime(document.updatedAt)),
        if (document.relativePath != null)
          _buildInfoRow('Path', document.relativePath!, isMonospace: true),
        if (document.cloudId != null)
          _buildInfoRow('Cloud ID', document.cloudId!, isMonospace: true),
      ],
    );
  }

  Widget _buildAdditionalMetadataSection(BuildContext context) {
    final metadata = document.metadataJson!;
    
    return _buildSection(
      context,
      title: 'Additional Metadata',
      children: metadata.entries.map((entry) {
        return _buildInfoRow(
          _formatMetadataKey(entry.key),
          entry.value.toString(),
        );
      }).toList(),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required List<Widget> children}) {
    if (children.isEmpty) return const SizedBox.shrink();
    
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...children,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: isMonospace ? 'monospace' : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
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
        iconColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
    }
    
    return Center(
      child: Icon(
        iconData,
        size: 64,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final theme = Theme.of(context);
    final status = document.status ?? 'unknown';
    
    Color chipColor;
    IconData iconData;
    
    switch (status) {
      case 'synced':
        chipColor = Colors.green;
        iconData = Icons.cloud_done;
        break;
      case 'syncing':
        chipColor = Colors.orange;
        iconData = Icons.sync;
        break;
      case 'error':
        chipColor = Colors.red;
        iconData = Icons.error;
        break;
      default:
        chipColor = Colors.grey;
        iconData = Icons.help_outline;
    }
    
    return Chip(
      avatar: Icon(iconData, size: 16, color: Colors.white),
      label: Text(
        status.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: chipColor,
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    final extension = document.extension?.toUpperCase() ?? 'DOC';
    
    return Chip(
      label: Text(
        extension,
        style: const TextStyle(fontSize: 12),
      ),
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatMetadataKey(String key) {
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        onShare?.call();
        break;
      case 'add_tag':
        onAddTag?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}