import '../models/entities/share.dart';
import '../models/api/create_share_request.dart';
import '../models/api/update_share_request.dart';
import '../network/api_client.dart';

/// API service for share operations with the backend
class ShareApiService {
  final ApiClient _apiClient;

  ShareApiService({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Create a new share
  /// API: POST /api/shares
  Future<Share> createShare(CreateShareRequest request) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      '/api/shares',
      body: request.toJson(),
    );
    
    return Share.fromJson(response);
  }

  /// Get all shares owned by the current user
  /// API: GET /api/shares
  Future<List<Share>> getShares() async {
    final response = await _apiClient.get<List<dynamic>>('/api/shares');
    
    return response.map((json) => Share.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get all shares where current user is the grantee
  /// API: GET /api/shares/shared-with-me
  Future<List<Share>> getSharedWithMe() async {
    final response = await _apiClient.get<List<dynamic>>('/api/shares/shared-with-me');
    
    return response.map((json) => Share.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get a specific share by ID
  /// API: GET /api/shares/{shareId}
  Future<Share> getShare(String shareId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/api/shares/$shareId');
    
    return Share.fromJson(response);
  }

  /// Update share permission
  /// API: PUT /api/shares/{shareId}
  Future<Share> updateSharePermission(String shareId, SharePermission permission) async {
    final request = UpdateShareRequest(permission: permission);
    final response = await _apiClient.put<Map<String, dynamic>>(
      '/api/shares/$shareId',
      body: request.toJson(),
    );
    
    return Share.fromJson(response);
  }

  /// Delete a share
  /// API: DELETE /api/shares/{shareId}
  Future<void> deleteShare(String shareId) async {
    await _apiClient.delete<void>('/api/shares/$shareId');
  }

  /// Get shares for a specific subject (document or folder)
  /// API: GET /api/shares?subject_id={subjectId}
  Future<List<Share>> getSharesBySubject(String subjectId) async {
    final response = await _apiClient.get<List<dynamic>>(
      '/api/shares',
      queryParams: {'subject_id': subjectId},
    );
    
    return response.map((json) => Share.fromJson(json as Map<String, dynamic>)).toList();
  }
}