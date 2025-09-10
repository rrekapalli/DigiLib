import 'dart:async';
import '../models/entities/document.dart';
import '../models/entities/folder_node.dart';
import '../database/repositories/document_repository.dart';

/// Exception thrown when folder operations fail
class FolderException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const FolderException(this.message, {this.code, this.cause});

  @override
  String toString() => 'FolderException: $message';
}

/// Service for managing folder structure and navigation
class FolderService {
  final DocumentRepository _documentRepository;

  // Cache for folder structures to avoid repeated database queries
  final Map<String, List<FolderNode>> _folderCache = {};
  final Map<String, int> _documentCountCache = {};

  FolderService({
    required DocumentRepository documentRepository,
  }) : _documentRepository = documentRepository;

  /// Build folder structure from documents in a library
  Future<List<FolderNode>> buildFolderStructure(String libraryId) async {
    try {
      // Check cache first
      final cacheKey = 'library_$libraryId';
      if (_folderCache.containsKey(cacheKey)) {
        return _folderCache[cacheKey]!;
      }

      // Get all documents for the library
      final documents = await _documentRepository.findAll(
        query: DocumentQuery(libraryId: libraryId),
      );

      // Build folder tree from document paths
      final folderTree = _buildTreeFromDocuments(documents);
      
      // Cache the result
      _folderCache[cacheKey] = folderTree;
      
      return folderTree;
    } catch (e) {
      throw FolderException('Failed to build folder structure: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get folder contents for a specific path
  Future<List<FolderNode>> getFolderContents(String libraryId, String folderPath) async {
    try {
      final allNodes = await buildFolderStructure(libraryId);
      
      if (folderPath == '/' || folderPath.isEmpty) {
        // Return root level nodes
        return allNodes.where((node) => node.isDirectChildOf('/')).toList();
      }
      
      // Find the target folder and return its children
      final targetFolder = _findNodeByPath(allNodes, folderPath);
      if (targetFolder != null && targetFolder.isFolder) {
        return targetFolder.children;
      }
      
      // If folder not found, return empty list
      return [];
    } catch (e) {
      throw FolderException('Failed to get folder contents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents in a specific folder (non-recursive)
  Future<List<Document>> getDocumentsInFolder(String libraryId, String folderPath) async {
    try {
      final documents = await _documentRepository.findAll(
        query: DocumentQuery(libraryId: libraryId),
      );

      // Filter documents that are directly in this folder
      return documents.where((doc) {
        final docPath = doc.relativePath ?? '';
        if (folderPath == '/' || folderPath.isEmpty) {
          // Root folder - documents with no path separator or only filename
          return !docPath.contains('/') || docPath.startsWith('./');
        } else {
          // Specific folder - documents that start with folder path
          final normalizedFolderPath = folderPath.endsWith('/') ? folderPath : '$folderPath/';
          return docPath.startsWith(normalizedFolderPath) &&
                 !docPath.substring(normalizedFolderPath.length).contains('/');
        }
      }).toList();
    } catch (e) {
      throw FolderException('Failed to get documents in folder: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get document count for a folder (recursive)
  Future<int> getDocumentCount(String libraryId, String folderPath) async {
    try {
      final cacheKey = '${libraryId}_$folderPath';
      if (_documentCountCache.containsKey(cacheKey)) {
        return _documentCountCache[cacheKey]!;
      }

      final documents = await _documentRepository.findAll(
        query: DocumentQuery(libraryId: libraryId),
      );

      int count = 0;
      if (folderPath == '/' || folderPath.isEmpty) {
        // Count all documents in library
        count = documents.length;
      } else {
        // Count documents in this folder and subfolders
        final normalizedFolderPath = folderPath.endsWith('/') ? folderPath : '$folderPath/';
        count = documents.where((doc) {
          final docPath = doc.relativePath ?? '';
          return docPath.startsWith(normalizedFolderPath);
        }).length;
      }

      _documentCountCache[cacheKey] = count;
      return count;
    } catch (e) {
      throw FolderException('Failed to get document count: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Search for folders and documents matching a query
  Future<List<FolderNode>> searchFolderStructure(String libraryId, String searchQuery) async {
    try {
      final documents = await _documentRepository.findAll(
        query: DocumentQuery(libraryId: libraryId, search: searchQuery),
      );

      // Build a filtered tree with only matching documents and their parent folders
      return _buildTreeFromDocuments(documents);
    } catch (e) {
      throw FolderException('Failed to search folder structure: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Clear cache for a specific library
  void clearCache(String libraryId) {
    final cacheKey = 'library_$libraryId';
    _folderCache.remove(cacheKey);
    
    // Clear document count cache for this library
    _documentCountCache.removeWhere((key, value) => key.startsWith('${libraryId}_'));
  }

  /// Clear all caches
  void clearAllCaches() {
    _folderCache.clear();
    _documentCountCache.clear();
  }

  /// Build folder tree from a list of documents
  List<FolderNode> _buildTreeFromDocuments(List<Document> documents) {
    final Map<String, FolderNode> nodeMap = {};
    final Set<String> folderPaths = {};

    // First pass: collect all folder paths
    for (final document in documents) {
      final relativePath = document.relativePath ?? '';
      if (relativePath.isNotEmpty && relativePath != './') {
        final pathParts = relativePath.split('/').where((part) => part.isNotEmpty && part != '.').toList();
        
        // Add all parent folder paths
        String currentPath = '';
        for (int i = 0; i < pathParts.length - 1; i++) {
          currentPath += '/${pathParts[i]}';
          folderPaths.add(currentPath);
        }
      }
    }

    // Second pass: create folder nodes
    for (final folderPath in folderPaths) {
      final pathParts = folderPath.split('/').where((part) => part.isNotEmpty).toList();
      final folderName = pathParts.isNotEmpty ? pathParts.last : 'Root';
      
      nodeMap[folderPath] = FolderNode(
        path: folderPath,
        name: folderName,
        isFolder: true,
        children: [],
      );
    }

    // Third pass: create document nodes
    for (final document in documents) {
      final relativePath = document.relativePath ?? '';
      final documentName = document.renamedName ?? document.filename ?? document.title ?? 'Unknown';
      
      String documentPath;
      if (relativePath.isEmpty || relativePath == './') {
        documentPath = '/$documentName';
      } else {
        documentPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
      }
      
      nodeMap[documentPath] = FolderNode(
        path: documentPath,
        name: documentName,
        isFolder: false,
        document: document,
      );
    }

    // Fourth pass: build parent-child relationships
    final Map<String, List<FolderNode>> childrenMap = {};
    
    for (final node in nodeMap.values) {
      final parentPath = node.parentPath;
      if (parentPath != null) {
        childrenMap.putIfAbsent(parentPath, () => []).add(node);
      }
    }

    // Update nodes with their children
    final updatedNodeMap = <String, FolderNode>{};
    for (final entry in nodeMap.entries) {
      final children = childrenMap[entry.key] ?? [];
      children.sort((a, b) {
        // Folders first, then documents, both alphabetically
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      
      updatedNodeMap[entry.key] = entry.value.copyWith(
        children: children,
        documentCount: _calculateDocumentCount(entry.value, childrenMap),
      );
    }

    // Return root level nodes
    final rootNodes = updatedNodeMap.values
        .where((node) => node.isDirectChildOf('/'))
        .toList();
    
    rootNodes.sort((a, b) {
      // Folders first, then documents, both alphabetically
      if (a.isFolder && !b.isFolder) return -1;
      if (!a.isFolder && b.isFolder) return 1;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return rootNodes;
  }

  /// Calculate document count for a node (recursive)
  int _calculateDocumentCount(FolderNode node, Map<String, List<FolderNode>> childrenMap) {
    if (!node.isFolder) return 1;
    
    int count = 0;
    final children = childrenMap[node.path] ?? [];
    for (final child in children) {
      count += _calculateDocumentCount(child, childrenMap);
    }
    return count;
  }

  /// Find a node by its path in the tree
  FolderNode? _findNodeByPath(List<FolderNode> nodes, String path) {
    for (final node in nodes) {
      if (node.path == path) return node;
      
      final found = _findNodeByPath(node.children, path);
      if (found != null) return found;
    }
    return null;
  }
}