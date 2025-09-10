import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';

/// Test configuration for the Digital Library App
class TestConfig {
  /// Initialize test configuration
  static Future<void> initialize() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    
    // Configure golden toolkit for widget testing
    await loadAppFonts();
  }

  /// Setup for widget tests
  static void setupWidgetTests() {
    setUpAll(() async {
      await initialize();
    });
  }

  /// Setup for unit tests
  static void setupUnitTests() {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
    });
  }

  /// Setup for integration tests
  static void setupIntegrationTests() {
    setUpAll(() async {
      await initialize();
    });
  }
}