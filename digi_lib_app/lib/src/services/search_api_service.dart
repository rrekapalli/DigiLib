import '../network/api_client.dart';
import '../models/api/search_response.dart';

/// API service for global search operations
class SearchApiService {
  final ApiClient _apiClient;

  SearchApiService(this._apiClient);

  /// Search documents globally using backend API
  Future<SearchResponse> searchGlobal(
    String query, {
    String? libraryId,
    List<String>? tags,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'page': page,
      'limit': limit,
    };

    if (libraryId != null) {
      queryParams['library_id'] = libraryId;
    }

    if (tags != null && tags.isNotEmpty) {
      queryParams['tags'] = tags.join(',');
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/search',
      queryParams: queryParams,
    );

    return SearchResponse.fromJson(response);
  }

  /// Search within a specific document using backend API
  Future<SearchResponse> searchInDocument(
    String documentId,
    String query, {
    int page = 1,
    int limit = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'page': page,
      'limit': limit,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/documents/$documentId/search',
      queryParams: queryParams,
    );

    return SearchResponse.fromJson(response);
  }

  /// Get search suggestions from backend
  Future<List<String>> getSearchSuggestions(
    String partialQuery, {
    int limit = 10,
  }) async {
    final queryParams = <String, dynamic>{
      'q': partialQuery,
      'limit': limit,
    };

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/search/suggestions',
      queryParams: queryParams,
    );

    final suggestions = response['suggestions'] as List<dynamic>?;
    return suggestions?.cast<String>() ?? [];
  }
}