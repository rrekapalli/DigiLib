import 'package:flutter/material.dart';

/// Dialog for configuring offline download options
class DownloadForOfflineDialog extends StatefulWidget {
  final String documentId;
  final String documentTitle;
  final int totalPages;
  final int? currentlyCachedPages;
  final Function(DownloadOptions options) onDownload;

  const DownloadForOfflineDialog({
    super.key,
    required this.documentId,
    required this.documentTitle,
    required this.totalPages,
    this.currentlyCachedPages,
    required this.onDownload,
  });

  @override
  State<DownloadForOfflineDialog> createState() =>
      _DownloadForOfflineDialogState();
}

class _DownloadForOfflineDialogState extends State<DownloadForOfflineDialog> {
  DownloadQuality _selectedQuality = DownloadQuality.medium;
  DownloadScope _selectedScope = DownloadScope.fullDocument;
  RangeValues? _pageRange;
  bool _downloadThumbnails = true;
  bool _downloadText = true;
  bool _wifiOnly = true;

  @override
  void initState() {
    super.initState();
    if (widget.totalPages > 0) {
      _pageRange = RangeValues(1, widget.totalPages.toDouble());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.download),
          const SizedBox(width: 8.0),
          const Text('Download for Offline'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Document info
              Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.documentTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${widget.totalPages} pages',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.currentlyCachedPages != null &&
                        widget.currentlyCachedPages! > 0) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        '${widget.currentlyCachedPages} pages already cached',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20.0),

              // Download scope
              Text(
                'Download Scope',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildScopeOptions(theme),

              if (_selectedScope == DownloadScope.pageRange) ...[
                const SizedBox(height: 12.0),
                _buildPageRangeSelector(theme),
              ],

              const SizedBox(height: 20.0),

              // Quality settings
              Text(
                'Quality Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildQualityOptions(theme),

              const SizedBox(height: 20.0),

              // Additional options
              Text(
                'Additional Options',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildAdditionalOptions(theme),

              const SizedBox(height: 20.0),

              // Download settings
              Text(
                'Download Settings',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8.0),
              _buildDownloadSettings(theme),

              const SizedBox(height: 16.0),

              // Estimated size and time
              _buildEstimateInfo(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _startDownload,
          child: const Text('Start Download'),
        ),
      ],
    );
  }

  Widget _buildScopeOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<DownloadScope>(
          title: const Text('Full Document'),
          subtitle: Text('Download all ${widget.totalPages} pages'),
          value: DownloadScope.fullDocument,
          groupValue: _selectedScope,
          onChanged: (value) {
            setState(() {
              _selectedScope = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<DownloadScope>(
          title: const Text('Page Range'),
          subtitle: const Text('Download specific pages'),
          value: DownloadScope.pageRange,
          groupValue: _selectedScope,
          onChanged: (value) {
            setState(() {
              _selectedScope = value!;
            });
          },
          dense: true,
        ),
        if (widget.currentlyCachedPages != null &&
            widget.currentlyCachedPages! < widget.totalPages)
          RadioListTile<DownloadScope>(
            title: const Text('Missing Pages Only'),
            subtitle: Text(
              'Download ${widget.totalPages - widget.currentlyCachedPages!} uncached pages',
            ),
            value: DownloadScope.missingOnly,
            groupValue: _selectedScope,
            onChanged: (value) {
              setState(() {
                _selectedScope = value!;
              });
            },
            dense: true,
          ),
      ],
    );
  }

  Widget _buildPageRangeSelector(ThemeData theme) {
    if (_pageRange == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Page Range: ${_pageRange!.start.toInt()} - ${_pageRange!.end.toInt()}',
          style: theme.textTheme.bodyMedium,
        ),
        RangeSlider(
          values: _pageRange!,
          min: 1,
          max: widget.totalPages.toDouble(),
          divisions: widget.totalPages > 1 ? widget.totalPages - 1 : 1,
          labels: RangeLabels(
            _pageRange!.start.toInt().toString(),
            _pageRange!.end.toInt().toString(),
          ),
          onChanged: (values) {
            setState(() {
              _pageRange = values;
            });
          },
        ),
      ],
    );
  }

  Widget _buildQualityOptions(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<DownloadQuality>(
          title: const Text('High Quality'),
          subtitle: const Text('Best quality, larger file size (300 DPI)'),
          value: DownloadQuality.high,
          groupValue: _selectedQuality,
          onChanged: (value) {
            setState(() {
              _selectedQuality = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<DownloadQuality>(
          title: const Text('Medium Quality'),
          subtitle: const Text('Good balance of quality and size (150 DPI)'),
          value: DownloadQuality.medium,
          groupValue: _selectedQuality,
          onChanged: (value) {
            setState(() {
              _selectedQuality = value!;
            });
          },
          dense: true,
        ),
        RadioListTile<DownloadQuality>(
          title: const Text('Low Quality'),
          subtitle: const Text('Smaller file size, lower quality (75 DPI)'),
          value: DownloadQuality.low,
          groupValue: _selectedQuality,
          onChanged: (value) {
            setState(() {
              _selectedQuality = value!;
            });
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildAdditionalOptions(ThemeData theme) {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Download Thumbnails'),
          subtitle: const Text('Include page thumbnails for faster browsing'),
          value: _downloadThumbnails,
          onChanged: (value) {
            setState(() {
              _downloadThumbnails = value ?? false;
            });
          },
          dense: true,
        ),
        CheckboxListTile(
          title: const Text('Download Text Content'),
          subtitle: const Text('Enable offline search within document'),
          value: _downloadText,
          onChanged: (value) {
            setState(() {
              _downloadText = value ?? false;
            });
          },
          dense: true,
        ),
      ],
    );
  }

  Widget _buildDownloadSettings(ThemeData theme) {
    return CheckboxListTile(
      title: const Text('Wi-Fi Only'),
      subtitle: const Text('Only download when connected to Wi-Fi'),
      value: _wifiOnly,
      onChanged: (value) {
        setState(() {
          _wifiOnly = value ?? false;
        });
      },
      dense: true,
    );
  }

  Widget _buildEstimateInfo(ThemeData theme) {
    final estimatedSize = _calculateEstimatedSize();
    final estimatedTime = _calculateEstimatedTime();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.0,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8.0),
              Text(
                'Estimated Download',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Size:'),
              Text(
                estimatedSize,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Time:'),
              Text(
                estimatedTime,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _calculateEstimatedSize() {
    int pagesToDownload = _getPagesToDownload();

    // Estimate based on quality and options
    double baseSizePerPage = 0.5; // MB per page at medium quality

    switch (_selectedQuality) {
      case DownloadQuality.high:
        baseSizePerPage = 1.2;
        break;
      case DownloadQuality.medium:
        baseSizePerPage = 0.5;
        break;
      case DownloadQuality.low:
        baseSizePerPage = 0.2;
        break;
    }

    double totalSize = pagesToDownload * baseSizePerPage;

    if (_downloadThumbnails) {
      totalSize += pagesToDownload * 0.05; // 50KB per thumbnail
    }

    if (_downloadText) {
      totalSize += pagesToDownload * 0.01; // 10KB per page text
    }

    if (totalSize < 1) {
      return '${(totalSize * 1024).toInt()} KB';
    } else {
      return '${totalSize.toStringAsFixed(1)} MB';
    }
  }

  String _calculateEstimatedTime() {
    int pagesToDownload = _getPagesToDownload();

    // Estimate 2-5 seconds per page depending on quality and connection
    double secondsPerPage = 3.0;

    switch (_selectedQuality) {
      case DownloadQuality.high:
        secondsPerPage = 5.0;
        break;
      case DownloadQuality.medium:
        secondsPerPage = 3.0;
        break;
      case DownloadQuality.low:
        secondsPerPage = 2.0;
        break;
    }

    int totalSeconds = (pagesToDownload * secondsPerPage).toInt();

    if (totalSeconds < 60) {
      return '$totalSeconds seconds';
    } else if (totalSeconds < 3600) {
      return '${(totalSeconds / 60).toInt()} minutes';
    } else {
      return '${(totalSeconds / 3600).toStringAsFixed(1)} hours';
    }
  }

  int _getPagesToDownload() {
    switch (_selectedScope) {
      case DownloadScope.fullDocument:
        return widget.totalPages;
      case DownloadScope.pageRange:
        if (_pageRange != null) {
          return (_pageRange!.end - _pageRange!.start + 1).toInt();
        }
        return widget.totalPages;
      case DownloadScope.missingOnly:
        return widget.totalPages - (widget.currentlyCachedPages ?? 0);
    }
  }

  void _startDownload() {
    final options = DownloadOptions(
      documentId: widget.documentId,
      scope: _selectedScope,
      quality: _selectedQuality,
      pageRange: _selectedScope == DownloadScope.pageRange ? _pageRange : null,
      downloadThumbnails: _downloadThumbnails,
      downloadText: _downloadText,
      wifiOnly: _wifiOnly,
    );

    widget.onDownload(options);
    Navigator.of(context).pop();
  }
}

/// Enum for download scope options
enum DownloadScope { fullDocument, pageRange, missingOnly }

/// Enum for download quality options
enum DownloadQuality { high, medium, low }

/// Model for download options
class DownloadOptions {
  final String documentId;
  final DownloadScope scope;
  final DownloadQuality quality;
  final RangeValues? pageRange;
  final bool downloadThumbnails;
  final bool downloadText;
  final bool wifiOnly;

  const DownloadOptions({
    required this.documentId,
    required this.scope,
    required this.quality,
    this.pageRange,
    required this.downloadThumbnails,
    required this.downloadText,
    required this.wifiOnly,
  });

  int getDpi() {
    switch (quality) {
      case DownloadQuality.high:
        return 300;
      case DownloadQuality.medium:
        return 150;
      case DownloadQuality.low:
        return 75;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'documentId': documentId,
      'scope': scope.name,
      'quality': quality.name,
      'pageRange': pageRange != null
          ? {'start': pageRange!.start.toInt(), 'end': pageRange!.end.toInt()}
          : null,
      'downloadThumbnails': downloadThumbnails,
      'downloadText': downloadText,
      'wifiOnly': wifiOnly,
      'dpi': getDpi(),
    };
  }
}
