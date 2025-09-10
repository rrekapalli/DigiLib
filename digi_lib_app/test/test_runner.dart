import 'package:flutter_test/flutter_test.dart';

// Import all test files
import 'auth_provider_test.dart' as auth_provider_test;
import 'auth_state_test.dart' as auth_state_test;
import 'cache_test.dart' as cache_test;
import 'database_test.dart' as database_test;
import 'fts_test.dart' as fts_test;
import 'models_test.dart' as models_test;
import 'secure_storage_test.dart' as secure_storage_test;

// Service tests
import 'services/performance_monitoring_service_test.dart' as performance_monitoring_test;
import 'services/notification_service_test.dart' as notification_service_test;
import 'services/secure_storage_service_test.dart' as secure_storage_service_test;
import 'services/auth_api_service_test.dart' as auth_api_service_test;
import 'services/library_api_service_test.dart' as library_api_service_test;
import 'services/native_rendering_worker_test.dart' as native_rendering_worker_test;
import 'services/platform_channel_native_rendering_worker_test.dart' as platform_channel_native_rendering_worker_test;

// Widget tests
import 'widgets/document_card_test.dart' as document_card_test;

// Integration tests
import 'integration/api_integration_test.dart' as api_integration_test;

// Network tests
import 'network/connectivity_service_test.dart' as connectivity_service_test;

void main() {
  group('Digital Library App - Complete Test Suite', () {
    group('Core Tests', () {
      auth_provider_test.main();
      auth_state_test.main();
      cache_test.main();
      database_test.main();
      fts_test.main();
      models_test.main();
      secure_storage_test.main();
    });

    group('Service Tests', () {
      performance_monitoring_test.main();
      notification_service_test.main();
      secure_storage_service_test.main();
      auth_api_service_test.main();
      library_api_service_test.main();
      native_rendering_worker_test.main();
      platform_channel_native_rendering_worker_test.main();
    });

    group('Widget Tests', () {
      document_card_test.main();
    });

    group('Integration Tests', () {
      api_integration_test.main();
    });

    group('Network Tests', () {
      connectivity_service_test.main();
    });
  });

  // Test summary
  tearDownAll(() {
    // Test summary is handled by the test framework
    // Individual test results provide detailed information
  });
}