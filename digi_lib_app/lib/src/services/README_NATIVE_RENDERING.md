# Native Rendering Implementation

This document describes the native rendering implementation for the Digital Library App, which provides document rendering capabilities through multiple fallback mechanisms.

## Overview

The native rendering system is designed with a layered approach that provides multiple implementation options:

1. **FFI (Foreign Function Interface)** - Direct integration with native libraries (Rust/C++)
2. **Platform Channels** - Flutter platform channel communication with native platform code
3. **Mock Implementation** - Fallback for development and testing

## Architecture

### Factory Pattern

The `NativeRenderingFactory` class manages the creation and selection of the appropriate rendering implementation:

```dart
// Get the best available implementation
final worker = NativeRenderingFactory.getInstance();

// Force a specific implementation
final ffiWorker = NativeRenderingFactory.getInstance(forcePlatformChannel: true);
final mockWorker = NativeRenderingFactory.getInstance(testMode: true);
```

### Implementation Priority

The factory tries implementations in this order:

1. **FFI Implementation** (`FFINativeRenderingWorker`)
   - Highest performance
   - Direct native library integration
   - Requires native library to be available

2. **Platform Channel Implementation** (`PlatformChannelNativeRenderingWorker`)
   - Good compatibility across platforms
   - Uses Flutter's platform channel system
   - Requires platform-specific native code

3. **Mock Implementation** (`MockNativeRenderingWorker`)
   - Always available fallback
   - Used for development and testing
   - Generates placeholder content

## FFI Implementation

### Features

- Direct binding to native Rust/C++ libraries
- High-performance document rendering
- Memory-efficient operations
- Proper error handling and resource cleanup

### Native Library Interface

The FFI implementation expects a native library with these functions:

```c
// Render a page to image bytes
RenderResult* render_page(const char* file_path, int32_t page, int32_t dpi);

// Extract text from a page
char* extract_text(const char* file_path, int32_t page);

// Get total page count
int32_t get_page_count(const char* file_path);

// Memory cleanup functions
void free_string(char* ptr);
void free_buffer(uint8_t* ptr);
```

### Error Handling

The FFI implementation includes comprehensive error handling:

- File validation
- Parameter validation
- Memory management
- Native library error propagation

## Platform Channel Implementation

### Features

- Cross-platform compatibility
- Asynchronous operation
- Performance monitoring
- Graceful error handling

### Platform Integration

#### Android

The Android implementation (`NativeRenderingPlugin.kt`) provides:

- Background thread processing
- Performance metrics tracking
- Error handling and logging
- Memory management

#### iOS

The iOS implementation (`NativeRenderingPlugin.swift`) provides:

- GCD-based async processing
- Performance metrics tracking
- Error handling and logging
- Memory management

### Method Channel Interface

The platform channel uses the following methods:

- `isAvailable` - Check if native rendering is available
- `renderPage` - Render a document page to image bytes
- `extractText` - Extract text from a document page
- `getPageCount` - Get total page count
- `getPerformanceMetrics` - Get rendering performance data
- `clearCache` - Clear cached data
- `setLogLevel` - Set logging level

## Usage Examples

### Basic Usage

```dart
// Get the rendering worker
final worker = NativeRenderingFactory.getInstance();

// Check if available
if (worker.isAvailable) {
  // Render a page
  final imageBytes = await worker.renderPage('/path/to/document.pdf', 0, 150);
  
  // Extract text
  final text = await worker.extractText('/path/to/document.pdf', 0);
  
  // Get page count
  final pageCount = await worker.getPageCount('/path/to/document.pdf');
}
```

### Integration with Page Rendering Service

The native workers integrate with the existing `PageRenderingService`:

```dart
final pageRenderingService = PageRenderingServiceImpl(
  documentApiService,
  cacheService,
  NativeRenderingFactory.getInstance(), // Native worker
  httpClient,
);

// The service will automatically fall back to native rendering if API fails
final result = await pageRenderingService.renderPage('doc-id', 0);
```

## Testing

### Unit Tests

Each implementation has comprehensive unit tests:

- `native_rendering_worker_test.dart` - Tests for FFI implementation and factory
- `platform_channel_native_rendering_worker_test.dart` - Tests for platform channel implementation

### Test Coverage

- Error handling scenarios
- Parameter validation
- Memory management
- Performance metrics
- Factory fallback behavior

### Mock Testing

The mock implementation allows for reliable testing without native dependencies:

```dart
// Force mock implementation for testing
final worker = NativeRenderingFactory.getInstance(testMode: true);
```

## Performance Considerations

### FFI Implementation

- Direct memory access for optimal performance
- Minimal overhead between Dart and native code
- Efficient memory management with proper cleanup

### Platform Channel Implementation

- Background thread processing to avoid UI blocking
- Performance metrics tracking
- Configurable logging levels

### Caching Integration

Both implementations work with the existing cache system:

- Rendered pages are cached automatically
- Cache eviction policies are respected
- Performance metrics include cache hit rates

## Error Handling

### Exception Types

All implementations throw `NativeRenderingException` for consistent error handling:

```dart
try {
  final imageBytes = await worker.renderPage(filePath, page, dpi);
} catch (e) {
  if (e is NativeRenderingException) {
    // Handle rendering-specific error
    print('Rendering failed: ${e.message}');
    if (e.details != null) {
      print('Details: ${e.details}');
    }
  }
}
```

### Common Error Scenarios

- File not found
- Invalid page numbers
- Invalid DPI values
- Native library not available
- Platform channel communication failures

## Future Enhancements

### Planned Features

1. **WebAssembly Support** - Browser-based rendering
2. **GPU Acceleration** - Hardware-accelerated rendering
3. **Streaming Rendering** - Progressive page loading
4. **Advanced Caching** - Predictive page preloading

### Performance Optimizations

1. **Memory Pooling** - Reuse memory buffers
2. **Parallel Processing** - Multi-threaded rendering
3. **Compression** - Optimized image formats
4. **Network Optimization** - Efficient data transfer

## Dependencies

### Dart Dependencies

- `ffi: ^2.1.0` - FFI bindings
- `flutter/services.dart` - Platform channels

### Native Dependencies

- Native rendering library (Rust/C++)
- Platform-specific PDF libraries (PDFium, MuPDF, etc.)

## Configuration

### Build Configuration

The native libraries should be placed in platform-specific directories:

- Windows: `digi_lib_native.dll`
- macOS: `libdigi_lib_native.dylib`
- Linux: `libdigi_lib_native.so`

### Runtime Configuration

The factory automatically detects available implementations and selects the best option. No manual configuration is required for normal operation.