import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'page_rendering_service.dart';
import 'native_library_loader.dart';

/// Exception thrown when native rendering operations fail
class NativeRenderingException implements Exception {
  final String message;
  final String? details;
  
  const NativeRenderingException(this.message, [this.details]);
  
  @override
  String toString() => 'NativeRenderingException: $message${details != null ? ' ($details)' : ''}';
}

/// FFI-based implementation of NativeRenderingWorker
class FFINativeRenderingWorker implements NativeRenderingWorker {
  static const String _libraryName = 'digi_lib_native';
  
  late final DynamicLibrary _dylib;
  late final _RenderPageNative _renderPage;
  late final _ExtractTextNative _extractText;
  late final _GetPageCountNative _getPageCount;
  late final _FreeStringNative _freeString;
  late final _FreeBufferNative _freeBuffer;
  
  bool _isInitialized = false;
  
  FFINativeRenderingWorker() {
    _initializeLibrary();
  }
  
  @override
  bool get isAvailable => _isInitialized;
  
  void _initializeLibrary() {
    try {
      // Load the native library using the comprehensive loader
      _dylib = NativeLibraryLoader.loadLibrary();
      
      // Bind native functions
      _renderPage = _dylib.lookupFunction<_RenderPageC, _RenderPageNative>('render_page');
      _extractText = _dylib.lookupFunction<_ExtractTextC, _ExtractTextNative>('extract_text');
      _getPageCount = _dylib.lookupFunction<_GetPageCountC, _GetPageCountNative>('get_page_count');
      _freeString = _dylib.lookupFunction<_FreeStringC, _FreeStringNative>('free_string');
      _freeBuffer = _dylib.lookupFunction<_FreeBufferC, _FreeBufferNative>('free_buffer');
      
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      // Don't throw here - just mark as unavailable
      print('Warning: Failed to initialize native library: $e');
    }
  }
  
  @override
  Future<Uint8List> renderPage(String filePath, int page, int dpi) async {
    if (!_isInitialized) {
      throw const NativeRenderingException('Native library not initialized');
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
    
    final filePathPtr = filePath.toNativeUtf8();
    Pointer<RenderResult> resultPtr = nullptr;
    
    try {
      // Call native function
      resultPtr = _renderPage(filePathPtr, page, dpi);
      
      if (resultPtr == nullptr) {
        throw const NativeRenderingException('Native render_page returned null');
      }
      
      final result = resultPtr.ref;
      
      // Check for errors
      if (result.error_code != 0) {
        final errorMsg = result.error_message != nullptr 
            ? result.error_message.toDartString()
            : 'Unknown error';
        throw NativeRenderingException('Rendering failed', errorMsg);
      }
      
      // Copy image data
      if (result.image_data == nullptr || result.image_size == 0) {
        throw const NativeRenderingException('No image data returned');
      }
      
      final imageBytes = Uint8List.fromList(
        result.image_data.asTypedList(result.image_size)
      );
      
      return imageBytes;
    } finally {
      // Clean up memory
      malloc.free(filePathPtr);
      if (resultPtr != nullptr) {
        if (resultPtr.ref.image_data != nullptr) {
          _freeBuffer(resultPtr.ref.image_data);
        }
        if (resultPtr.ref.error_message != nullptr) {
          _freeString(resultPtr.ref.error_message);
        }
        malloc.free(resultPtr);
      }
    }
  }
  
  @override
  Future<String> extractText(String filePath, int page) async {
    if (!_isInitialized) {
      throw const NativeRenderingException('Native library not initialized');
    }
    
    // Validate inputs
    if (!File(filePath).existsSync()) {
      throw NativeRenderingException('File not found: $filePath');
    }
    
    if (page < 0) {
      throw const NativeRenderingException('Page number must be non-negative');
    }
    
    final filePathPtr = filePath.toNativeUtf8();
    Pointer<Utf8> textPtr = nullptr;
    
    try {
      // Call native function
      textPtr = _extractText(filePathPtr, page);
      
      if (textPtr == nullptr) {
        throw const NativeRenderingException('Text extraction failed');
      }
      
      return textPtr.toDartString();
    } finally {
      // Clean up memory
      malloc.free(filePathPtr);
      if (textPtr != nullptr) {
        _freeString(textPtr);
      }
    }
  }
  
  @override
  Future<int> getPageCount(String filePath) async {
    if (!_isInitialized) {
      throw const NativeRenderingException('Native library not initialized');
    }
    
    // Validate inputs
    if (!File(filePath).existsSync()) {
      throw NativeRenderingException('File not found: $filePath');
    }
    
    final filePathPtr = filePath.toNativeUtf8();
    
    try {
      // Call native function
      final pageCount = _getPageCount(filePathPtr);
      
      if (pageCount < 0) {
        throw const NativeRenderingException('Failed to get page count');
      }
      
      return pageCount;
    } finally {
      // Clean up memory
      malloc.free(filePathPtr);
    }
  }
  
  /// Disposes of native resources
  void dispose() {
    // FFI resources are automatically cleaned up
    _isInitialized = false;
  }
}

// C function signatures
typedef _RenderPageC = Pointer<RenderResult> Function(
  Pointer<Utf8> filePath,
  Int32 page,
  Int32 dpi,
);

typedef _ExtractTextC = Pointer<Utf8> Function(
  Pointer<Utf8> filePath,
  Int32 page,
);

typedef _GetPageCountC = Int32 Function(
  Pointer<Utf8> filePath,
);

typedef _FreeStringC = Void Function(Pointer<Utf8> ptr);
typedef _FreeBufferC = Void Function(Pointer<Uint8> ptr);

// Dart function signatures
typedef _RenderPageNative = Pointer<RenderResult> Function(
  Pointer<Utf8> filePath,
  int page,
  int dpi,
);

typedef _ExtractTextNative = Pointer<Utf8> Function(
  Pointer<Utf8> filePath,
  int page,
);

typedef _GetPageCountNative = int Function(
  Pointer<Utf8> filePath,
);

typedef _FreeStringNative = void Function(Pointer<Utf8> ptr);
typedef _FreeBufferNative = void Function(Pointer<Uint8> ptr);

// Native struct for render result
final class RenderResult extends Struct {
  @Int32()
  external int error_code;
  
  external Pointer<Utf8> error_message;
  external Pointer<Uint8> image_data;
  
  @Int32()
  external int image_size;
}