import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlatformChannelNativeRenderingWorker', () {
    PlatformChannelNativeRenderingWorker? worker;
    late File testFile;
    const MethodChannel channel = MethodChannel('digi_lib_native_rendering');

    setUpAll(() async {
      // Create a test file
      testFile = File('test_document.pdf');
      await testFile.writeAsString('Mock PDF content for testing');
    });

    tearDownAll(() async {
      // Clean up test file
      if (await testFile.exists()) {
        await testFile.delete();
      }
    });

    setUp(() {
      // Worker will be created in individual test groups after mock setup
    });

    tearDown(() {
      worker?.dispose();
      // Reset method channel mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    group('when platform channel is available', () {
      setUp(() {
        // Mock platform channel responses
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isAvailable':
              return true;
            case 'renderPage':
              final args = methodCall.arguments as Map;
              final filePath = args['filePath'] as String;
              final page = args['page'] as int;
              final dpi = args['dpi'] as int;
              
              // Validate arguments
              if (!File(filePath).existsSync()) {
                return <String, dynamic>{
                  'success': false,
                  'error': 'File not found: $filePath'
                };
              }
              
              if (page < 0) {
                return <String, dynamic>{
                  'success': false,
                  'error': 'Page number must be non-negative'
                };
              }
              
              if (dpi <= 0 || dpi > 600) {
                return <String, dynamic>{
                  'success': false,
                  'error': 'DPI must be between 1 and 600'
                };
              }
              
              // Return mock image data
              return <String, dynamic>{
                'success': true,
                'imageData': Uint8List.fromList([1, 2, 3, 4, 5])
              };
            case 'extractText':
              final args = methodCall.arguments as Map;
              final filePath = args['filePath'] as String;
              final page = args['page'] as int;
              
              if (!File(filePath).existsSync()) {
                return <String, dynamic>{
                  'success': false,
                  'error': 'File not found: $filePath'
                };
              }
              
              return <String, dynamic>{
                'success': true,
                'text': 'Mock text content for page ${page + 1} from platform channel'
              };
            case 'getPageCount':
              final args = methodCall.arguments as Map;
              final filePath = args['filePath'] as String;
              
              if (!File(filePath).existsSync()) {
                return <String, dynamic>{
                  'success': false,
                  'error': 'File not found: $filePath'
                };
              }
              
              return <String, dynamic>{
                'success': true,
                'pageCount': 10
              };
            case 'getPerformanceMetrics':
              return <String, dynamic>{
                'renderCount': 5,
                'totalRenderTime': 1000,
                'averageRenderTime': 200,
                'errorCount': 0,
                'platform': 'test'
              };
            case 'clearCache':
              return null;
            case 'setLogLevel':
              return null;
            default:
              throw MissingPluginException('No implementation found for method ${methodCall.method}');
          }
        });
        
        // Create worker after setting up mock
        worker = PlatformChannelNativeRenderingWorker();
      });

      test('should be available when platform channel responds positively', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        expect(worker!.isAvailable, isTrue);
      });

      test('should render page successfully', () async {
        final imageBytes = await worker!.renderPage(testFile.path, 0, 150);
        
        expect(imageBytes, isA<Uint8List>());
        expect(imageBytes.isNotEmpty, isTrue);
      });

      test('should extract text successfully', () async {
        final text = await worker!.extractText(testFile.path, 0);
        
        expect(text, isA<String>());
        expect(text.isNotEmpty, isTrue);
        expect(text.contains('Mock text content'), isTrue);
      });

      test('should get page count successfully', () async {
        final pageCount = await worker!.getPageCount(testFile.path);
        
        expect(pageCount, isA<int>());
        expect(pageCount, equals(10));
      });

      test('should get performance metrics', () async {
        final metrics = await worker!.getPerformanceMetrics();
        
        expect(metrics, isNotNull);
        expect(metrics!['renderCount'], equals(5));
        expect(metrics['platform'], equals('test'));
      });

      test('should clear cache without error', () async {
        await expectLater(worker!.clearCache(), completes);
      });

      test('should set log level without error', () async {
        await expectLater(worker!.setLogLevel('debug'), completes);
      });

      test('should handle file not found error', () async {
        expect(
          () => worker!.renderPage('non_existent_file.pdf', 0, 150),
          throwsA(isA<NativeRenderingException>()),
        );
      });

      test('should handle invalid page number', () async {
        expect(
          () => worker!.renderPage(testFile.path, -1, 150),
          throwsA(isA<NativeRenderingException>()),
        );
      });

      test('should handle invalid DPI', () async {
        expect(
          () => worker!.renderPage(testFile.path, 0, 0),
          throwsA(isA<NativeRenderingException>()),
        );
        
        expect(
          () => worker!.renderPage(testFile.path, 0, 700),
          throwsA(isA<NativeRenderingException>()),
        );
      });
    });

    group('when platform channel is not available', () {
      setUp(() {
        // Mock platform channel to return unavailable
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isAvailable':
              return false;
            default:
              throw MissingPluginException('No implementation found for method ${methodCall.method}');
          }
        });
        
        // Create worker after setting up mock
        worker = PlatformChannelNativeRenderingWorker();
      });

      test('should not be available when platform channel responds negatively', () async {
        // Wait for initialization
        await Future.delayed(const Duration(milliseconds: 100));
        expect(worker!.isAvailable, isFalse);
      });

      test('should throw exception when trying to render page', () async {
        expect(
          () => worker!.renderPage(testFile.path, 0, 150),
          throwsA(isA<NativeRenderingException>()),
        );
      });

      test('should return null for performance metrics', () async {
        final metrics = await worker!.getPerformanceMetrics();
        expect(metrics, isNull);
      });
    });

    group('when platform channel throws exceptions', () {
      setUp(() {
        // Mock platform channel to throw exceptions
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'isAvailable':
              return true;
            case 'renderPage':
              throw PlatformException(
                code: 'RENDER_ERROR',
                message: 'Mock platform error',
                details: null,
              );
            default:
              throw MissingPluginException('No implementation found for method ${methodCall.method}');
          }
        });
        
        // Create worker after setting up mock
        worker = PlatformChannelNativeRenderingWorker();
      });

      test('should handle platform exceptions gracefully', () async {
        expect(
          () => worker!.renderPage(testFile.path, 0, 150),
          throwsA(isA<NativeRenderingException>()),
        );
      });
    });

    group('dispose', () {
      setUp(() {
        worker = PlatformChannelNativeRenderingWorker();
      });
      
      test('should dispose without error', () {
        expect(() => worker!.dispose(), returnsNormally);
        expect(worker!.isAvailable, isFalse);
      });
    });
  });
}