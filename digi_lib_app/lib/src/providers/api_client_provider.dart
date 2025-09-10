import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/api_client.dart';
import '../utils/constants.dart';

/// Provider for API client configuration
final apiClientConfigProvider = Provider<ApiClientConfig>((ref) {
  return ApiClientConfig(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
    maxRetries: 3,
    retryDelay: const Duration(seconds: 1),
    enableLogging: true,
  );
});

/// Provider for API client
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiClientConfigProvider);
  return DioApiClient(config);
});