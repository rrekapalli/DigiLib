import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entities/library.dart';
import '../models/api/create_library_request.dart';
import '../models/api/scan_job.dart';
import '../services/library_service.dart';
import '../services/library_api_service.dart';
import '../database/repositories/library_repository.dart';
import '../database/database_helper.dart';
import '../services/job_queue_service.dart';
import 'connectivity_provider.dart';

/// Provider for DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provider for LibraryRepository
final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return LibraryRepositoryImpl(databaseHelper);
});

/// Provider for LibraryApiService
final libraryApiServiceProvider = Provider<LibraryApiService>((ref) {
  // This would be injected from a higher level provider in a real app
  // For now, we'll use a mock implementation
  return MockLibraryApiService();
});

// connectivityServiceProvider is now imported from connectivity_provider.dart

/// Provider for JobQueueService
final jobQueueServiceProvider = Provider<JobQueueService>((ref) {
  final databaseHelper = ref.watch(databaseHelperProvider);
  return JobQueueService(databaseHelper: databaseHelper);
});

/// Provider for LibraryService
final libraryServiceProvider = Provider<LibraryService>((ref) {
  final apiService = ref.watch(libraryApiServiceProvider);
  final repository = ref.watch(libraryRepositoryProvider);
  final connectivityService = ref.watch(connectivityServiceProvider);
  final jobQueueService = ref.watch(jobQueueServiceProvider);
  
  return LibraryServiceImpl(
    apiService,
    repository,
    connectivityService,
    jobQueueService,
  );
});

/// State for library management
class LibraryState {
  final List<Library> libraries;
  final bool isLoading;
  final String? error;
  final bool isRefreshing;
  final Map<String, ScanProgress> scanProgress;

  const LibraryState({
    this.libraries = const [],
    this.isLoading = false,
    this.error,
    this.isRefreshing = false,
    this.scanProgress = const {},
  });

  LibraryState copyWith({
    List<Library>? libraries,
    bool? isLoading,
    String? error,
    bool? isRefreshing,
    Map<String, ScanProgress>? scanProgress,
  }) {
    return LibraryState(
      libraries: libraries ?? this.libraries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      scanProgress: scanProgress ?? this.scanProgress,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LibraryState &&
        other.libraries == libraries &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.isRefreshing == isRefreshing &&
        other.scanProgress == scanProgress;
  }

  @override
  int get hashCode {
    return Object.hash(
      libraries,
      isLoading,
      error,
      isRefreshing,
      scanProgress,
    );
  }
}

/// Notifier for managing library state
class LibraryNotifier extends StateNotifier<LibraryState> {
  final LibraryService _libraryService;
  final Map<String, StreamSubscription> _scanSubscriptions = {};

  LibraryNotifier(this._libraryService) : super(const LibraryState()) {
    _loadLibraries();
  }

  @override
  void dispose() {
    // Cancel all scan progress subscriptions
    for (final subscription in _scanSubscriptions.values) {
      subscription.cancel();
    }
    _scanSubscriptions.clear();
    super.dispose();
  }

  /// Load libraries from service
  Future<void> _loadLibraries() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final libraries = await _libraryService.getLibraries();
      state = state.copyWith(
        libraries: libraries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load libraries: $e',
      );
    }
  }

  /// Refresh libraries from server
  Future<void> refreshLibraries() async {
    if (state.isRefreshing) return;

    state = state.copyWith(isRefreshing: true, error: null);

    try {
      await _libraryService.refreshLibraries();
      final libraries = await _libraryService.getLibraries();
      state = state.copyWith(
        libraries: libraries,
        isRefreshing: false,
      );
    } catch (e) {
      state = state.copyWith(
        isRefreshing: false,
        error: 'Failed to refresh libraries: $e',
      );
    }
  }

  /// Add a new library
  Future<void> addLibrary(CreateLibraryRequest request) async {
    try {
      state = state.copyWith(error: null);
      
      final library = await _libraryService.addLibrary(request);
      
      // Add to current state
      final updatedLibraries = [...state.libraries, library];
      state = state.copyWith(libraries: updatedLibraries);
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add library: $e',
      );
      rethrow;
    }
  }

  /// Delete a library
  Future<void> deleteLibrary(String libraryId) async {
    try {
      state = state.copyWith(error: null);
      
      await _libraryService.deleteLibrary(libraryId);
      
      // Remove from current state
      final updatedLibraries = state.libraries
          .where((library) => library.id != libraryId)
          .toList();
      state = state.copyWith(libraries: updatedLibraries);
      
      // Cancel any scan progress subscription for this library
      _scanSubscriptions[libraryId]?.cancel();
      _scanSubscriptions.remove(libraryId);
      
      // Remove scan progress for this library
      final updatedScanProgress = Map<String, ScanProgress>.from(state.scanProgress);
      updatedScanProgress.remove(libraryId);
      state = state.copyWith(scanProgress: updatedScanProgress);
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete library: $e',
      );
      rethrow;
    }
  }

  /// Start scanning a library
  Future<ScanJob> scanLibrary(String libraryId) async {
    try {
      state = state.copyWith(error: null);
      
      final scanJob = await _libraryService.scanLibrary(libraryId);
      
      // Start watching scan progress
      _watchScanProgress(libraryId);
      
      return scanJob;
      
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to start library scan: $e',
      );
      rethrow;
    }
  }

  /// Cancel a scan job
  Future<void> cancelScanJob(String jobId) async {
    try {
      await _libraryService.cancelScanJob(jobId);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to cancel scan job: $e',
      );
      rethrow;
    }
  }

  /// Watch scan progress for a library
  void _watchScanProgress(String libraryId) {
    // Cancel existing subscription if any
    _scanSubscriptions[libraryId]?.cancel();
    
    // Start new subscription
    _scanSubscriptions[libraryId] = _libraryService
        .watchScanProgress(libraryId)
        .listen(
      (progress) {
        final updatedScanProgress = Map<String, ScanProgress>.from(state.scanProgress);
        updatedScanProgress[libraryId] = progress;
        state = state.copyWith(scanProgress: updatedScanProgress);
        
        // Clean up subscription if scan is completed or failed
        if (progress.status == 'completed' || 
            progress.status == 'failed' || 
            progress.status == 'cancelled') {
          _scanSubscriptions[libraryId]?.cancel();
          _scanSubscriptions.remove(libraryId);
        }
      },
      onError: (error) {
        state = state.copyWith(
          error: 'Scan progress error: $error',
        );
      },
    );
  }

  /// Get scan progress for a library
  ScanProgress? getScanProgress(String libraryId) {
    return state.scanProgress[libraryId];
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Retry loading libraries
  Future<void> retry() async {
    await _loadLibraries();
  }

  /// Sync pending operations
  Future<void> syncPendingOperations() async {
    try {
      await _libraryService.syncPendingOperations();
      // Refresh libraries after sync
      await refreshLibraries();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to sync pending operations: $e',
      );
    }
  }
}

/// Provider for LibraryNotifier
final libraryProvider = StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  final libraryService = ref.watch(libraryServiceProvider);
  return LibraryNotifier(libraryService);
});

/// Provider for getting a specific library by ID
final libraryByIdProvider = Provider.family<Library?, String>((ref, libraryId) {
  final libraryState = ref.watch(libraryProvider);
  return libraryState.libraries.cast<Library?>().firstWhere(
    (library) => library?.id == libraryId,
    orElse: () => null,
  );
});

/// Provider for getting scan progress for a specific library
final scanProgressProvider = Provider.family<ScanProgress?, String>((ref, libraryId) {
  final libraryState = ref.watch(libraryProvider);
  return libraryState.scanProgress[libraryId];
});

/// Provider for getting all libraries as a simple list
final librariesProvider = Provider<AsyncValue<List<Library>>>((ref) {
  final libraryState = ref.watch(libraryProvider);
  
  if (libraryState.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (libraryState.error != null) {
    return AsyncValue.error(libraryState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(libraryState.libraries);
});