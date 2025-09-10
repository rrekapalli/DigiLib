import 'package:flutter/material.dart';
import '../models/entities/library.dart';
import '../services/library_api_service.dart';

/// Card widget displaying library information and actions
class LibraryCard extends StatelessWidget {
  final Library library;
  final ScanProgress? scanProgress;
  final VoidCallback? onTap;
  final VoidCallback? onScan;
  final VoidCallback? onSettings;
  final VoidCallback? onDelete;

  const LibraryCard({
    super.key,
    required this.library,
    this.scanProgress,
    this.onTap,
    this.onScan,
    this.onSettings,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildLibraryIcon(colorScheme),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          library.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getLibraryTypeDisplayName(library.type),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildSyncStatusIndicator(colorScheme),
                  PopupMenuButton<String>(
                    onSelected: _handleMenuAction,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'scan',
                        child: ListTile(
                          leading: Icon(Icons.refresh),
                          title: Text('Rescan'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'settings',
                        child: ListTile(
                          leading: Icon(Icons.settings),
                          title: Text('Settings'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuDivider(),
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
              
              const SizedBox(height: 16),
              
              // Library statistics
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.description,
                    label: 'Documents',
                    value: _getDocumentCount(),
                    colorScheme: colorScheme,
                  ),
                  const SizedBox(width: 8),
                  _buildStatChip(
                    icon: Icons.storage,
                    label: 'Size',
                    value: _getLibrarySize(),
                    colorScheme: colorScheme,
                  ),
                ],
              ),
              
              // Scan progress indicator
              if (scanProgress != null) ...[
                const SizedBox(height: 16),
                _buildScanProgress(theme, colorScheme),
              ],
              
              // Last sync info
              const SizedBox(height: 12),
              Text(
                'Added ${_formatDate(library.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryIcon(ColorScheme colorScheme) {
    IconData iconData;
    Color iconColor;

    switch (library.type) {
      case LibraryType.local:
        iconData = Icons.folder;
        iconColor = colorScheme.primary;
        break;
      case LibraryType.gdrive:
        iconData = Icons.cloud;
        iconColor = Colors.blue;
        break;
      case LibraryType.onedrive:
        iconData = Icons.cloud;
        iconColor = Colors.blue.shade700;
        break;
      case LibraryType.s3:
        iconData = Icons.cloud_queue;
        iconColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 24,
      ),
    );
  }

  Widget _buildSyncStatusIndicator(ColorScheme colorScheme) {
    // For now, show a simple online/offline indicator
    // In a real implementation, this would show actual sync status
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required ColorScheme colorScheme,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanProgress(ThemeData theme, ColorScheme colorScheme) {
    final progress = scanProgress!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getScanStatusIcon(progress.status),
              size: 16,
              color: _getScanStatusColor(progress.status, colorScheme),
            ),
            const SizedBox(width: 8),
            Text(
              _getScanStatusText(progress.status),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _getScanStatusColor(progress.status, colorScheme),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (progress.status == 'running') ...[
              Text(
                '${progress.progress}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        
        if (progress.status == 'running') ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.progress / 100,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
        ],
        
        if (progress.error != null) ...[
          const SizedBox(height: 4),
          Text(
            progress.error!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  IconData _getScanStatusIcon(String status) {
    switch (status) {
      case 'running':
        return Icons.sync;
      case 'completed':
        return Icons.check_circle;
      case 'failed':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      case 'queued':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  Color _getScanStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'running':
      case 'queued':
        return colorScheme.primary;
      case 'completed':
        return Colors.green;
      case 'failed':
        return colorScheme.error;
      case 'cancelled':
        return colorScheme.onSurface.withValues(alpha: 0.6);
      default:
        return colorScheme.onSurface.withValues(alpha: 0.6);
    }
  }

  String _getScanStatusText(String status) {
    switch (status) {
      case 'running':
        return 'Scanning...';
      case 'completed':
        return 'Scan completed';
      case 'failed':
        return 'Scan failed';
      case 'cancelled':
        return 'Scan cancelled';
      case 'queued':
        return 'Scan queued';
      default:
        return 'Unknown status';
    }
  }

  String _getLibraryTypeDisplayName(LibraryType type) {
    switch (type) {
      case LibraryType.local:
        return 'Local Folder';
      case LibraryType.gdrive:
        return 'Google Drive';
      case LibraryType.onedrive:
        return 'OneDrive';
      case LibraryType.s3:
        return 'Amazon S3';
    }
  }

  String _getDocumentCount() {
    // In a real implementation, this would come from the library metadata
    // For now, return a placeholder
    return '0';
  }

  String _getLibrarySize() {
    // In a real implementation, this would come from the library metadata
    // For now, return a placeholder
    return '0 MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'scan':
        onScan?.call();
        break;
      case 'settings':
        onSettings?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }
}