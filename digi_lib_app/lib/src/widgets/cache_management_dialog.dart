import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog for managing cache storage
class CacheManagementDialog extends ConsumerStatefulWidget {
  const CacheManagementDialog({super.key});

  @override
  ConsumerState<CacheManagementDialog> createState() => _CacheManagementDialogState();
}

class _CacheManagementDialogState extends ConsumerState<CacheManagementDialog> {
  bool _isLoading = true;
  int _totalCacheSize = 0;
  int _thumbnailCacheSize = 0;
  int _pageCacheSize = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheInfo();
  }

  Future<void> _loadCacheInfo() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock cache sizes - in real implementation, get from CacheService
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _totalCacheSize = 512 * 1024 * 1024; // 512 MB
        _thumbnailCacheSize = 128 * 1024 * 1024; // 128 MB
        _pageCacheSize = 384 * 1024 * 1024; // 384 MB
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Cache Management'),
      content: SizedBox(
        width: double.maxFinite,
        child: _isLoading
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading cache information...'),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cache Usage',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _CacheInfoTile(
                    title: 'Total Cache',
                    size: _formatBytes(_totalCacheSize),
                    icon: Icons.storage,
                  ),
                  _CacheInfoTile(
                    title: 'Page Cache',
                    size: _formatBytes(_pageCacheSize),
                    icon: Icons.description,
                  ),
                  _CacheInfoTile(
                    title: 'Thumbnail Cache',
                    size: _formatBytes(_thumbnailCacheSize),
                    icon: Icons.image,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearPageCache,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Page Cache'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearThumbnailCache,
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Thumbnail Cache'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _clearAllCache,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear All Cache'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _clearPageCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Page Cache',
      'This will clear all cached document pages. They will need to be re-downloaded when accessed.',
    );

    if (confirmed) {
      // In real implementation, call CacheService.clearPageCache()
      setState(() {
        _pageCacheSize = 0;
        _totalCacheSize = _thumbnailCacheSize;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Page cache cleared')),
        );
      }
    }
  }

  Future<void> _clearThumbnailCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear Thumbnail Cache',
      'This will clear all cached thumbnails. They will need to be re-generated when accessed.',
    );

    if (confirmed) {
      // In real implementation, call CacheService.clearThumbnailCache()
      setState(() {
        _thumbnailCacheSize = 0;
        _totalCacheSize = _pageCacheSize;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thumbnail cache cleared')),
        );
      }
    }
  }

  Future<void> _clearAllCache() async {
    final confirmed = await _showConfirmationDialog(
      'Clear All Cache',
      'This will clear all cached data including pages and thumbnails. This action cannot be undone.',
    );

    if (confirmed) {
      // In real implementation, call CacheService.clearAllCache()
      setState(() {
        _totalCacheSize = 0;
        _pageCacheSize = 0;
        _thumbnailCacheSize = 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All cache cleared')),
        );
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _CacheInfoTile extends StatelessWidget {
  final String title;
  final String size;
  final IconData icon;

  const _CacheInfoTile({
    required this.title,
    required this.size,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Text(size),
      contentPadding: EdgeInsets.zero,
    );
  }
}