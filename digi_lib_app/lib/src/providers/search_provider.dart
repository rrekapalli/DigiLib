import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../services/search_api_service.dart';
import '../services/local_search_service.dart';
import '../services/global_search_service.dart';
import '../services/search_service.dart';
import 'connectivity_provider.dart';

/// Provider for SearchApiService
final searchApiServiceProvider = Provider<SearchApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchApiService(apiClient);
});

/// Provider for LocalSearchService
final localSearchServiceProvider = Provider<LocalSearchService>((ref) {
  return LocalSearchService();
});

/// Provider for GlobalSearchService
final globalSearchServiceProvider = Provider<GlobalSearchService>((ref) {
  final searchApiService = ref.watch(searchApiServiceProvider);
  final localSearchService = ref.watch(localSearchServiceProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  
  return GlobalSearchService(
    searchApiService,
    localSearchService,
    connectivityService,
  );
});

/// Provider for main SearchService
final searchServiceProvider = Provider<SearchService>((ref) {
  final localSearchService = ref.watch(localSearchServiceProvider);
  final globalSearchService = ref.watch(globalSearchServiceProvider);
  
  return SearchService(
    localSearchService,
    globalSearchService,
  );
});

// Note: These providers assume that apiClientProvider and connectivityServiceProvider
// are defined elsewhere in the app. You may need to adjust the imports and provider names
// based on your actual provider setup.

/// Placeholder providers - replace with actual implementations
final apiClientProvider = Provider<ApiClient>((ref) {
  return MockApiClient();
});

// connectivityServiceProvider is now imported from connectivity_provider.dart

/// Mock ApiClient for development
class MockApiClient implements ApiClient {
  String? _authToken;
  
  @override
  String get baseUrl => 'http://localhost:8080';
  
  @override
  bool get hasAuthToken => _authToken != null;

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParams}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Mock API client - GET not implemented');
  }

  @override
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? queryParams}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Mock API client - POST not implemented');
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Mock API client - PUT not implemented');
  }

  @override
  Future<T> delete<T>(String path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    throw UnimplementedError('Mock API client - DELETE not implemented');
  }

  @override
  void setAuthToken(String token) {
    _authToken = token;
  }

  @override
  void clearAuthToken() {
    _authToken = null;
  }
}