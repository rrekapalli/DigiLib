import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'page_rendering_service.dart';
import 'ffi_native_rendering_worker.dart';

/// Platform channel-based implementation of NativeRenderingWorker
///
/// This implementation uses Flutter's platform channels to communicate
/// with native platform code (Android/iOS/Desktop) for document rendering.
/// It serves as a fallback when FFI is not available or fails.
class PlatformChannelNativeRenderingWorker implements NativeRenderingWorker {
  static const MethodChannel _channel = MethodChannel(
    'digi_lib_native_rendering',
  );

  bool _isInitialized = false;
  bool _isAvailable = false;

  PlatformChannelNativeRenderingWorker() {
    _initializePlatformChannel();
  }

  @override
  bool get isAvailable => _isAvailable;

  Future<void> _initializePlatformChannel() async {
    try {
      // Test if the platform channel is available
      final result = await _channel.invokeMethod<bool>('isAvailable');
      _isAvailable = result ?? false;
      _isInitialized = true;

      if (_isAvailable) {
        debugPrint(
          'Platform channel native rendering initialized successfully',
        );
      } else {
        debugPrint(
          'Platform channel native rendering is not available on this platform',
        );
      }
    } catch (e) {
      _isAvailable = false;
      _isInitialized = true;
      debugPrint('Platform channel native rendering initialization failed: $e');
    }
  }

  @override
  Future<Uint8List> renderPage(String filePath, int page, int dpi) async {
    if (!_isInitialized) {
      await _initializePlatformChannel();
    }

    if (!_isAvailable) {
      throw const NativeRenderingException(
        'Platform channel native rendering is not available',
      );
    }

    // Validate inputs
    if (!File(filePath).existsSync()) {
      throw NativeRenderingException('File not found: $filePath');
    }

    if (page < 0) {
      throw const NativeRenderingException('Page number must be non-negative');
    }

    if (dpi <= 0 || dpi > 600) {
      throw const NativeRenderingException('DPI must be between 1 and 600');
    }

    try {
      final result = await _channel.invokeMethod<Map>('renderPage', {
        'filePath': filePath,
        'page': page,
        'dpi': dpi,
      });

      if (result == null) {
        throw const NativeRenderingException(
          'Platform channel returned null result',
        );
      }

      final success = result['success'] as bool? ?? false;
      if (!success) {
        final errorMessage = result['error'] as String? ?? 'Unknown error';
        throw NativeRenderingException(
          'Platform rendering failed',
          errorMessage,
        );
      }

      final imageData = result['imageData'] as Uint8List?;
      if (imageData == null || imageData.isEmpty) {
        throw const NativeRenderingException(
          'No image data returned from platform',
        );
      }

      return imageData;
    } on PlatformException catch (e) {
      throw NativeRenderingException('Platform channel error', e.message);
    } catch (e) {
      throw NativeRenderingException(
        'Unexpected error during platform rendering',
        e.toString(),
      );
    }
  }

  @override
  Future<String> extractText(String filePath, int page) async {
    if (!_isInitialized) {
      await _initializePlatformChannel();
    }

    if (!_isAvailable) {
      throw const NativeRenderingException(
        'Platform channel native rendering is not available',
      );
    }

    // Validate inputs
    if (!File(filePath).existsSync()) {
      throw NativeRenderingException('File not found: $filePath');
    }

    if (page < 0) {
      throw const NativeRenderingException('Page number must be non-negative');
    }

    try {
      final result = await _channel.invokeMethod<Map>('extractText', {
        'filePath': filePath,
        'page': page,
      });

      if (result == null) {
        throw const NativeRenderingException(
          'Platform channel returned null result',
        );
      }

      final success = result['success'] as bool? ?? false;
      if (!success) {
        final errorMessage = result['error'] as String? ?? 'Unknown error';
        throw NativeRenderingException('Text extraction failed', errorMessage);
      }

      final text = result['text'] as String?;
      if (text == null) {
        throw const NativeRenderingException(
          'No text data returned from platform',
        );
      }

      return text;
    } on PlatformException catch (e) {
      throw NativeRenderingException('Platform channel error', e.message);
    } catch (e) {
      throw NativeRenderingException(
        'Unexpected error during text extraction',
        e.toString(),
      );
    }
  }

  @override
  Future<int> getPageCount(String filePath) async {
    if (!_isInitialized) {
      await _initializePlatformChannel();
    }

    if (!_isAvailable) {
      throw const NativeRenderingException(
        'Platform channel native rendering is not available',
      );
    }

    // Validate inputs
    if (!File(filePath).existsSync()) {
      throw NativeRenderingException('File not found: $filePath');
    }

    try {
      final result = await _channel.invokeMethod<Map>('getPageCount', {
        'filePath': filePath,
      });

      if (result == null) {
        throw const NativeRenderingException(
          'Platform channel returned null result',
        );
      }

      final success = result['success'] as bool? ?? false;
      if (!success) {
        final errorMessage = result['error'] as String? ?? 'Unknown error';
        throw NativeRenderingException('Get page count failed', errorMessage);
      }

      final pageCount = result['pageCount'] as int?;
      if (pageCount == null || pageCount < 0) {
        throw const NativeRenderingException(
          'Invalid page count returned from platform',
        );
      }

      return pageCount;
    } on PlatformException catch (e) {
      throw NativeRenderingException('Platform channel error', e.message);
    } catch (e) {
      throw NativeRenderingException(
        'Unexpected error during page count retrieval',
        e.toString(),
      );
    }
  }

  /// Gets performance metrics from the platform
  Future<Map<String, dynamic>?> getPerformanceMetrics() async {
    if (!_isAvailable) {
      return null;
    }

    try {
      final result = await _channel.invokeMethod<Map>('getPerformanceMetrics');
      return result?.cast<String, dynamic>();
    } catch (e) {
      debugPrint('Failed to get performance metrics: $e');
      return null;
    }
  }

  /// Clears any cached data on the platform side
  Future<void> clearCache() async {
    if (!_isAvailable) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('clearCache');
    } catch (e) {
      debugPrint('Failed to clear platform cache: $e');
    }
  }

  /// Sets logging level for platform-side operations
  Future<void> setLogLevel(String level) async {
    if (!_isAvailable) {
      return;
    }

    try {
      await _channel.invokeMethod<void>('setLogLevel', {'level': level});
    } catch (e) {
      debugPrint('Failed to set log level: $e');
    }
  }

  /// Disposes of platform channel resources
  void dispose() {
    _isInitialized = false;
    _isAvailable = false;
  }
}
