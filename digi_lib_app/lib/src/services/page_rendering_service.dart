import 'dart:typed_data';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'document_api_service.dart';
import 'cache_service.dart';
import '../models/api/render_response.dart';

/// Result of page rendering operation
class PageRenderResult {
  final Uint8List imageData;
  final String format;
  final int dpi;
  final bool fromCache;
  final bool fromNative;
  final String? sourceUrl;

  const PageRenderResult({
    required this.imageData,
    required this.format,
    required this.dpi,
    this.fromCache = false,
    this.fromNative = false,
    this.sourceUrl,
  });

  @override
  String toString() {
    return 'PageRenderResult(format: $format, dpi: $dpi, fromCache: $fromCache, fromNative: $fromNative, sourceUrl: $sourceUrl, dataSize: ${imageData.length})';
  }
}

/// Interface for native rendering worker
abstract class NativeRenderingWorker {
  /// Render a page to image data
  Future<Uint8List> renderPage(String filePath, int page, int dpi);
  
  /// Extract text from a page
  Future<String> extractText(String filePath, int page);
  
  /// Get total page count for a document
  Future<int> getPageCount(String filePath);
  
  /// Check if native rendering is available
  bool get isAvailable;
}

/// Service for rendering document pages combining API and native rendering
abstract class PageRenderingService {
  /// Render a page with fallback to native rendering
  Future<PageRenderResult> renderPage(
    String documentId, 
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
    bool useCache = true,
    bool preloadNext = true,
  });
  
  /// Get page render URL from server
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  });
  
  /// Preload pages for better user experience
  Future<void> preloadPages(
    String documentId,
    List<int> pageNumbers, {
    int dpi = 150,
    String format = 'webp',
  });
  
  /// Clear cached pages for a document
  Future<void> clearDocumentCache(String documentId);
  
  /// Check if page is cached
  Future<bool> isPageCached(
    String documentId, 
    int pageNumber, {
    String format = 'webp',
  });
  
  /// Get rendering statistics
  Future<RenderingStatistics> getRenderingStatistics();
}

/// Implementation of PageRenderingService
class PageRenderingServiceImpl implements PageRenderingService {
  final DocumentApiService _documentApiService;
  final CacheService _cacheService;
  final NativeRenderingWorker? _nativeWorker;
  final http.Client _httpClient;

  // Statistics tracking
  int _apiRenderCount = 0;
  int _nativeRenderCount = 0;
  int _cacheHitCount = 0;
  int _renderFailureCount = 0;

  PageRenderingServiceImpl(
    this._documentApiService,
    this._cacheService,
    this._nativeWorker,
    this._httpClient,
  );

  @override
  Future<PageRenderResult> renderPage(
    String documentId, 
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
    bool useCache = true,
    bool preloadNext = true,
  }) async {
    try {
      // Check cache first if enabled
      if (useCache) {
        final cachedImage = await _cacheService.getCachedPageImage(
          documentId, 
          pageNumber, 
          format: format,
        );
        
        if (cachedImage != null) {
          _cacheHitCount++;
          
          // Preload next page in background if requested
          if (preloadNext) {
            _preloadNextPageInBackground(documentId, pageNumber, dpi: dpi, format: format);
          }
          
          return PageRenderResult(
            imageData: cachedImage,
            format: format,
            dpi: dpi,
            fromCache: true,
          );
        }
      }

      // Try API rendering first
      try {
        final result = await _renderPageViaApi(documentId, pageNumber, dpi: dpi, format: format);
        
        // Cache the result if successful
        if (useCache) {
          await _cacheService.cachePageImage(documentId, pageNumber, result.imageData, format: format);
        }
        
        // Preload next page in background if requested
        if (preloadNext) {
          _preloadNextPageInBackground(documentId, pageNumber, dpi: dpi, format: format);
        }
        
        _apiRenderCount++;
        return result;
      } catch (apiError) {
        // Fallback to native rendering if API fails
        if (_nativeWorker != null && _nativeWorker.isAvailable) {
          try {
            final result = await _renderPageViaNative(documentId, pageNumber, dpi: dpi, format: format);
            
            // Cache the result if successful
            if (useCache) {
              await _cacheService.cachePageImage(documentId, pageNumber, result.imageData, format: format);
            }
            
            // Preload next page in background if requested
            if (preloadNext) {
              _preloadNextPageInBackground(documentId, pageNumber, dpi: dpi, format: format);
            }
            
            _nativeRenderCount++;
            return result;
          } catch (nativeError) {
            _renderFailureCount++;
            throw PageRenderingException(
              'Both API and native rendering failed. API error: $apiError, Native error: $nativeError',
            );
          }
        } else {
          _renderFailureCount++;
          throw PageRenderingException(
            'API rendering failed and native rendering is not available: $apiError',
          );
        }
      }
    } catch (e) {
      _renderFailureCount++;
      if (e is PageRenderingException) {
        rethrow;
      }
      throw PageRenderingException('Failed to render page: $e');
    }
  }

  @override
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  }) async {
    try {
      return await _documentApiService.getPageRenderUrl(
        documentId, 
        page, 
        dpi: dpi, 
        format: format,
      );
    } catch (e) {
      throw PageRenderingException('Failed to get page render URL: $e');
    }
  }

  @override
  Future<void> preloadPages(
    String documentId,
    List<int> pageNumbers, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    final futures = pageNumbers.map((pageNumber) async {
      try {
        // Check if already cached
        final isCached = await isPageCached(documentId, pageNumber, format: format);
        if (!isCached) {
          await renderPage(
            documentId, 
            pageNumber, 
            dpi: dpi, 
            format: format,
            preloadNext: false, // Avoid recursive preloading
          );
        }
      } catch (e) {
        // Continue with other pages if one fails
      }
    });

    // Wait for all preloading to complete
    await Future.wait(futures);
  }

  @override
  Future<void> clearDocumentCache(String documentId) async {
    try {
      await _cacheService.clearDocumentCache(documentId);
    } catch (e) {
      throw PageRenderingException('Failed to clear document cache: $e');
    }
  }

  @override
  Future<bool> isPageCached(
    String documentId, 
    int pageNumber, {
    String format = 'webp',
  }) async {
    try {
      final cachedImage = await _cacheService.getCachedPageImage(
        documentId, 
        pageNumber, 
        format: format,
      );
      return cachedImage != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<RenderingStatistics> getRenderingStatistics() async {
    final cacheStats = await _cacheService.getCacheStatistics();
    
    return RenderingStatistics(
      apiRenderCount: _apiRenderCount,
      nativeRenderCount: _nativeRenderCount,
      cacheHitCount: _cacheHitCount,
      renderFailureCount: _renderFailureCount,
      totalRenderCount: _apiRenderCount + _nativeRenderCount,
      cacheStatistics: cacheStats,
      nativeWorkerAvailable: _nativeWorker?.isAvailable ?? false,
    );
  }

  /// Render page via API
  Future<PageRenderResult> _renderPageViaApi(
    String documentId, 
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    // Get signed URL from API
    final renderResponse = await _documentApiService.getPageRenderUrl(
      documentId, 
      pageNumber, 
      dpi: dpi, 
      format: format,
    );

    // Check if URL is expired
    if (renderResponse.expiresAt.isBefore(DateTime.now())) {
      throw PageRenderingException('Render URL has expired');
    }

    // Download the rendered image
    final response = await _httpClient.get(Uri.parse(renderResponse.signedUrl));
    
    if (response.statusCode != 200) {
      throw PageRenderingException(
        'Failed to download rendered page: HTTP ${response.statusCode}',
      );
    }

    return PageRenderResult(
      imageData: response.bodyBytes,
      format: format,
      dpi: dpi,
      sourceUrl: renderResponse.signedUrl,
    );
  }

  /// Render page via native worker
  Future<PageRenderResult> _renderPageViaNative(
    String documentId, 
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    if (_nativeWorker == null || !_nativeWorker.isAvailable) {
      throw PageRenderingException('Native rendering worker is not available');
    }

    // Get document information to find file path
    final document = await _documentApiService.getDocument(documentId);
    
    if (document.fullPath == null) {
      throw PageRenderingException('Document file path is not available for native rendering');
    }

    // Check if file exists
    final file = File(document.fullPath!);
    if (!await file.exists()) {
      throw PageRenderingException('Document file not found: ${document.fullPath}');
    }

    // Render page using native worker
    final imageData = await _nativeWorker.renderPage(
      document.fullPath!, 
      pageNumber, 
      dpi,
    );

    return PageRenderResult(
      imageData: imageData,
      format: format,
      dpi: dpi,
      fromNative: true,
    );
  }

  /// Preload next page in background
  void _preloadNextPageInBackground(
    String documentId, 
    int currentPage, {
    int dpi = 150,
    String format = 'webp',
  }) {
    // Run in background without awaiting
    Future(() async {
      try {
        final nextPage = currentPage + 1;
        final isCached = await isPageCached(documentId, nextPage, format: format);
        
        if (!isCached) {
          await renderPage(
            documentId, 
            nextPage, 
            dpi: dpi, 
            format: format,
            preloadNext: false, // Avoid recursive preloading
          );
        }
      } catch (e) {
        // Ignore preloading errors
      }
    });
  }
}

/// Mock implementation for testing
class MockPageRenderingService implements PageRenderingService {
  final Map<String, Map<int, Uint8List>> _mockPages = {};
  int _renderCount = 0;

  MockPageRenderingService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Create mock page data
    final mockImageData = Uint8List.fromList([
      // Simple 1x1 WebP image data (mock)
      0x52, 0x49, 0x46, 0x46, 0x1A, 0x00, 0x00, 0x00,
      0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x20,
      0x0E, 0x00, 0x00, 0x00, 0x30, 0x01, 0x00, 0x9D,
      0x01, 0x2A, 0x01, 0x00, 0x01, 0x00, 0x02, 0x00,
    ]);

    // Add mock pages for test documents
    _mockPages['mock-doc-1'] = {
      for (int i = 1; i <= 10; i++) i: mockImageData,
    };
    
    _mockPages['mock-doc-2'] = {
      for (int i = 1; i <= 5; i++) i: mockImageData,
    };
  }

  @override
  Future<PageRenderResult> renderPage(
    String documentId, 
    int pageNumber, {
    int dpi = 150,
    String format = 'webp',
    bool useCache = true,
    bool preloadNext = true,
  }) async {
    _renderCount++;
    
    final documentPages = _mockPages[documentId];
    if (documentPages == null) {
      throw PageRenderingException('Mock document not found: $documentId');
    }

    final pageData = documentPages[pageNumber];
    if (pageData == null) {
      throw PageRenderingException('Mock page not found: $documentId page $pageNumber');
    }

    // Simulate some processing time
    await Future.delayed(const Duration(milliseconds: 100));

    return PageRenderResult(
      imageData: pageData,
      format: format,
      dpi: dpi,
      fromCache: _renderCount % 3 == 0, // Simulate cache hits
    );
  }

  @override
  Future<RenderResponse> getPageRenderUrl(
    String documentId, 
    int page, {
    int dpi = 150, 
    String format = 'webp',
  }) async {
    return RenderResponse(
      signedUrl: 'https://mock-api.example.com/render/$documentId/page/$page?dpi=$dpi&format=$format&token=mock-token',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    );
  }

  @override
  Future<void> preloadPages(
    String documentId,
    List<int> pageNumbers, {
    int dpi = 150,
    String format = 'webp',
  }) async {
    // Simulate preloading
    for (final pageNumber in pageNumbers) {
      await renderPage(documentId, pageNumber, dpi: dpi, format: format, preloadNext: false);
    }
  }

  @override
  Future<void> clearDocumentCache(String documentId) async {
    // Mock implementation - no actual cache to clear
  }

  @override
  Future<bool> isPageCached(
    String documentId, 
    int pageNumber, {
    String format = 'webp',
  }) async {
    // Simulate some pages being cached
    return (documentId.hashCode + pageNumber) % 3 == 0;
  }

  @override
  Future<RenderingStatistics> getRenderingStatistics() async {
    return RenderingStatistics(
      apiRenderCount: _renderCount ~/ 2,
      nativeRenderCount: _renderCount - (_renderCount ~/ 2),
      cacheHitCount: _renderCount ~/ 3,
      renderFailureCount: 0,
      totalRenderCount: _renderCount,
      cacheStatistics: CacheStatistics.empty(500 * 1024 * 1024),
      nativeWorkerAvailable: true,
    );
  }

  /// Add mock page data for testing
  void addMockPage(String documentId, int pageNumber, Uint8List imageData) {
    _mockPages.putIfAbsent(documentId, () => {})[pageNumber] = imageData;
  }

  /// Clear all mock data
  void clearMockData() {
    _mockPages.clear();
    _renderCount = 0;
  }
}

/// Mock native rendering worker for testing
class MockNativeRenderingWorker implements NativeRenderingWorker {
  @override
  bool get isAvailable => true;

  @override
  Future<Uint8List> renderPage(String filePath, int page, int dpi) async {
    // Simulate rendering time
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Return mock image data
    return Uint8List.fromList([
      0x52, 0x49, 0x46, 0x46, 0x1A, 0x00, 0x00, 0x00,
      0x57, 0x45, 0x42, 0x50, 0x56, 0x50, 0x38, 0x20,
      0x0E, 0x00, 0x00, 0x00, 0x30, 0x01, 0x00, 0x9D,
      0x01, 0x2A, 0x01, 0x00, 0x01, 0x00, 0x02, 0x00,
    ]);
  }

  @override
  Future<String> extractText(String filePath, int page) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return 'Mock text content for page $page from $filePath';
  }

  @override
  Future<int> getPageCount(String filePath) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return 10; // Mock page count
  }
}

/// Rendering statistics model
class RenderingStatistics {
  final int apiRenderCount;
  final int nativeRenderCount;
  final int cacheHitCount;
  final int renderFailureCount;
  final int totalRenderCount;
  final CacheStatistics cacheStatistics;
  final bool nativeWorkerAvailable;

  const RenderingStatistics({
    required this.apiRenderCount,
    required this.nativeRenderCount,
    required this.cacheHitCount,
    required this.renderFailureCount,
    required this.totalRenderCount,
    required this.cacheStatistics,
    required this.nativeWorkerAvailable,
  });

  double get apiRenderPercentage => totalRenderCount > 0 ? (apiRenderCount / totalRenderCount) * 100 : 0;
  double get nativeRenderPercentage => totalRenderCount > 0 ? (nativeRenderCount / totalRenderCount) * 100 : 0;
  double get cacheHitPercentage => (totalRenderCount + cacheHitCount) > 0 ? (cacheHitCount / (totalRenderCount + cacheHitCount)) * 100 : 0;
  double get failurePercentage => (totalRenderCount + renderFailureCount) > 0 ? (renderFailureCount / (totalRenderCount + renderFailureCount)) * 100 : 0;

  @override
  String toString() {
    return 'RenderingStatistics(apiRenders: $apiRenderCount, nativeRenders: $nativeRenderCount, cacheHits: $cacheHitCount, failures: $renderFailureCount, total: $totalRenderCount, nativeAvailable: $nativeWorkerAvailable)';
  }
}

/// Page rendering exception
class PageRenderingException implements Exception {
  final String message;

  const PageRenderingException(this.message);

  @override
  String toString() => 'PageRenderingException: $message';
}