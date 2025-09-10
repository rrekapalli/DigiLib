/// Enumeration for document view modes
enum DocumentViewMode {
  list,
  grid,
}

/// Enumeration for document sorting options
enum DocumentSortBy {
  name,
  author,
  dateCreated,
  dateModified,
  size,
  pageCount,
}

/// Document view settings for UI preferences
class DocumentViewSettings {
  final DocumentViewMode viewMode;
  final DocumentSortBy sortBy;
  final bool ascending;
  final bool showThumbnails;
  final bool showMetadata;
  final int gridColumns;

  const DocumentViewSettings({
    this.viewMode = DocumentViewMode.list,
    this.sortBy = DocumentSortBy.name,
    this.ascending = true,
    this.showThumbnails = true,
    this.showMetadata = true,
    this.gridColumns = 2,
  });

  DocumentViewSettings copyWith({
    DocumentViewMode? viewMode,
    DocumentSortBy? sortBy,
    bool? ascending,
    bool? showThumbnails,
    bool? showMetadata,
    int? gridColumns,
  }) {
    return DocumentViewSettings(
      viewMode: viewMode ?? this.viewMode,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      showThumbnails: showThumbnails ?? this.showThumbnails,
      showMetadata: showMetadata ?? this.showMetadata,
      gridColumns: gridColumns ?? this.gridColumns,
    );
  }

  /// Get display name for sort option
  String getSortDisplayName() {
    switch (sortBy) {
      case DocumentSortBy.name:
        return 'Name';
      case DocumentSortBy.author:
        return 'Author';
      case DocumentSortBy.dateCreated:
        return 'Date Created';
      case DocumentSortBy.dateModified:
        return 'Date Modified';
      case DocumentSortBy.size:
        return 'Size';
      case DocumentSortBy.pageCount:
        return 'Page Count';
    }
  }

  /// Get sort direction display name
  String getSortDirectionDisplayName() {
    return ascending ? 'Ascending' : 'Descending';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentViewSettings &&
        other.viewMode == viewMode &&
        other.sortBy == sortBy &&
        other.ascending == ascending &&
        other.showThumbnails == showThumbnails &&
        other.showMetadata == showMetadata &&
        other.gridColumns == gridColumns;
  }

  @override
  int get hashCode {
    return Object.hash(
      viewMode,
      sortBy,
      ascending,
      showThumbnails,
      showMetadata,
      gridColumns,
    );
  }

  @override
  String toString() {
    return 'DocumentViewSettings(viewMode: $viewMode, sortBy: $sortBy, '
           'ascending: $ascending, showThumbnails: $showThumbnails, '
           'showMetadata: $showMetadata, gridColumns: $gridColumns)';
  }
}