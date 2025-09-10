import 'document.dart';

/// Represents a folder or document node in the library tree structure
class FolderNode {
  final String path;
  final String name;
  final bool isFolder;
  final List<FolderNode> children;
  final Document? document; // Only set if this is a document node
  final int documentCount; // Total documents in this folder and subfolders
  final bool isExpanded;
  final bool isLoading;

  const FolderNode({
    required this.path,
    required this.name,
    required this.isFolder,
    this.children = const [],
    this.document,
    this.documentCount = 0,
    this.isExpanded = false,
    this.isLoading = false,
  });

  FolderNode copyWith({
    String? path,
    String? name,
    bool? isFolder,
    List<FolderNode>? children,
    Document? document,
    int? documentCount,
    bool? isExpanded,
    bool? isLoading,
  }) {
    return FolderNode(
      path: path ?? this.path,
      name: name ?? this.name,
      isFolder: isFolder ?? this.isFolder,
      children: children ?? this.children,
      document: document ?? this.document,
      documentCount: documentCount ?? this.documentCount,
      isExpanded: isExpanded ?? this.isExpanded,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  /// Get the parent path of this node
  String? get parentPath {
    if (path == '/' || path.isEmpty) return null;
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return '/';
    return path.substring(0, lastSlash);
  }

  /// Get the depth level of this node (root is 0)
  int get depth {
    if (path == '/' || path.isEmpty) return 0;
    return path.split('/').where((part) => part.isNotEmpty).length;
  }

  /// Check if this node is a descendant of the given path
  bool isDescendantOf(String ancestorPath) {
    if (ancestorPath == '/') return path != '/';
    return path.startsWith('$ancestorPath/');
  }

  /// Check if this node is a direct child of the given path
  bool isDirectChildOf(String parentPath) {
    if (parentPath == '/') {
      return !path.substring(1).contains('/');
    }
    return path.startsWith('$parentPath/') && 
           !path.substring(parentPath.length + 1).contains('/');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FolderNode &&
        other.path == path &&
        other.name == name &&
        other.isFolder == isFolder &&
        other.children == children &&
        other.document == document &&
        other.documentCount == documentCount &&
        other.isExpanded == isExpanded &&
        other.isLoading == isLoading;
  }

  @override
  int get hashCode {
    return Object.hash(
      path,
      name,
      isFolder,
      children,
      document,
      documentCount,
      isExpanded,
      isLoading,
    );
  }

  @override
  String toString() {
    return 'FolderNode(path: $path, name: $name, isFolder: $isFolder, '
           'documentCount: $documentCount, isExpanded: $isExpanded, '
           'isLoading: $isLoading, children: ${children.length})';
  }
}

