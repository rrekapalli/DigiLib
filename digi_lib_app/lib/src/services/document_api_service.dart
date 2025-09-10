import '../network/api_client.dart';
import '../models/entities/document.dart';
import '../models/entities/page.dart';
import '../models/api/document_list_response.dart';
import '../models/api/update_document_request.dart';
import '../models/api/render_response.dart';
import '../models/api/pagination.dart';
import '../models/api/api_error.dart';

/// Service for handling document management API calls
abstract class DocumentApiService {
  /// Get documents with pagination, filtering, and search
  Future<DocumentListResponse> getDocuments({
    String? libraryId,
    String? search,
    List<String>? tags,
    int page = 1,
    int limit = 50,
  });
  
  /// Get a specific document by ID
  Future<Document> getDocument(String documentId);
  
  /// Update a document
  Future<Document> updateDocument(String documentId, UpdateDocumentRequest update);
  
  /// Delete a document
  Future<void> deleteDocument(String documentId);
  
  /// Get all pages for a document
  Future<List<Page>> getDocumentPages(String documentId);
  
  /// Get a specific page for a document
  Future<Page> getDocumentPage(String documentId, int pageNumber);
  
  /// Get text content for a specific page
  Future<String> getPageText(String documentId, int pageNumber);
  
  /// Get page render URL for server-side rendering
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  });
}

/// Implementation of DocumentApiService
class DocumentApiServiceImpl implements DocumentApiService {
  final ApiClient _apiClient;

  DocumentApiServiceImpl(this._apiClient);

  @override
  Future<DocumentListResponse> getDocuments({
    String? libraryId,
    String? search,
    List<String>? tags,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (libraryId != null) {
        queryParams['library_id'] = libraryId;
      }
      
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      if (tags != null && tags.isNotEmpty) {
        queryParams['tags'] = tags.join(',');
      }

      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/documents',
        queryParams: queryParams,
      );
      
      return DocumentListResponse.fromJson(response);
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get documents');
    }
  }

  @override
  Future<Document> getDocument(String documentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/documents/$documentId',
      );
      
      return Document.fromJson(response);
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get document');
    }
  }

  @override
  Future<Document> updateDocument(String documentId, UpdateDocumentRequest update) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/documents/$documentId',
        body: update.toJson(),
      );
      
      return Document.fromJson(response);
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to update document');
    }
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    try {
      await _apiClient.delete('/api/documents/$documentId');
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to delete document');
    }
  }

  @override
  Future<List<Page>> getDocumentPages(String documentId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/api/documents/$documentId/pages',
      );
      
      return response
          .map((json) => Page.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get document pages');
    }
  }

  @override
  Future<Page> getDocumentPage(String documentId, int pageNumber) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/documents/$documentId/pages/$pageNumber',
      );
      
      return Page.fromJson(response);
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get document page');
    }
  }

  @override
  Future<String> getPageText(String documentId, int pageNumber) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/documents/$documentId/pages/$pageNumber/text',
      );
      
      // The API returns the text content in a 'text' field
      return response['text'] as String? ?? '';
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get page text');
    }
  }

  @override
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/documents/$documentId/render',
        body: {
          'page': page,
          'dpi': dpi,
          'format': format,
        },
      );
      
      return RenderResponse.fromJson(response);
    } catch (e) {
      throw _handleDocumentError(e, 'Failed to get page render URL');
    }
  }

  /// Handle document-specific errors
  ApiException _handleDocumentError(Object error, String context) {
    if (error is ApiException) {
      // Add context to existing API exception
      return ApiException(
        error.error.copyWith(
          message: '${error.error.message} ($context)',
        ),
        error.originalMessage,
      );
    }

    // Create new API exception for other errors
    return ApiException(
      ApiError(
        message: '$context: ${error.toString()}',
        code: 'DOCUMENT_ERROR',
        timestamp: DateTime.now(),
      ),
      error.toString(),
    );
  }
}

/// Mock implementation for testing
class MockDocumentApiService implements DocumentApiService {
  final List<Document> _documents = [];
  final Map<String, List<Page>> _documentPages = {};

  MockDocumentApiService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Add some mock documents
    final now = DateTime.now();
    
    final doc1 = Document(
      id: 'mock-doc-1',
      libraryId: 'mock-library-1',
      title: 'Sample PDF Document',
      author: 'John Doe',
      filename: 'sample.pdf',
      relativePath: '/documents/sample.pdf',
      fullPath: '/home/user/documents/sample.pdf',
      extension: 'pdf',
      format: 'pdf',
      pageCount: 10,
      sizeBytes: 1024000,
      createdAt: now,
      updatedAt: now,
    );
    
    final doc2 = Document(
      id: 'mock-doc-2',
      libraryId: 'mock-library-1',
      title: 'Another Document',
      author: 'Jane Smith',
      filename: 'another.pdf',
      relativePath: '/documents/another.pdf',
      fullPath: '/home/user/documents/another.pdf',
      extension: 'pdf',
      format: 'pdf',
      pageCount: 5,
      sizeBytes: 512000,
      createdAt: now,
      updatedAt: now,
    );
    
    _documents.addAll([doc1, doc2]);
    
    // Add mock pages for documents
    _documentPages[doc1.id] = List.generate(
      doc1.pageCount ?? 0,
      (index) => Page(
        id: 'mock-page-${doc1.id}-${index + 1}',
        docId: doc1.id,
        pageNumber: index + 1,
        textContent: 'Sample text content for page ${index + 1}',
        createdAt: now,
      ),
    );
    
    _documentPages[doc2.id] = List.generate(
      doc2.pageCount ?? 0,
      (index) => Page(
        id: 'mock-page-${doc2.id}-${index + 1}',
        docId: doc2.id,
        pageNumber: index + 1,
        textContent: 'Sample text content for page ${index + 1}',
        createdAt: now,
      ),
    );
  }

  @override
  Future<DocumentListResponse> getDocuments({
    String? libraryId,
    String? search,
    List<String>? tags,
    int page = 1,
    int limit = 50,
  }) async {
    var filteredDocs = List<Document>.from(_documents);
    
    // Filter by library ID
    if (libraryId != null) {
      filteredDocs = filteredDocs
          .where((doc) => doc.libraryId == libraryId)
          .toList();
    }
    
    // Filter by search term
    if (search != null && search.isNotEmpty) {
      final searchLower = search.toLowerCase();
      filteredDocs = filteredDocs.where((doc) {
        return (doc.title?.toLowerCase().contains(searchLower) ?? false) ||
               (doc.author?.toLowerCase().contains(searchLower) ?? false) ||
               (doc.filename?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }
    
    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    final paginatedDocs = filteredDocs.length > startIndex
        ? filteredDocs.sublist(
            startIndex,
            endIndex > filteredDocs.length ? filteredDocs.length : endIndex,
          )
        : <Document>[];
    
    final pagination = Pagination(
      page: page,
      limit: limit,
      total: filteredDocs.length,
      totalPages: (filteredDocs.length / limit).ceil(),
    );
    
    return DocumentListResponse(
      documents: paginatedDocs,
      pagination: pagination,
    );
  }

  @override
  Future<Document> getDocument(String documentId) async {
    final document = _documents.firstWhere(
      (doc) => doc.id == documentId,
      orElse: () => throw ApiException(
        ApiError(
          message: 'Document not found',
          code: 'DOCUMENT_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      ),
    );
    
    return document;
  }

  @override
  Future<Document> updateDocument(String documentId, UpdateDocumentRequest update) async {
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    
    if (index == -1) {
      throw ApiException(
        ApiError(
          message: 'Document not found',
          code: 'DOCUMENT_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      );
    }
    
    final existingDoc = _documents[index];
    final updatedDoc = existingDoc.copyWith(
      title: update.title ?? existingDoc.title,
      author: update.author ?? existingDoc.author,
      renamedName: update.renamedName ?? existingDoc.renamedName,
      isbn: update.isbn ?? existingDoc.isbn,
      yearPublished: update.yearPublished ?? existingDoc.yearPublished,
      metadataJson: update.metadataJson ?? existingDoc.metadataJson,
      updatedAt: DateTime.now(),
    );
    
    _documents[index] = updatedDoc;
    return updatedDoc;
  }

  @override
  Future<void> deleteDocument(String documentId) async {
    final initialLength = _documents.length;
    _documents.removeWhere((doc) => doc.id == documentId);
    
    if (_documents.length == initialLength) {
      throw ApiException(
        ApiError(
          message: 'Document not found',
          code: 'DOCUMENT_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      );
    }
    
    // Also remove associated pages
    _documentPages.remove(documentId);
  }

  @override
  Future<List<Page>> getDocumentPages(String documentId) async {
    // Verify document exists
    await getDocument(documentId);
    
    return _documentPages[documentId] ?? [];
  }

  @override
  Future<Page> getDocumentPage(String documentId, int pageNumber) async {
    // Verify document exists
    await getDocument(documentId);
    
    final pages = _documentPages[documentId] ?? [];
    final page = pages.firstWhere(
      (p) => p.pageNumber == pageNumber,
      orElse: () => throw ApiException(
        ApiError(
          message: 'Page not found',
          code: 'PAGE_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      ),
    );
    
    return page;
  }

  @override
  Future<String> getPageText(String documentId, int pageNumber) async {
    final page = await getDocumentPage(documentId, pageNumber);
    return page.textContent ?? '';
  }

  @override
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  }) async {
    // Verify document exists
    await getDocument(documentId);
    
    // Return mock render response
    return RenderResponse(
      signedUrl: 'https://mock-api.example.com/render/$documentId/page/$page?dpi=$dpi&format=$format&token=mock-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  /// Add a mock document for testing
  void addMockDocument(Document document) {
    _documents.add(document);
  }

  /// Add mock pages for a document
  void addMockPages(String documentId, List<Page> pages) {
    _documentPages[documentId] = pages;
  }

  /// Clear all mock data
  void clearMockData() {
    _documents.clear();
    _documentPages.clear();
  }
}