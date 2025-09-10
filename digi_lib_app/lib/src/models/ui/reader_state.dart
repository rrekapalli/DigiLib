/// State for document reader functionality
class ReaderState {
  final String documentId;
  final int currentPage;
  final int totalPages;
  final double zoomLevel;
  final double scrollOffset;
  final bool isLoading;
  final String? error;
  final DateTime lastUpdated;

  const ReaderState({
    required this.documentId,
    required this.currentPage,
    required this.totalPages,
    this.zoomLevel = 1.0,
    this.scrollOffset = 0.0,
    this.isLoading = false,
    this.error,
    required this.lastUpdated,
  });

  ReaderState copyWith({
    String? documentId,
    int? currentPage,
    int? totalPages,
    double? zoomLevel,
    double? scrollOffset,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return ReaderState(
      documentId: documentId ?? this.documentId,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      scrollOffset: scrollOffset ?? this.scrollOffset,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Check if current page is the first page
  bool get isFirstPage => currentPage <= 1;

  /// Check if current page is the last page
  bool get isLastPage => currentPage >= totalPages;

  /// Get reading progress as percentage
  double get progressPercentage {
    if (totalPages <= 0) return 0.0;
    return (currentPage / totalPages).clamp(0.0, 1.0);
  }

  /// Get remaining pages
  int get remainingPages => (totalPages - currentPage).clamp(0, totalPages);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReaderState &&
        other.documentId == documentId &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.zoomLevel == zoomLevel &&
        other.scrollOffset == scrollOffset &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.lastUpdated == lastUpdated;
  }

  @override
  int get hashCode {
    return Object.hash(
      documentId,
      currentPage,
      totalPages,
      zoomLevel,
      scrollOffset,
      isLoading,
      error,
      lastUpdated,
    );
  }

  @override
  String toString() {
    return 'ReaderState(documentId: $documentId, '
           'currentPage: $currentPage, '
           'totalPages: $totalPages, '
           'zoomLevel: $zoomLevel, '
           'scrollOffset: $scrollOffset, '
           'isLoading: $isLoading, '
           'error: $error, '
           'lastUpdated: $lastUpdated)';
  }
}