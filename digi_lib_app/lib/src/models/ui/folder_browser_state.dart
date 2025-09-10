import '../entities/folder_node.dart';

/// State for folder browser functionality
class FolderBrowserState {
  final String currentPath;
  final List<String> breadcrumbs;
  final List<FolderNode> currentNodes;
  final bool isLoading;
  final String? error;
  final Set<String> selectedPaths;
  final bool isMultiSelectMode;

  const FolderBrowserState({
    this.currentPath = '/',
    this.breadcrumbs = const ['/'],
    this.currentNodes = const [],
    this.isLoading = false,
    this.error,
    this.selectedPaths = const {},
    this.isMultiSelectMode = false,
  });

  FolderBrowserState copyWith({
    String? currentPath,
    List<String>? breadcrumbs,
    List<FolderNode>? currentNodes,
    bool? isLoading,
    String? error,
    Set<String>? selectedPaths,
    bool? isMultiSelectMode,
  }) {
    return FolderBrowserState(
      currentPath: currentPath ?? this.currentPath,
      breadcrumbs: breadcrumbs ?? this.breadcrumbs,
      currentNodes: currentNodes ?? this.currentNodes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPaths: selectedPaths ?? this.selectedPaths,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
    );
  }

  /// Generate breadcrumbs from a folder path
  static List<String> generateBreadcrumbs(String path) {
    if (path == '/' || path.isEmpty) {
      return ['/'];
    }

    final parts = path.split('/').where((part) => part.isNotEmpty).toList();
    final breadcrumbs = <String>['/'];
    
    String currentPath = '';
    for (final part in parts) {
      currentPath += '/$part';
      breadcrumbs.add(currentPath);
    }
    
    return breadcrumbs;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderBrowserState &&
        other.currentPath == currentPath &&
        other.breadcrumbs == breadcrumbs &&
        other.currentNodes == currentNodes &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.selectedPaths == selectedPaths &&
        other.isMultiSelectMode == isMultiSelectMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentPath,
      breadcrumbs,
      currentNodes,
      isLoading,
      error,
      selectedPaths,
      isMultiSelectMode,
    );
  }

  @override
  String toString() {
    return 'FolderBrowserState(currentPath: $currentPath, '
           'breadcrumbs: $breadcrumbs, '
           'currentNodes: ${currentNodes.length} items, '
           'isLoading: $isLoading, '
           'error: $error, '
           'selectedPaths: ${selectedPaths.length} selected, '
           'isMultiSelectMode: $isMultiSelectMode)';
  }
}