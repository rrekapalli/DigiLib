import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/native_rendering_factory.dart';
import '../services/page_rendering_service.dart';
import '../services/document_api_service.dart';
import '../services/cache_service.dart';
import 'package:http/http.dart' as http;

/// Provider for document API service
final documentApiServiceProvider = Provider<DocumentApiService>((ref) {
  // TODO: Replace with actual API client provider
  throw UnimplementedError('DocumentApiService provider must be overridden');
});

/// Provider for native rendering worker
final nativeRenderingWorkerProvider = Provider<NativeRenderingWorker>((ref) {
  return NativeRenderingFactory.getInstance();
});

/// Provider for page rendering service
final pageRenderingServiceProvider = Provider<PageRenderingService>((ref) {
  final documentApiService = ref.watch(documentApiServiceProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  final nativeWorker = ref.watch(nativeRenderingWorkerProvider);
  final httpClient = http.Client();

  return PageRenderingServiceImpl(
    documentApiService,
    cacheService,
    nativeWorker,
    httpClient,
  );
});

/// Provider for cache service
final cacheServiceProvider = Provider<CacheService>((ref) {
  // Return the actual cache service instance
  return CacheService.instance;
});

/// State notifier for native rendering configuration
class NativeRenderingConfigNotifier extends StateNotifier<NativeRenderingConfig> {
  NativeRenderingConfigNotifier() : super(const NativeRenderingConfig());

  /// Update the preferred implementation
  void setPreferredImplementation(NativeRenderingImplementation implementation) {
    state = state.copyWith(preferredImplementation: implementation);
    _reinitializeWorker();
  }

  /// Enable or disable native rendering fallback
  void setNativeFallbackEnabled(bool enabled) {
    state = state.copyWith(nativeFallbackEnabled: enabled);
  }

  /// Set the default DPI for rendering
  void setDefaultDpi(int dpi) {
    if (dpi > 0 && dpi <= 600) {
      state = state.copyWith(defaultDpi: dpi);
    }
  }

  /// Set the default image format
  void setDefaultFormat(String format) {
    if (['webp', 'png', 'jpeg'].contains(format.toLowerCase())) {
      state = state.copyWith(defaultFormat: format.toLowerCase());
    }
  }

  /// Enable or disable performance monitoring
  void setPerformanceMonitoringEnabled(bool enabled) {
    state = state.copyWith(performanceMonitoringEnabled: enabled);
  }

  /// Reinitialize the native worker with new configuration
  void _reinitializeWorker() {
    NativeRenderingFactory.reset();
    
    switch (state.preferredImplementation) {
      case NativeRenderingImplementation.ffi:
        NativeRenderingFactory.getInstance();
        break;
      case NativeRenderingImplementation.platformChannel:
        NativeRenderingFactory.getInstance(forcePlatformChannel: true);
        break;
      case NativeRenderingImplementation.mock:
        NativeRenderingFactory.getInstance(testMode: true);
        break;
      case NativeRenderingImplementation.auto:
        NativeRenderingFactory.getInstance();
        break;
    }
  }

  /// Get current implementation info
  NativeRenderingInfo getCurrentImplementationInfo() {
    return NativeRenderingInfo(
      currentImplementation: _mapImplementationType(NativeRenderingFactory.currentImplementation),
      isFFIAvailable: NativeRenderingFactory.isNativeLibraryAvailable(),
      isPlatformChannelAvailable: true, // Always available in Flutter
      isMockMode: NativeRenderingFactory.isUsingMock,
    );
  }

  NativeRenderingImplementation _mapImplementationType(String implementation) {
    switch (implementation) {
      case 'ffi':
        return NativeRenderingImplementation.ffi;
      case 'platform_channel':
        return NativeRenderingImplementation.platformChannel;
      case 'mock':
        return NativeRenderingImplementation.mock;
      default:
        return NativeRenderingImplementation.auto;
    }
  }
}

/// Provider for native rendering configuration
final nativeRenderingConfigProvider = StateNotifierProvider<NativeRenderingConfigNotifier, NativeRenderingConfig>((ref) {
  return NativeRenderingConfigNotifier();
});

/// Provider for native rendering info
final nativeRenderingInfoProvider = Provider<NativeRenderingInfo>((ref) {
  final configNotifier = ref.watch(nativeRenderingConfigProvider.notifier);
  return configNotifier.getCurrentImplementationInfo();
});

/// Configuration for native rendering
class NativeRenderingConfig {
  final NativeRenderingImplementation preferredImplementation;
  final bool nativeFallbackEnabled;
  final int defaultDpi;
  final String defaultFormat;
  final bool performanceMonitoringEnabled;

  const NativeRenderingConfig({
    this.preferredImplementation = NativeRenderingImplementation.auto,
    this.nativeFallbackEnabled = true,
    this.defaultDpi = 150,
    this.defaultFormat = 'webp',
    this.performanceMonitoringEnabled = true,
  });

  NativeRenderingConfig copyWith({
    NativeRenderingImplementation? preferredImplementation,
    bool? nativeFallbackEnabled,
    int? defaultDpi,
    String? defaultFormat,
    bool? performanceMonitoringEnabled,
  }) {
    return NativeRenderingConfig(
      preferredImplementation: preferredImplementation ?? this.preferredImplementation,
      nativeFallbackEnabled: nativeFallbackEnabled ?? this.nativeFallbackEnabled,
      defaultDpi: defaultDpi ?? this.defaultDpi,
      defaultFormat: defaultFormat ?? this.defaultFormat,
      performanceMonitoringEnabled: performanceMonitoringEnabled ?? this.performanceMonitoringEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativeRenderingConfig &&
        other.preferredImplementation == preferredImplementation &&
        other.nativeFallbackEnabled == nativeFallbackEnabled &&
        other.defaultDpi == defaultDpi &&
        other.defaultFormat == defaultFormat &&
        other.performanceMonitoringEnabled == performanceMonitoringEnabled;
  }

  @override
  int get hashCode {
    return Object.hash(
      preferredImplementation,
      nativeFallbackEnabled,
      defaultDpi,
      defaultFormat,
      performanceMonitoringEnabled,
    );
  }
}

/// Information about current native rendering implementation
class NativeRenderingInfo {
  final NativeRenderingImplementation currentImplementation;
  final bool isFFIAvailable;
  final bool isPlatformChannelAvailable;
  final bool isMockMode;

  const NativeRenderingInfo({
    required this.currentImplementation,
    required this.isFFIAvailable,
    required this.isPlatformChannelAvailable,
    required this.isMockMode,
  });

  bool get isNativeRenderingAvailable => isFFIAvailable || isPlatformChannelAvailable;
  
  String get implementationName {
    switch (currentImplementation) {
      case NativeRenderingImplementation.ffi:
        return 'FFI (Foreign Function Interface)';
      case NativeRenderingImplementation.platformChannel:
        return 'Platform Channel';
      case NativeRenderingImplementation.mock:
        return 'Mock (Development)';
      case NativeRenderingImplementation.auto:
        return 'Auto-detected';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NativeRenderingInfo &&
        other.currentImplementation == currentImplementation &&
        other.isFFIAvailable == isFFIAvailable &&
        other.isPlatformChannelAvailable == isPlatformChannelAvailable &&
        other.isMockMode == isMockMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      currentImplementation,
      isFFIAvailable,
      isPlatformChannelAvailable,
      isMockMode,
    );
  }
}

/// Available native rendering implementations
enum NativeRenderingImplementation {
  auto,
  ffi,
  platformChannel,
  mock,
}

/// Mock cache service for development
class MockCacheService {
  final Map<String, Map<int, Map<String, Uint8List>>> _cache = {};

  MockCacheService();

  Future<Uint8List?> getCachedPageImage(
    String documentId, 
    int pageNumber, {
    String format = 'webp',
  }) async {
    return _cache[documentId]?[pageNumber]?[format];
  }

  Future<void> cachePageImage(
    String documentId, 
    int pageNumber, 
    Uint8List imageData, {
    String format = 'webp',
  }) async {
    _cache.putIfAbsent(documentId, () => {})
        .putIfAbsent(pageNumber, () => {})[format] = imageData;
  }

  Future<void> clearDocumentCache(String documentId) async {
    _cache.remove(documentId);
  }

  Future<void> clearCache() async {
    _cache.clear();
  }

  Future<int> getCacheSize() async {
    int totalSize = 0;
    for (final document in _cache.values) {
      for (final page in document.values) {
        for (final imageData in page.values) {
          totalSize += imageData.length;
        }
      }
    }
    return totalSize;
  }
}