import '../network/api_client.dart';
import '../models/api/sync_models.dart';

/// API service for synchronization operations
class SyncApiService {
  final ApiClient _apiClient;

  SyncApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Get sync manifest from server
  /// API: GET /api/sync/manifest?since=...
  Future<SyncManifest> getSyncManifest({DateTime? since}) async {
    final queryParams = <String, dynamic>{};
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/api/sync/manifest',
      queryParams: queryParams,
    );

    return SyncManifest.fromJson(response);
  }

  /// Push local changes to server
  /// API: POST /api/sync/push
  Future<SyncPushResponse> pushLocalChanges(SyncPushRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/sync/push',
      body: request.toJson(),
    );

    return SyncPushResponse.fromJson(response);
  }
}