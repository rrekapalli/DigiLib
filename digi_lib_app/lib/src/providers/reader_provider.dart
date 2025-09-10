import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/document.dart';
import '../models/ui/reader_settings.dart';
import '../models/ui/reader_state.dart' as reader_state;
import '../models/ui/page_render_result.dart' as ui;
import '../services/page_rendering_service.dart';
import 'native_rendering_provider.dart';
import '../services/reading_progress_service.dart';
import '../services/document_service.dart';

// PageRenderingService provider is imported from native_rendering_provider.dart

/// Provider for reading progress service
final readingProgressServiceProvider = Provider<ReadingProgressService>((ref) {
  throw UnimplementedError('ReadingProgressService must be overridden');
});

/// Provider for document service
final documentServiceProvider = Provider<DocumentService>((ref) {
  throw UnimplementedError('DocumentService must be overridden');
});

/// Provider for reader settings
final readerSettingsProvider = StateNotifierProvider<ReaderSettingsNotifier, ReaderSettings>((ref) {
  return ReaderSettingsNotifier();
});

/// Provider for reader state
final readerStateProvider = StateNotifierProvider.family<ReaderStateNotifier, AsyncValue<reader_state.ReaderState>, String>((ref, documentId) {
  return ReaderStateNotifier(
    documentId: documentId,
    pageRenderingService: ref.watch(pageRenderingServiceProvider),
    readingProgressService: ref.watch(readingProgressServiceProvider),
    documentService: ref.watch(documentServiceProvider),
  );
});

/// Provider for current document
final currentDocumentProvider = FutureProvider.family<Document, String>((ref, documentId) async {
  final documentService = ref.watch(documentServiceProvider);
  return await documentService.getDocument(documentId);
});

/// Notifier for reader settings
class ReaderSettingsNotifier extends StateNotifier<ReaderSettings> {
  ReaderSettingsNotifier() : super(const ReaderSettings());

  /// Update reading mode
  void updateReadingMode(ReadingMode mode) {
    state = state.copyWith(readingMode: mode);
  }

  /// Update page fit mode
  void updatePageFitMode(PageFitMode mode) {
    state = state.copyWith(pageFitMode: mode);
  }

  /// Update theme
  void updateTheme(ReaderTheme theme) {
    state = state.copyWith(theme: theme);
  }

  /// Update brightness
  void updateBrightness(double brightness) {
    state = state.copyWith(brightness: brightness.clamp(0.1, 1.0));
  }

  /// Update zoom level
  void updateZoom(double zoom) {
    state = state.copyWith(zoom: zoom.clamp(0.5, 5.0));
  }

  /// Toggle page numbers visibility
  void togglePageNumbers() {
    state = state.copyWith(showPageNumbers: !state.showPageNumbers);
  }

  /// Toggle text selection
  void toggleTextSelection() {
    state = state.copyWith(enableTextSelection: !state.enableTextSelection);
  }

  /// Toggle annotations
  void toggleAnnotations() {
    state = state.copyWith(enableAnnotations: !state.enableAnnotations);
  }

  /// Toggle page preloading
  void togglePreloading() {
    state = state.copyWith(preloadPages: !state.preloadPages);
  }

  /// Update preload count
  void updatePreloadCount(int count) {
    state = state.copyWith(preloadCount: count.clamp(1, 10));
  }

  /// Reset to defaults
  void resetToDefaults() {
    state = const ReaderSettings();
  }

  /// Load settings from storage (to be implemented)
  Future<void> loadSettings() async {
    // TODO: Load from secure storage or preferences
  }

  /// Save settings to storage (to be implemented)
  Future<void> saveSettings() async {
    // TODO: Save to secure storage or preferences
  }
}

/// Notifier for reader state
class ReaderStateNotifier extends StateNotifier<AsyncValue<reader_state.ReaderState>> {
  final String documentId;
  final PageRenderingService _pageRenderingService;
  final ReadingProgressService _readingProgressService;
  final DocumentService _documentService;

  Timer? _progressSaveTimer;
  static const Duration _progressSaveDelay = Duration(seconds: 2);

  ReaderStateNotifier({
    required this.documentId,
    required PageRenderingService pageRenderingService,
    required ReadingProgressService readingProgressService,
    required DocumentService documentService,
  }) : _pageRenderingService = pageRenderingService,
       _readingProgressService = readingProgressService,
       _documentService = documentService,
       super(const AsyncValue.loading()) {
    _initializeReader();
  }

  /// Initialize the reader with document data
  Future<void> _initializeReader() async {
    try {
      state = const AsyncValue.loading();

      // Get document information
      final document = await _documentService.getDocument(documentId);
      final totalPages = document.pageCount ?? 0;

      if (totalPages <= 0) {
        state = AsyncValue.error('Document has no pages', StackTrace.current);
        return;
      }

      // Get reading progress
      final progress = await _readingProgressService.getReadingProgress('current_user', documentId);
      final currentPage = progress?.lastPage ?? 1;

      // Create initial state
      final readerState = reader_state.ReaderState(
        documentId: documentId,
        currentPage: currentPage,
        totalPages: totalPages,
        lastUpdated: DateTime.now(),
      );

      state = AsyncValue.data(readerState);

      // Preload current page
      _preloadPage(currentPage);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Navigate to specific page
  Future<void> goToPage(int pageNumber) async {
    final currentState = state.value;
    if (currentState == null) return;

    final clampedPage = pageNumber.clamp(1, currentState.totalPages);
    if (clampedPage == currentState.currentPage) return;

    try {
      state = AsyncValue.data(
        currentState.copyWith(
          currentPage: clampedPage,
          isLoading: true,
          lastUpdated: DateTime.now(),
        ),
      );

      // Preload the new page
      await _preloadPage(clampedPage);

      // Update reading progress with debouncing
      _scheduleProgressSave(clampedPage);

      state = AsyncValue.data(
        currentState.copyWith(
          currentPage: clampedPage,
          isLoading: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Navigate to next page
  Future<void> nextPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.isLastPage) return;

    await goToPage(currentState.currentPage + 1);
  }

  /// Navigate to previous page
  Future<void> previousPage() async {
    final currentState = state.value;
    if (currentState == null || currentState.isFirstPage) return;

    await goToPage(currentState.currentPage - 1);
  }

  /// Update zoom level
  void updateZoom(double zoomLevel) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(
        zoomLevel: zoomLevel.clamp(0.5, 5.0),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Update scroll offset
  void updateScrollOffset(double offset) {
    final currentState = state.value;
    if (currentState == null) return;

    state = AsyncValue.data(
      currentState.copyWith(
        scrollOffset: offset,
        lastUpdated: DateTime.now(),
      ),
    );
  }

  /// Refresh current page
  Future<void> refresh() async {
    final currentState = state.value;
    if (currentState == null) return;

    try {
      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: true,
          error: null,
          lastUpdated: DateTime.now(),
        ),
      );

      // Clear cache for current page and reload
      await _pageRenderingService.clearDocumentCache(documentId);
      await _preloadPage(currentState.currentPage);

      state = AsyncValue.data(
        currentState.copyWith(
          isLoading: false,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Preload a specific page
  Future<void> _preloadPage(int pageNumber) async {
    try {
      await _pageRenderingService.renderPage(
        documentId,
        pageNumber,
        preloadNext: true,
      );
    } catch (e) {
      // Ignore preload errors to not break the reading experience
    }
  }

  /// Schedule progress save with debouncing
  void _scheduleProgressSave(int pageNumber) {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = Timer(_progressSaveDelay, () {
      _readingProgressService.updateReadingProgressAutoSave(
        'current_user', // TODO: Get actual user ID
        documentId,
        pageNumber,
      );
    });
  }

  /// Force save reading progress
  Future<void> saveProgress() async {
    _progressSaveTimer?.cancel();
    final currentState = state.value;
    if (currentState == null) return;

    try {
      await _readingProgressService.updateReadingProgress(
        'current_user', // TODO: Get actual user ID
        documentId,
        currentState.currentPage,
      );
    } catch (e) {
      // Ignore save errors to not break the reading experience
    }
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    super.dispose();
  }
}

/// Provider for page image data
final pageImageProvider = FutureProvider.family<ui.PageRenderResult, PageRequest>((ref, request) async {
  final pageRenderingService = ref.watch(pageRenderingServiceProvider);
  return await pageRenderingService.renderPage(
    request.documentId,
    request.pageNumber,
    dpi: request.dpi,
    format: request.format,
  );
});

/// Request model for page rendering
class PageRequest {
  final String documentId;
  final int pageNumber;
  final int dpi;
  final String format;

  const PageRequest({
    required this.documentId,
    required this.pageNumber,
    this.dpi = 150,
    this.format = 'webp',
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageRequest &&
        other.documentId == documentId &&
        other.pageNumber == pageNumber &&
        other.dpi == dpi &&
        other.format == format;
  }

  @override
  int get hashCode {
    return Object.hash(documentId, pageNumber, dpi, format);
  }

  @override
  String toString() {
    return 'PageRequest(documentId: $documentId, pageNumber: $pageNumber, dpi: $dpi, format: $format)';
  }
}