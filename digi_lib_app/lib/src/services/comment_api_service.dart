import '../models/entities/comment.dart';
import '../models/api/create_comment_request.dart';
import '../models/api/update_comment_request.dart';
import '../network/api_client.dart';

/// API service for comment operations with the backend
class CommentApiService {
  final ApiClient _apiClient;

  CommentApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get all comments for a specific document
  /// API: GET /api/documents/{documentId}/comments
  Future<List<Comment>> getComments(String documentId, {int? pageNumber}) async {
    final queryParams = <String, dynamic>{};
    if (pageNumber != null) {
      queryParams['page_number'] = pageNumber;
    }

    final response = await _apiClient.get<List<dynamic>>(
      '/api/documents/$documentId/comments',
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    
    return response.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add a new comment to a document
  /// API: POST /api/documents/{documentId}/comments
  Future<Comment> addComment(String documentId, CreateCommentRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/documents/$documentId/comments',
      body: request.toJson(),
    );
    
    return Comment.fromJson(response);
  }

  /// Update an existing comment
  /// API: PUT /api/comments/{commentId}
  Future<Comment> updateComment(String commentId, UpdateCommentRequest request) async {
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/comments/$commentId',
      body: request.toJson(),
    );
    
    return Comment.fromJson(response);
  }

  /// Delete a comment
  /// API: DELETE /api/comments/{commentId}
  Future<void> deleteComment(String commentId) async {
    await _apiClient.delete<void>('/api/comments/$commentId');
  }

  /// Get a specific comment by ID
  /// API: GET /api/comments/{commentId}
  Future<Comment> getComment(String commentId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/comments/$commentId',
    );
    
    return Comment.fromJson(response);
  }

  /// Get all comments for the current user
  /// API: GET /api/comments/user
  Future<List<Comment>> getUserComments({
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
      '/api/comments/user',
      queryParams: queryParams,
    );
    
    return response.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get comments for a specific page of a document
  /// API: GET /api/documents/{documentId}/pages/{pageNumber}/comments
  Future<List<Comment>> getPageComments(String documentId, int pageNumber) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/documents/$documentId/pages/$pageNumber/comments',
    );
    
    return response.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Search comments by content
  /// API: GET /api/comments/search
  Future<List<Comment>> searchComments(String query, {
    String? documentId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'page': page,
      'limit': limit,
    };
    
    if (documentId != null) {
      queryParams['document_id'] = documentId;
    }
    
    final response = await _apiClient.get<List<dynamic>>(
      '/api/comments/search',
      queryParams: queryParams,
    );
    
    return response.map((json) => Comment.fromJson(json as Map<String, dynamic>)).toList();
  }
}