import 'dart:typed_data';

/// Result of page rendering operation
class PageRenderResult {
  final String documentId;
  final int pageNumber;
  final Uint8List? imageData;
  final String? imageUrl;
  final int width;
  final int height;
  final int dpi;
  final String format;
  final bool fromCache;
  final DateTime renderedAt;
  final String? error;

  const PageRenderResult({
    required this.documentId,
    required this.pageNumber,
    this.imageData,
    this.imageUrl,
    required this.width,
    required this.height,
    required this.dpi,
    required this.format,
    this.fromCache = false,
    required this.renderedAt,
    this.error,
  });

  /// Check if rendering was successful
  bool get isSuccess => error == null && (imageData != null || imageUrl != null);

  /// Check if result has image data
  bool get hasImageData => imageData != null;

  /// Check if result has image URL
  bool get hasImageUrl => imageUrl != null && imageUrl!.isNotEmpty;

  /// Get file size in bytes (if image data is available)
  int? get fileSizeBytes => imageData?.length;

  /// Get aspect ratio
  double get aspectRatio {
    if (height == 0) return 1.0;
    return width / height;
  }

  PageRenderResult copyWith({
    String? documentId,
    int? pageNumber,
    Uint8List? imageData,
    String? imageUrl,
    int? width,
    int? height,
    int? dpi,
    String? format,
    bool? fromCache,
    DateTime? renderedAt,
    String? error,
  }) {
    return PageRenderResult(
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      imageData: imageData ?? this.imageData,
      imageUrl: imageUrl ?? this.imageUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      dpi: dpi ?? this.dpi,
      format: format ?? this.format,
      fromCache: fromCache ?? this.fromCache,
      renderedAt: renderedAt ?? this.renderedAt,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageRenderResult &&
        other.documentId == documentId &&
        other.pageNumber == pageNumber &&
        other.imageData == imageData &&
        other.imageUrl == imageUrl &&
        other.width == width &&
        other.height == height &&
        other.dpi == dpi &&
        other.format == format &&
        other.fromCache == fromCache &&
        other.renderedAt == renderedAt &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      documentId,
      pageNumber,
      imageData,
      imageUrl,
      width,
      height,
      dpi,
      format,
      fromCache,
      renderedAt,
      error,
    );
  }

  @override
  String toString() {
    return 'PageRenderResult(documentId: $documentId, '
           'pageNumber: $pageNumber, '
           'hasImageData: $hasImageData, '
           'hasImageUrl: $hasImageUrl, '
           'size: ${width}x$height, '
           'dpi: $dpi, '
           'format: $format, '
           'fromCache: $fromCache, '
           'isSuccess: $isSuccess, '
           'error: $error)';
  }
}