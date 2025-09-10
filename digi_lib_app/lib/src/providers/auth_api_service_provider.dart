import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_api_service.dart';
import 'api_client_provider.dart';
import 'settings_provider.dart';

/// Provider for auth API service
final authApiServiceProvider = Provider<AuthApiService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return AuthApiServiceImpl(apiClient, secureStorage);
});