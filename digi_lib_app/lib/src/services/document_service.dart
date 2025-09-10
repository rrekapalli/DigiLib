import 'dart:async';
import '../models/entities/document.dart';
import '../models/entities/tag.dart';
import '../database/repositories/document_repository.dart';
import '../database/repositories/tag_repository.dart';
import '../network/connectivity_service.dart';
import 'document_api_service.dart';

/// Exception thrown when document operations fail
class DocumentException implements Exception {
  final String message;
  final String? code;
  final Exception? cause;

  const DocumentException(this.message, {this.code, this.cause});

  @override
  String toString() => 'DocumentException: $message';
}

/// Service for managing documents with tag-based filtering and organization
class DocumentService {
  final DocumentApiService _apiService;
  final DocumentRepository _documentRepository;
  final TagRepository _tagRepository;
  final ConnectivityService _connectivityService;

  // Stream controllers for real-time updates
  final StreamController<List<Document>> _documentsController = StreamController<List<Document>>.broadcast();

  DocumentService({
    required DocumentApiService apiService,
    required DocumentRepository documentRepository,
    required TagRepository tagRepository,
    required ConnectivityService connectivityService,
  }) : _apiService = apiService,
       _documentRepository = documentRepository,
       _tagRepository = tagRepository,
       _connectivityService = connectivityService;

  /// Stream of document lists (for UI updates)
  Stream<List<Document>> get documentsStream => _documentsController.stream;

  /// Get documents with tag-based filtering
  Future<List<Document>> getDocuments({
    String? libraryId,
    String? search,
    List<String>? tagIds,
    String? author,
    String? format,
    int? yearPublished,
    String? status,
    String? sortBy = 'title',
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      final query = DocumentQuery(
        libraryId: libraryId,
        search: search,
        tagIds: tagIds,
        author: author,
        format: format,
        yearPublished: yearPublished,
        status: status,
        sortBy: sortBy,
        ascending: ascending,
        limit: limit,
        offset: offset,
      );

      // Always return local data first for immediate UI response
      final localDocuments = await _documentRepository.findAll(query: query);
      
      // If online, try to sync with server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverResponse = await _apiService.getDocuments(
            libraryId: libraryId,
            search: search,
            tags: tagIds,
            page: offset != null && limit != null ? (offset ~/ limit) + 1 : 1,
            limit: limit ?? 50,
          );
          
          // Update local cache with server data
          await _syncDocumentsToLocal(serverResponse.documents);
          
          // Return updated local data
          final updatedDocuments = await _documentRepository.findAll(query: query);
          _documentsController.add(updatedDocuments);
          return updatedDocuments;
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      _documentsController.add(localDocuments);
      return localDocuments;
    } catch (e) {
      throw DocumentException('Failed to get documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents by tag ID with pagination
  Future<List<Document>> getDocumentsByTag(String tagId, {int? limit, int? offset}) async {
    try {
      // Always return local data first
      final localDocuments = await _documentRepository.findByTagId(tagId, limit: limit, offset: offset);
      
      // If online, try to get server data
      if (await _connectivityService.hasConnectivity()) {
        try {
          final page = offset != null && limit != null ? (offset ~/ limit) + 1 : 1;
          final serverDocuments = await _tagRepository.getDocumentsByTag(tagId);
          
          // Note: Server documents are returned directly as they may have more up-to-date data
          return serverDocuments;
        } catch (e) {
          // If server request fails, continue with local data
        }
      }
      
      return localDocuments;
    } catch (e) {
      throw DocumentException('Failed to get documents by tag: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents that have ALL specified tags
  Future<List<Document>> getDocumentsByAllTags(List<String> tagIds) async {
    try {
      return await _documentRepository.findByAllTags(tagIds);
    } catch (e) {
      throw DocumentException('Failed to get documents by all tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get documents that have ANY of the specified tags
  Future<List<Document>> getDocumentsByAnyTags(List<String> tagIds) async {
    try {
      return await _documentRepository.findByAnyTags(tagIds);
    } catch (e) {
      throw DocumentException('Failed to get documents by any tags: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get untagged documents
  Future<List<Document>> getUntaggedDocuments({int? limit, int? offset}) async {
    try {
      return await _documentRepository.findUntaggedDocuments(limit: limit, offset: offset);
    } catch (e) {
      throw DocumentException('Failed to get untagged documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get document count with optional filtering
  Future<int> getDocumentCount({
    String? libraryId,
    String? search,
    List<String>? tagIds,
    String? author,
    String? format,
    int? yearPublished,
    String? status,
  }) async {
    try {
      final query = DocumentQuery(
        libraryId: libraryId,
        search: search,
        tagIds: tagIds,
        author: author,
        format: format,
        yearPublished: yearPublished,
        status: status,
      );

      return await _documentRepository.getCount(query: query);
    } catch (e) {
      throw DocumentException('Failed to get document count: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get document count by tag
  Future<int> getDocumentCountByTag(String tagId) async {
    try {
      return await _documentRepository.getDocumentCountByTag(tagId);
    } catch (e) {
      throw DocumentException('Failed to get document count by tag: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Search documents with full-text search
  Future<List<Document>> searchDocuments(String query) async {
    try {
      // Use local FTS search first
      final localResults = await _documentRepository.search(query);
      
      // If online, try to get server search results
      if (await _connectivityService.hasConnectivity()) {
        try {
          // Note: This would require a search endpoint in DocumentApiService
          // For now, we'll use the local search results
        } catch (e) {
          // If server search fails, continue with local results
        }
      }
      
      return localResults;
    } catch (e) {
      throw DocumentException('Failed to search documents: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get filter options for documents
  Future<DocumentFilterOptions> getFilterOptions() async {
    try {
      final authors = await _documentRepository.getAuthors();
      final formats = await _documentRepository.getFormats();
      final yearRange = await _documentRepository.getYearRange();
      final allTags = await _tagRepository.getAllTags();

      return DocumentFilterOptions(
        authors: authors,
        formats: formats,
        minYear: yearRange['min'],
        maxYear: yearRange['max'],
        availableTags: allTags,
      );
    } catch (e) {
      throw DocumentException('Failed to get filter options: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Get a specific document by ID
  Future<Document?> getDocument(String documentId) async {
    try {
      // Try local first
      final localDocument = await _documentRepository.findById(documentId);
      
      // If online, try to get latest from server
      if (await _connectivityService.hasConnectivity()) {
        try {
          final serverDocument = await _apiService.getDocument(documentId);
          
          // Update local cache
          await _documentRepository.save(serverDocument);
          
          return serverDocument;
        } catch (e) {
          // If server request fails, return local data
        }
      }
      
      return localDocument;
    } catch (e) {
      throw DocumentException('Failed to get document: ${e.toString()}', cause: e is Exception ? e : null);
    }
  }

  /// Sync server documents to local database
  Future<void> _syncDocumentsToLocal(List<Document> serverDocuments) async {
    await _documentRepository.saveAll(serverDocuments);
  }

  /// Dispose resources
  void dispose() {
    _documentsController.close();
  }
}

/// Filter options for document queries
class DocumentFilterOptions {
  final List<String> authors;
  final List<String> formats;
  final int? minYear;
  final int? maxYear;
  final List<Tag> availableTags;

  const DocumentFilterOptions({
    required this.authors,
    required this.formats,
    this.minYear,
    this.maxYear,
    required this.availableTags,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DocumentFilterOptions &&
        other.authors == authors &&
        other.formats == formats &&
        other.minYear == minYear &&
        other.maxYear == maxYear &&
        other.availableTags == availableTags;
  }

  @override
  int get hashCode => Object.hash(
    authors,
    formats,
    minYear,
    maxYear,
    availableTags,
  );

  @override
  String toString() {
    return 'DocumentFilterOptions(authors: $authors, formats: $formats, '
           'minYear: $minYear, maxYear: $maxYear, availableTags: $availableTags)';
  }
}