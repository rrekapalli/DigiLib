import '../models/entities/tag.dart';
import '../models/entities/document.dart';
import '../models/api/create_tag_request.dart';
import '../network/api_client.dart';

/// API service for tag operations with the backend
class TagApiService {
  final ApiClient _apiClient;

  TagApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all tags for the current user
  /// API: GET /api/tags
  Future<List<Tag>> getTags() async {
    final response = await _apiClient.get<List<dynamic>>('/api/tags');
    return response.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Create a new tag
  /// API: POST /api/tags
  Future<Tag> createTag(CreateTagRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/tags',
      body: request.toJson(),
    );
    return Tag.fromJson(response);
  }

  /// Delete a tag
  /// API: DELETE /api/tags/{tagId}
  Future<void> deleteTag(String tagId) async {
    await _apiClient.delete<void>('/api/tags/$tagId');
  }

  /// Get a specific tag by ID
  /// API: GET /api/tags/{tagId}
  Future<Tag> getTag(String tagId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/api/tags/$tagId');
    return Tag.fromJson(response);
  }

  /// Add tag to document
  /// API: POST /api/documents/{documentId}/tags
  Future<void> addTagToDocument(String documentId, AddTagToDocumentRequest request) async {
    await _apiClient.post<void>(
      '/api/documents/$documentId/tags',
      body: request.toJson(),
    );
  }

  /// Remove tag from document
  /// API: DELETE /api/documents/{documentId}/tags/{tagId}
  Future<void> removeTagFromDocument(String documentId, String tagId) async {
    await _apiClient.delete<void>('/api/documents/$documentId/tags/$tagId');
  }

  /// Get tags for a specific document
  /// API: GET /api/documents/{documentId}/tags
  Future<List<Tag>> getDocumentTags(String documentId) async {
    final response = await _apiClient.get<List<dynamic>>('/api/documents/$documentId/tags');
    return response.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get documents for a specific tag
  /// API: GET /api/tags/{tagId}/documents
  Future<List<Document>> getDocumentsByTag(String tagId, {
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.get<List<dynamic>>(
      '/api/tags/$tagId/documents',
      queryParams: queryParams,
    );
    return response.map((json) => Document.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Search tags by name
  /// API: GET /api/tags/search
  Future<List<Tag>> searchTags(String query, {int limit = 20}) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'limit': limit,
    };

    final response = await _apiClient.get<List<dynamic>>(
      '/api/tags/search',
      queryParams: queryParams,
    );
    return response.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get popular tags (most used)
  /// API: GET /api/tags/popular
  Future<List<Tag>> getPopularTags({int limit = 10}) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };

    final response = await _apiClient.get<List<dynamic>>(
      '/api/tags/popular',
      queryParams: queryParams,
    );
    return response.map((json) => Tag.fromJson(json as Map<String, dynamic>)).toList();
  }
}