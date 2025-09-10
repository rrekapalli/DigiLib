import '../models/entities/reading_progress.dart';
import '../network/api_client.dart';

/// Request model for updating reading progress
class UpdateReadingProgressRequest {
  final int lastPage;

  const UpdateReadingProgressRequest({required this.lastPage});

  Map<String, dynamic> toJson() {
    return {
      'last_page': lastPage,
    };
  }
}

/// API service for reading progress operations with the backend
class ReadingProgressApiService {
  final ApiClient _apiClient;

  ReadingProgressApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get reading progress for a specific document
  /// API: GET /api/documents/{documentId}/progress
  Future<ReadingProgress?> getReadingProgress(String documentId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/documents/$documentId/progress',
      );
      
      return ReadingProgress.fromJson(response);
    } catch (e) {
      // Return null if progress doesn't exist (404)
      return null;
    }
  }

  /// Update reading progress for a document
  /// API: PUT /api/documents/{documentId}/progress
  Future<ReadingProgress> updateReadingProgress(String documentId, int lastPage) async {
    final request = UpdateReadingProgressRequest(lastPage: lastPage);
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/documents/$documentId/progress',
      body: request.toJson(),
    );
    
    return ReadingProgress.fromJson(response);
  }

  /// Delete reading progress for a document
  /// API: DELETE /api/documents/{documentId}/progress
  Future<void> deleteReadingProgress(String documentId) async {
    await _apiClient.delete<void>('/api/documents/$documentId/progress');
  }

  /// Get all reading progress for the current user
  /// API: GET /api/reading-progress
  Future<List<ReadingProgress>> getUserReadingProgress({
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    final response = await _apiClient.get<List<dynamic>>(
      '/api/reading-progress',
      queryParams: queryParams,
    );
    
    return response.map((json) => ReadingProgress.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get recently read documents
  /// API: GET /api/reading-progress/recent
  Future<List<ReadingProgress>> getRecentReadingProgress({int limit = 10}) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
    };
    
    final response = await _apiClient.get<List<dynamic>>(
      '/api/reading-progress/recent',
      queryParams: queryParams,
    );
    
    return response.map((json) => ReadingProgress.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get documents currently in progress (partially read)
  /// API: GET /api/reading-progress/in-progress
  Future<List<ReadingProgress>> getInProgressDocuments({
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    
    final response = await _apiClient.get<List<dynamic>>(
      '/api/reading-progress/in-progress',
      queryParams: queryParams,
    );
    
    return response.map((json) => ReadingProgress.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Batch update reading progress (for sync operations)
  /// API: POST /api/reading-progress/batch
  Future<List<ReadingProgress>> batchUpdateReadingProgress(List<ReadingProgress> progressList) async {
    final requestBody = {
      'progress': progressList.map((p) => p.toJson()).toList(),
    };
    
    final response = await _apiClient.post<List<dynamic>>(
      '/api/reading-progress/batch',
      body: requestBody,
    );
    
    return response.map((json) => ReadingProgress.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get reading statistics for the user
  /// API: GET /api/reading-progress/stats
  Future<ReadingStats> getReadingStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/reading-progress/stats',
    );
    
    return ReadingStats.fromJson(response);
  }
}

/// Model for reading statistics
class ReadingStats {
  final int totalDocuments;
  final int documentsInProgress;
  final int documentsCompleted;
  final int totalPagesRead;
  final DateTime? lastReadAt;

  const ReadingStats({
    required this.totalDocuments,
    required this.documentsInProgress,
    required this.documentsCompleted,
    required this.totalPagesRead,
    this.lastReadAt,
  });

  factory ReadingStats.fromJson(Map<String, dynamic> json) {
    return ReadingStats(
      totalDocuments: json['total_documents'] as int,
      documentsInProgress: json['documents_in_progress'] as int,
      documentsCompleted: json['documents_completed'] as int,
      totalPagesRead: json['total_pages_read'] as int,
      lastReadAt: json['last_read_at'] != null 
          ? DateTime.parse(json['last_read_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_documents': totalDocuments,
      'documents_in_progress': documentsInProgress,
      'documents_completed': documentsCompleted,
      'total_pages_read': totalPagesRead,
      'last_read_at': lastReadAt?.toIso8601String(),
    };
  }
}