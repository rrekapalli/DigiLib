import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/connectivity_service.dart';

/// Provider for ConnectivityService - shared across the app
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService.instance;
});