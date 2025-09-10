import '../models/entities/bookmark.dart';
import '../models/api/create_bookmark_request.dart';
import '../models/api/update_bookmark_request.dart';
import '../network/api_client.dart';

/// API service for bookmark operations with the backend
class BookmarkApiService {
  final ApiClient _apiClient;

  BookmarkApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all bookmarks for a specific document
  /// API: GET /api/documents/{documentId}/bookmarks
  Future<List<Bookmark>> getBookmarks(String documentId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/documents/$documentId/bookmarks',
    );
    
    return response.map((json) => Bookmark.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add a new bookmark to a document
  /// API: POST /api/documents/{documentId}/bookmarks
  Future<Bookmark> addBookmark(String documentId, CreateBookmarkRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/documents/$documentId/bookmarks',
      body: request.toJson(),
    );
    
    return Bookmark.fromJson(response);
  }

  /// Update an existing bookmark
  /// API: PUT /api/bookmarks/{bookmarkId}
  Future<Bookmark> updateBookmark(String bookmarkId, UpdateBookmarkRequest request) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/bookmarks/$bookmarkId',
      body: request.toJson(),
    );
    
    return Bookmark.fromJson(response);
  }

  /// Delete a bookmark
  /// API: DELETE /api/bookmarks/{bookmarkId}
  Future<void> deleteBookmark(String bookmarkId) async {
    await _apiClient.delete<void>('/api/bookmarks/$bookmarkId');
  }

  /// Get a specific bookmark by ID
  /// API: GET /api/bookmarks/{bookmarkId}
  Future<Bookmark> getBookmark(String bookmarkId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/bookmarks/$bookmarkId',
    );
    
    return Bookmark.fromJson(response);
  }

  /// Get all bookmarks for the current user
  /// API: GET /api/bookmarks
  Future<List<Bookmark>> getUserBookmarks({
    int page = 1,
    int limit = 50,
    String? documentId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    if (documentId != null) {
      queryParams['document_id'] = documentId;
    }
    
    final response = await _apiClient.get<List<dynamic>>(
      '/api/bookmarks',
      queryParams: queryParams,
    );
    
    return response.map((json) => Bookmark.fromJson(json as Map<String, dynamic>)).toList();
  }
}