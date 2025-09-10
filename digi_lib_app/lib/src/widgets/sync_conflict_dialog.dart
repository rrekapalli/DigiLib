import 'package:flutter/material.dart';
import '../services/job_queue_service.dart';
import '../models/api/sync_models.dart';

/// Dialog for resolving sync conflicts
class SyncConflictDialog extends StatefulWidget {
  final List<SyncConflict> conflicts;
  final Function(String conflictId, ConflictResolution resolution) onResolveConflict;

  const SyncConflictDialog({
    super.key,
    required this.conflicts,
    required this.onResolveConflict,
  });

  @override
  State<SyncConflictDialog> createState() => _SyncConflictDialogState();
}

class _SyncConflictDialogState extends State<SyncConflictDialog> {
  final Map<String, ConflictResolution> _resolutions = {};
  int _currentConflictIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with default resolutions
    for (final conflict in widget.conflicts) {
      _resolutions[conflict.entityId] = ConflictResolution.useServer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentConflict = widget.conflicts[_currentConflictIndex];
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.merge_type,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8.0),
          const Text('Sync Conflicts'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            if (widget.conflicts.length > 1) ...[
              Text(
                'Conflict ${_currentConflictIndex + 1} of ${widget.conflicts.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8.0),
              LinearProgressIndicator(
                value: (_currentConflictIndex + 1) / widget.conflicts.length,
              ),
              const SizedBox(height: 16.0),
            ],
            
            // Conflict details
            _buildConflictDetails(currentConflict, theme),
            
            const SizedBox(height: 16.0),
            
            // Resolution options
            _buildResolutionOptions(currentConflict, theme),
          ],
        ),
      ),
      actions: [
        if (_currentConflictIndex > 0)
          TextButton(
            onPressed: () {
              setState(() {
                _currentConflictIndex--;
              });
            },
            child: const Text('Previous'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_currentConflictIndex < widget.conflicts.length - 1)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _currentConflictIndex++;
              });
            },
            child: const Text('Next'),
          )
        else
          ElevatedButton(
            onPressed: _resolveAllConflicts,
            child: const Text('Resolve All'),
          ),
      ],
    );
  }

  Widget _buildConflictDetails(SyncConflict conflict, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getEntityIcon(conflict.entityType),
                size: 20.0,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 8.0),
              Text(
                _getEntityDisplayName(conflict.entityType),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'ID: ${conflict.entityId}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Both your device and the server have changes to this item. Choose how to resolve the conflict:',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOptions(SyncConflict conflict, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resolution Options:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        
        // Use Server Version
        _buildResolutionOption(
          conflict: conflict,
          resolution: ConflictResolution.useServer,
          title: 'Use Server Version',
          description: 'Keep the version from the server and discard your local changes.',
          icon: Icons.cloud_download,
          theme: theme,
        ),
        
        const SizedBox(height: 8.0),
        
        // Use Local Version
        _buildResolutionOption(
          conflict: conflict,
          resolution: ConflictResolution.useLocal,
          title: 'Use Local Version',
          description: 'Keep your local changes and overwrite the server version.',
          icon: Icons.phone_android,
          theme: theme,
        ),
        
        const SizedBox(height: 8.0),
        
        // Merge (if supported)
        if (_supportsMerge(conflict.entityType))
          _buildResolutionOption(
            conflict: conflict,
            resolution: ConflictResolution.merge,
            title: 'Merge Changes',
            description: 'Attempt to combine both versions (may not always be possible).',
            icon: Icons.merge,
            theme: theme,
          ),
      ],
    );
  }

  Widget _buildResolutionOption({
    required SyncConflict conflict,
    required ConflictResolution resolution,
    required String title,
    required String description,
    required IconData icon,
    required ThemeData theme,
  }) {
    final isSelected = _resolutions[conflict.entityId] == resolution;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _resolutions[conflict.entityId] = resolution;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isSelected 
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Radio<ConflictResolution>(
              value: resolution,
              groupValue: _resolutions[conflict.entityId],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _resolutions[conflict.entityId] = value;
                  });
                }
              },
            ),
            const SizedBox(width: 8.0),
            Icon(
              icon,
              size: 20.0,
              color: isSelected 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'document':
        return Icons.description;
      case 'bookmark':
        return Icons.bookmark;
      case 'comment':
        return Icons.comment;
      case 'reading_progress':
        return Icons.timeline;
      case 'tag':
        return Icons.label;
      case 'share':
        return Icons.share;
      default:
        return Icons.help_outline;
    }
  }

  String _getEntityDisplayName(String entityType) {
    switch (entityType) {
      case 'document':
        return 'Document';
      case 'bookmark':
        return 'Bookmark';
      case 'comment':
        return 'Comment';
      case 'reading_progress':
        return 'Reading Progress';
      case 'tag':
        return 'Tag';
      case 'document_tag':
        return 'Document Tag';
      case 'share':
        return 'Share';
      default:
        return entityType.replaceAll('_', ' ').toUpperCase();
    }
  }

  bool _supportsMerge(String entityType) {
    // For now, only comments support merging (append-only)
    return entityType == 'comment';
  }

  void _resolveAllConflicts() {
    for (final conflict in widget.conflicts) {
      final resolution = _resolutions[conflict.entityId] ?? ConflictResolution.useServer;
      widget.onResolveConflict(conflict.entityId, resolution);
    }
    Navigator.of(context).pop();
  }
}

/// Widget that shows a summary of sync conflicts
class SyncConflictSummary extends StatelessWidget {
  final List<SyncConflict> conflicts;
  final VoidCallback onResolve;

  const SyncConflictSummary({
    super.key,
    required this.conflicts,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (conflicts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      color: theme.colorScheme.errorContainer.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                  size: 24.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Sync Conflicts Detected',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              '${conflicts.length} items have conflicts that need to be resolved.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8.0),
            _buildConflictTypesSummary(theme),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    // TODO: Show help about conflicts
                  },
                  child: const Text('Learn More'),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: onResolve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  child: const Text('Resolve Conflicts'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictTypesSummary(ThemeData theme) {
    final conflictsByType = <String, int>{};
    for (final conflict in conflicts) {
      conflictsByType[conflict.entityType] = 
          (conflictsByType[conflict.entityType] ?? 0) + 1;
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: conflictsByType.entries.map((entry) {
        return Chip(
          avatar: Icon(
            _getEntityIcon(entry.key),
            size: 16.0,
          ),
          label: Text('${_getEntityDisplayName(entry.key)}: ${entry.value}'),
          backgroundColor: theme.colorScheme.errorContainer.withOpacity(0.3),
        );
      }).toList(),
    );
  }

  IconData _getEntityIcon(String entityType) {
    switch (entityType) {
      case 'document':
        return Icons.description;
      case 'bookmark':
        return Icons.bookmark;
      case 'comment':
        return Icons.comment;
      case 'reading_progress':
        return Icons.timeline;
      case 'tag':
        return Icons.label;
      case 'share':
        return Icons.share;
      default:
        return Icons.help_outline;
    }
  }

  String _getEntityDisplayName(String entityType) {
    switch (entityType) {
      case 'document':
        return 'Documents';
      case 'bookmark':
        return 'Bookmarks';
      case 'comment':
        return 'Comments';
      case 'reading_progress':
        return 'Reading Progress';
      case 'tag':
        return 'Tags';
      case 'document_tag':
        return 'Document Tags';
      case 'share':
        return 'Shares';
      default:
        return entityType.replaceAll('_', ' ').toUpperCase();
    }
  }
}
