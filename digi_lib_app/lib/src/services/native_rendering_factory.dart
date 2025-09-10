
import 'dart:typed_data';

import 'page_rendering_service.dart';
import 'ffi_native_rendering_worker.dart';
import 'platform_channel_native_rendering_worker.dart';
import 'native_library_loader.dart';

/// Factory class for creating NativeRenderingWorker instances
/// 
/// This factory automatically detects whether the native library is available
/// and provides the appropriate implementation (FFI or Mock).
class NativeRenderingFactory {
  static NativeRenderingWorker? _instance;
  static String _currentImplementation = 'unknown';
  
  /// Creates or returns the singleton instance of NativeRenderingWorker
  /// 
  /// [forceUseMock] - If true, forces the use of mock implementation
  /// [testMode] - If true, always uses mock implementation for testing
  /// [forcePlatformChannel] - If true, forces the use of platform channel implementation
  static NativeRenderingWorker getInstance({
    bool forceUseMock = false,
    bool testMode = false,
    bool forcePlatformChannel = false,
  }) {
    if (_instance != null) {
      return _instance!;
    }
    
    // In test mode, always use mock
    if (testMode || forceUseMock) {
      _instance = MockNativeRenderingWorker();
      _currentImplementation = 'mock';
      return _instance!;
    }
    
    // Force platform channel if requested
    if (forcePlatformChannel) {
      _instance = PlatformChannelNativeRenderingWorker();
      _currentImplementation = 'platform_channel';
      return _instance!;
    }
    
    // Try implementations in order of preference:
    // 1. FFI (best performance)
    // 2. Platform Channel (good compatibility)
    // 3. Mock (fallback for development)
    
    // Try FFI implementation first
    try {
      final ffiWorker = FFINativeRenderingWorker();
      if (ffiWorker.isAvailable) {
        _instance = ffiWorker;
        _currentImplementation = 'ffi';
        print('Using FFI native rendering implementation');
        return _instance!;
      }
    } catch (e) {
      print('FFI native rendering failed to initialize: $e');
    }
    
    // Try platform channel implementation
    try {
      final platformWorker = PlatformChannelNativeRenderingWorker();
      _instance = platformWorker;
      _currentImplementation = 'platform_channel';
      print('Using platform channel native rendering implementation');
      return _instance!;
    } catch (e) {
      print('Platform channel native rendering failed to initialize: $e');
    }
    
    // Fall back to mock implementation
    print('Warning: No native rendering implementations available, using mock implementation');
    _instance = MockNativeRenderingWorker();
    _currentImplementation = 'mock';
    return _instance!;
  }
  
  /// Returns the current implementation type
  static String get currentImplementation => _currentImplementation;
  
  /// Returns true if the current instance is using FFI implementation
  static bool get isUsingFFI => _currentImplementation == 'ffi';
  
  /// Returns true if the current instance is using platform channel implementation
  static bool get isUsingPlatformChannel => _currentImplementation == 'platform_channel';
  
  /// Returns true if the current instance is using mock implementation
  static bool get isUsingMock => _currentImplementation == 'mock';
  
  /// Checks if the native library is available on the current platform
  static bool isNativeLibraryAvailable() {
    return NativeLibraryLoader.isLibraryAvailable();
  }

  
  /// Resets the singleton instance (useful for testing)
  static void reset() {
    // Dispose based on implementation type
    if (_instance is FFINativeRenderingWorker) {
      (_instance as FFINativeRenderingWorker).dispose();
    } else if (_instance is PlatformChannelNativeRenderingWorker) {
      (_instance as PlatformChannelNativeRenderingWorker).dispose();
    }
    _instance = null;
    _currentImplementation = 'unknown';
  }
  
  /// Disposes the current instance and resets the factory
  static void dispose() {
    // Dispose based on implementation type
    if (_instance is FFINativeRenderingWorker) {
      (_instance as FFINativeRenderingWorker).dispose();
    } else if (_instance is PlatformChannelNativeRenderingWorker) {
      (_instance as PlatformChannelNativeRenderingWorker).dispose();
    }
    _instance = null;
    _currentImplementation = 'unknown';
  }
}

/// Mock implementation of NativeRenderingWorker for testing and fallback
class MockNativeRenderingWorker implements NativeRenderingWorker {
  @override
  bool get isAvailable => true;

  @override
  Future<Uint8List> renderPage(String filePath, int page, int dpi) async {
    // Return a simple 1x1 pixel image for testing
    return Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, // IHDR chunk
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, // 1x1 dimensions
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
      0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41, // IDAT chunk
      0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
      0x00, 0x01, 0x00, 0x01, 0x5C, 0xC2, 0xD5, 0x7E,
      0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, // IEND chunk
      0xAE, 0x42, 0x60, 0x82
    ]);
  }

  @override
  Future<String> extractText(String filePath, int page) async {
    return 'Mock text content for page $page of $filePath';
  }

  @override
  Future<int> getPageCount(String filePath) async {
    return 10; // Mock page count
  }

  void dispose() {
    // Nothing to dispose for mock implementation
  }
}