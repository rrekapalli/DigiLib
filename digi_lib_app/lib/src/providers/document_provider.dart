import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/document.dart';
import '../models/api/update_document_request.dart';
import '../services/document_service.dart';
import '../services/document_api_service.dart';
import '../database/repositories/document_repository.dart';
import '../database/repositories/tag_repository.dart';
import '../network/connectivity_service.dart';

/// Provider for document service
final documentServiceProvider = Provider<DocumentService>((ref) {
  final apiService = ref.watch(documentApiServiceProvider);
  final documentRepository = ref.watch(documentRepositoryProvider);
  final tagRepository = ref.watch(tagRepositoryProvider);
  
  return DocumentService(
    apiService: apiService,
    documentRepository: documentRepository,
    tagRepository: tagRepository,
    connectivityService: ConnectivityService.instance,
  );
});

/// Provider for document API service
final documentApiServiceProvider = Provider<DocumentApiService>((ref) {
  // For now, return mock implementation
  // In production, this would use the real API client
  return MockDocumentApiService();
});

/// Provider for document repository
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository();
});

/// Provider for tag repository
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository();
});

/// Provider for connectivity state
final connectivityStateProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

/// State notifier for managing document operations
class DocumentNotifier extends StateNotifier<AsyncValue<Document?>> {
  final DocumentService _documentService;
  
  DocumentNotifier(this._documentService) : super(const AsyncValue.data(null));

  /// Set document directly (for initial data)
  void setDocument(Document? document) {
    state = AsyncValue.data(document);
  }

  /// Load a document by ID
  Future<void> loadDocument(String documentId) async {
    state = const AsyncValue.loading();
    
    try {
      final document = await _documentService.getDocument(documentId);
      state = AsyncValue.data(document);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Update document metadata
  Future<void> updateDocument(String documentId, UpdateDocumentRequest request) async {
    if (state.value == null) return;
    
    state = const AsyncValue.loading();
    
    try {
      // For now, we'll create a mock update since the service doesn't expose the API service
      // In a real implementation, DocumentService would have update methods
      final mockApiService = MockDocumentApiService();
      final updatedDocument = await mockApiService.updateDocument(documentId, request);
      state = AsyncValue.data(updatedDocument);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Delete document
  Future<void> deleteDocument(String documentId) async {
    if (state.value == null) return;
    
    try {
      // For now, we'll create a mock delete since the service doesn't expose the API service
      // In a real implementation, DocumentService would have delete methods
      final mockApiService = MockDocumentApiService();
      await mockApiService.deleteDocument(documentId);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Refresh current document
  Future<void> refresh() async {
    final currentDocument = state.value;
    if (currentDocument != null) {
      await loadDocument(currentDocument.id);
    }
  }
}

/// Provider for document notifier
final documentNotifierProvider = StateNotifierProvider<DocumentNotifier, AsyncValue<Document?>>((ref) {
  final documentService = ref.watch(documentServiceProvider);
  return DocumentNotifier(documentService);
});

/// Provider for a specific document
final documentProvider = FutureProvider.family<Document?, String>((ref, documentId) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocument(documentId);
});

/// Provider for documents list with filtering
final documentsProvider = FutureProvider.family<List<Document>, DocumentQuery>((ref, query) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocuments(
    libraryId: query.libraryId,
    search: query.search,
    tagIds: query.tagIds,
    author: query.author,
    format: query.format,
    yearPublished: query.yearPublished,
    status: query.status,
    sortBy: query.sortBy,
    ascending: query.ascending,
    limit: query.limit,
    offset: query.offset,
  );
});

