import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class NetworkTest {
  static Future<void> testApiConnectivity() async {
    final dio = Dio();

    // Skip network connectivity tests on web due to CORS restrictions
    if (kIsWeb) {
      debugPrint(
        '🌐 Web platform detected - skipping network connectivity tests due to CORS restrictions',
      );
      debugPrint('💡 To resolve CORS issues:');
      debugPrint(
        '   1. Configure your API server to allow CORS from http://localhost:43687',
      );
      debugPrint(
        '   2. Or launch Chrome with --disable-web-security (development only)',
      );
      debugPrint('   3. Or use a CORS proxy for development');
      return;
    }

    // Test different URLs based on platform
    final urls = [
      'http://localhost:9090', // Primary - localhost
      'http://127.0.0.1:9090', // Alternative localhost
      'http://10.0.2.2:9090', // Android emulator (fallback)
    ];

    for (final url in urls) {
      try {
        debugPrint('Testing connectivity to: $url');
        // Try different endpoints
        final endpoints = ['/', '/health', '/api', '/auth'];

        for (final endpoint in endpoints) {
          try {
            final response = await dio.get('$url$endpoint');
            debugPrint(
              '✅ Success: $url$endpoint - Status: ${response.statusCode}',
            );
            debugPrint(
              '   Response: ${response.data.toString().substring(0, response.data.toString().length > 100 ? 100 : response.data.toString().length)}...',
            );
            return;
          } catch (e) {
            debugPrint('❌ Failed: $url$endpoint - Error: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Failed: $url - Error: $e');
      }
    }

    debugPrint('🔴 All connectivity tests failed');
  }

  static Future<void> testPlatformInfo() async {
    debugPrint('Platform Info:');
    debugPrint('- kIsWeb: $kIsWeb');
    if (!kIsWeb) {
      debugPrint('- Platform.isAndroid: ${Platform.isAndroid}');
      debugPrint('- Platform.isIOS: ${Platform.isIOS}');
      debugPrint('- Platform.isWindows: ${Platform.isWindows}');
    }
  }
}
