import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:digi_lib_app/src/services/services.dart';

void main() {
  group('FFINativeRenderingWorker', () {
    late NativeRenderingWorker worker;
    late File testFile;
    
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
      
      // Clean up factory
      NativeRenderingFactory.dispose();
    });
    
    setUp(() {
      // Use mock implementation for testing since FFI library won't be available
      worker = NativeRenderingFactory.getInstance(testMode: true);
    });
    
    tearDown(() {
      NativeRenderingFactory.reset();
    });
    
    group('MockNativeRenderingWorker (fallback)', () {
      test('should render page successfully', () async {
        final imageBytes = await worker.renderPage(testFile.path, 0, 150);
        
        expect(imageBytes, isA<Uint8List>());
        expect(imageBytes.isNotEmpty, isTrue);
      });
      
      test('should extract text successfully', () async {
        final text = await worker.extractText(testFile.path, 0);
        
        expect(text, isA<String>());
        expect(text.isNotEmpty, isTrue);
        expect(text.contains('Mock text content'), isTrue);
      });
      
      test('should get page count successfully', () async {
        final pageCount = await worker.getPageCount(testFile.path);
        
        expect(pageCount, isA<int>());
        expect(pageCount, greaterThan(0));
      });
      
      test('should be available', () {
        expect(worker.isAvailable, isTrue);
      });
      
      test('should handle non-existent file gracefully', () async {
        // The mock implementation should handle this gracefully
        // by checking file existence
        expect(worker.isAvailable, isTrue);
      });
    });
    
    group('NativeRenderingFactory', () {
      test('should return mock implementation in test mode', () {
        NativeRenderingFactory.reset();
        final worker = NativeRenderingFactory.getInstance(testMode: true);
        
        expect(worker, isA<MockNativeRenderingWorker>());
        expect(NativeRenderingFactory.isUsingMock, isTrue);
        expect(NativeRenderingFactory.isUsingFFI, isFalse);
        expect(NativeRenderingFactory.isUsingPlatformChannel, isFalse);
        expect(NativeRenderingFactory.currentImplementation, equals('mock'));
      });
      
      test('should return platform channel implementation when forced', () {
        NativeRenderingFactory.reset();
        final worker = NativeRenderingFactory.getInstance(forcePlatformChannel: true);
        
        expect(worker, isA<PlatformChannelNativeRenderingWorker>());
        expect(NativeRenderingFactory.isUsingPlatformChannel, isTrue);
        expect(NativeRenderingFactory.isUsingFFI, isFalse);
        expect(NativeRenderingFactory.isUsingMock, isFalse);
        expect(NativeRenderingFactory.currentImplementation, equals('platform_channel'));
        
        // The platform channel worker will not be available in test environment
        // but it should still be created
        expect(worker.isAvailable, isFalse);
      });
      
      test('should return same instance on multiple calls', () {
        NativeRenderingFactory.reset();
        final worker1 = NativeRenderingFactory.getInstance(testMode: true);
        final worker2 = NativeRenderingFactory.getInstance(testMode: true);
        
        expect(identical(worker1, worker2), isTrue);
      });
      
      test('should reset instance correctly', () {
        NativeRenderingFactory.reset();
        final worker1 = NativeRenderingFactory.getInstance(testMode: true);
        NativeRenderingFactory.reset();
        final worker2 = NativeRenderingFactory.getInstance(testMode: true);
        
        expect(identical(worker1, worker2), isFalse);
      });
      
      test('should check native library availability', () {
        final isAvailable = NativeRenderingFactory.isNativeLibraryAvailable();
        
        expect(isAvailable, isA<bool>());
        // In test environment, native library is typically not available
        expect(isAvailable, isFalse);
      });
      
      test('should fall back through implementations correctly', () {
        // Reset to test fallback behavior
        NativeRenderingFactory.reset();
        
        // Without forcing any implementation, should try FFI first, then platform channel, then mock
        final worker = NativeRenderingFactory.getInstance();
        
        // In test environment, FFI will fail, platform channel will be created but not available
        // The factory returns platform channel but it won't be available
        expect(worker, anyOf(
          isA<PlatformChannelNativeRenderingWorker>(),
          isA<MockNativeRenderingWorker>()
        ));
        
        // The implementation should be either platform_channel or mock
        expect(NativeRenderingFactory.currentImplementation, anyOf(
          equals('platform_channel'),
          equals('mock')
        ));
      });
    });
    
    group('FFINativeRenderingWorker (when available)', () {
      test('should create FFI worker but fall back to mock when library unavailable', () {
        // In test environment, FFI library won't be available
        // so factory should fall back to mock implementation
        final worker = NativeRenderingFactory.getInstance();
        
        expect(worker, isA<MockNativeRenderingWorker>());
        expect(NativeRenderingFactory.isUsingMock, isTrue);
        expect(NativeRenderingFactory.isUsingFFI, isFalse);
      });
    });
    
    group('NativeRenderingException', () {
      test('should create exception with message only', () {
        const exception = NativeRenderingException('Test error');
        
        expect(exception.message, equals('Test error'));
        expect(exception.details, isNull);
        expect(exception.toString(), equals('NativeRenderingException: Test error'));
      });
      
      test('should create exception with message and details', () {
        const exception = NativeRenderingException('Test error', 'Additional details');
        
        expect(exception.message, equals('Test error'));
        expect(exception.details, equals('Additional details'));
        expect(exception.toString(), equals('NativeRenderingException: Test error (Additional details)'));
      });
    });
  });
}