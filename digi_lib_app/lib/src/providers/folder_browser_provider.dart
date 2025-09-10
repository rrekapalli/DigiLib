import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/folder_node.dart';
import '../models/entities/document.dart';
import '../models/ui/folder_browser_state.dart' hide FolderBrowserState;
import '../models/ui/folder_browser_state.dart' as ui;
import '../services/folder_service.dart';
import '../services/document_service.dart';
import '../database/repositories/document_repository.dart';
import 'document_provider.dart';

/// Provider for FolderService
final folderServiceProvider = Provider<FolderService>((ref) {
  final documentRepository = ref.watch(documentRepositoryProvider);
  return FolderService(documentRepository: documentRepository);
});

// DocumentRepository provider is imported from document_provider.dart

/// State notifier for folder browser functionality
class FolderBrowserNotifier extends StateNotifier<ui.FolderBrowserState> {
  final FolderService _folderService;
  final DocumentService _documentService;
  String? _currentLibraryId;

  FolderBrowserNotifier({
    required FolderService folderService,
    required DocumentService documentService,
  }) : _folderService = folderService,
       _documentService = documentService,
       super(const ui.FolderBrowserState());

  /// Initialize folder browser for a specific library
  Future<void> initializeLibrary(String libraryId) async {
    if (_currentLibraryId == libraryId && state.currentNodes.isNotEmpty) {
      return; // Already initialized for this library
    }

    _currentLibraryId = libraryId;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final rootNodes = await _folderService.getFolderContents(libraryId, '/');
      state = state.copyWith(
        currentPath: '/',
        breadcrumbs: ['/'],
        currentNodes: rootNodes,
        isLoading: false,
        selectedPaths: {},
        isMultiSelectMode: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Navigate to a specific folder
  Future<void> navigateToFolder(String folderPath) async {
    if (_currentLibraryId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final folderNodes = await _folderService.getFolderContents(_currentLibraryId!, folderPath);
      final breadcrumbs = ui.FolderBrowserState.generateBreadcrumbs(folderPath);
      
      state = state.copyWith(
        currentPath: folderPath,
        breadcrumbs: breadcrumbs,
        currentNodes: folderNodes,
        isLoading: false,
        selectedPaths: {},
        isMultiSelectMode: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Navigate up one level in the folder hierarchy
  Future<void> navigateUp() async {
    final currentPath = state.currentPath;
    if (currentPath == '/' || currentPath.isEmpty) return;

    final parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
    final targetPath = parentPath.isEmpty ? '/' : parentPath;
    
    await navigateToFolder(targetPath);
  }

  /// Navigate to a specific breadcrumb level
  Future<void> navigateToBreadcrumb(String path) async {
    await navigateToFolder(path);
  }

  /// Toggle multi-select mode
  void toggleMultiSelectMode() {
    state = state.copyWith(
      isMultiSelectMode: !state.isMultiSelectMode,
      selectedPaths: {},
    );
  }

  /// Toggle selection of a node
  void toggleNodeSelection(String nodePath) {
    if (!state.isMultiSelectMode) return;

    final selectedPaths = Set<String>.from(state.selectedPaths);
    if (selectedPaths.contains(nodePath)) {
      selectedPaths.remove(nodePath);
    } else {
      selectedPaths.add(nodePath);
    }

    state = state.copyWith(selectedPaths: selectedPaths);
  }

  /// Select all nodes in current folder
  void selectAll() {
    if (!state.isMultiSelectMode) return;

    final allPaths = state.currentNodes.map((node) => node.path).toSet();
    state = state.copyWith(selectedPaths: allPaths);
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(selectedPaths: {});
  }

  /// Get documents in current folder
  Future<List<Document>> getCurrentFolderDocuments() async {
    if (_currentLibraryId == null) return [];

    try {
      return await _folderService.getDocumentsInFolder(_currentLibraryId!, state.currentPath);
    } catch (e) {
      return [];
    }
  }

  /// Search within current library
  Future<void> searchInLibrary(String query) async {
    if (_currentLibraryId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      if (query.isEmpty) {
        // Reset to current folder view
        await navigateToFolder(state.currentPath);
      } else {
        // Perform search
        final searchResults = await _folderService.searchFolderStructure(_currentLibraryId!, query);
        state = state.copyWith(
          currentNodes: searchResults,
          isLoading: false,
          selectedPaths: {},
          isMultiSelectMode: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh current folder
  Future<void> refresh() async {
    if (_currentLibraryId == null) return;

    // Clear cache and reload
    _folderService.clearCache(_currentLibraryId!);
    await navigateToFolder(state.currentPath);
  }

  /// Get selected documents
  List<Document> getSelectedDocuments() {
    return state.currentNodes
        .where((node) => !node.isFolder && 
                        state.selectedPaths.contains(node.path) && 
                        node.document != null)
        .map((node) => node.document!)
        .toList();
  }

  /// Get selected folders
  List<FolderNode> getSelectedFolders() {
    return state.currentNodes
        .where((node) => node.isFolder && state.selectedPaths.contains(node.path))
        .toList();
  }

  /// Check if any items are selected
  bool get hasSelection => state.selectedPaths.isNotEmpty;

  /// Check if all items are selected
  bool get isAllSelected => 
      state.currentNodes.isNotEmpty && 
      state.selectedPaths.length == state.currentNodes.length;

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for folder browser state
final folderBrowserProvider = StateNotifierProvider<FolderBrowserNotifier, ui.FolderBrowserState>((ref) {
  final folderService = ref.watch(folderServiceProvider);
  final documentService = ref.watch(documentServiceProvider);
  
  return FolderBrowserNotifier(
    folderService: folderService,
    documentService: documentService,
  );
});

/// Provider for DocumentService
final documentServiceProvider = Provider<DocumentService>((ref) {
  // This should be properly injected with dependencies
  // For now, we'll create a minimal version
  throw UnimplementedError('DocumentService provider needs to be properly implemented with dependencies');
});