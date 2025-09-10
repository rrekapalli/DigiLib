import 'dart:async';
import '../network/api_client.dart';
import '../models/entities/library.dart';
import '../models/api/create_library_request.dart';
import '../models/api/scan_job.dart';
import '../models/api/api_error.dart';

/// Progress information for scan operations
class ScanProgress {
  final String jobId;
  final String libraryId;
  final String status;
  final int progress;
  final DateTime timestamp;
  final String? error;

  const ScanProgress({
    required this.jobId,
    required this.libraryId,
    required this.status,
    required this.progress,
    required this.timestamp,
    this.error,
  });

  factory ScanProgress.fromScanJob(ScanJob job, {String? error}) {
    return ScanProgress(
      jobId: job.id,
      libraryId: job.libraryId,
      status: job.status,
      progress: job.progress,
      timestamp: DateTime.now(),
      error: error,
    );
  }

  @override
  String toString() {
    return 'ScanProgress(jobId: $jobId, libraryId: $libraryId, status: $status, progress: $progress, timestamp: $timestamp, error: $error)';
  }
}

/// Service for handling library management API calls
abstract class LibraryApiService {
  /// Get all libraries for the current user
  Future<List<Library>> getLibraries();
  
  /// Add a new library
  Future<Library> addLibrary(CreateLibraryRequest request);
  
  /// Get a specific library by ID
  Future<Library> getLibrary(String libraryId);
  
  /// Start scanning a library for documents
  Future<ScanJob> scanLibrary(String libraryId);
  
  /// Delete a library
  Future<void> deleteLibrary(String libraryId);
  
  /// Watch scan progress for a library
  Stream<ScanProgress> watchScanProgress(String libraryId);
  
  /// Get scan job status
  Future<ScanJob> getScanJob(String jobId);
  
  /// Cancel a running scan job
  Future<void> cancelScanJob(String jobId);
}

/// Implementation of LibraryApiService
class LibraryApiServiceImpl implements LibraryApiService {
  final ApiClient _apiClient;
  final Map<String, StreamController<ScanProgress>> _scanProgressControllers = {};
  final Map<String, Timer> _scanPollingTimers = {};

  LibraryApiServiceImpl(this._apiClient);

  @override
  Future<List<Library>> getLibraries() async {
    try {
      final response = await _apiClient.get<List<dynamic>>('/api/libraries');
      return response.map((json) => Library.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to get libraries');
    }
  }

  @override
  Future<Library> addLibrary(CreateLibraryRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/libraries',
        body: request.toJson(),
      );
      return Library.fromJson(response);
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to add library');
    }
  }

  @override
  Future<Library> getLibrary(String libraryId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/libraries/$libraryId');
      return Library.fromJson(response);
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to get library');
    }
  }

  @override
  Future<ScanJob> scanLibrary(String libraryId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>('/api/libraries/$libraryId/scan');
      final scanJob = ScanJob.fromJson(response);
      
      // Start watching progress for this scan job
      _startWatchingScanProgress(scanJob);
      
      return scanJob;
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to start library scan');
    }
  }

  @override
  Future<void> deleteLibrary(String libraryId) async {
    try {
      await _apiClient.delete('/api/libraries/$libraryId');
      
      // Clean up any active scan progress watching
      _stopWatchingScanProgress(libraryId);
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to delete library');
    }
  }

  @override
  Stream<ScanProgress> watchScanProgress(String libraryId) {
    // Create or get existing controller for this library
    if (!_scanProgressControllers.containsKey(libraryId)) {
      _scanProgressControllers[libraryId] = StreamController<ScanProgress>.broadcast();
    }
    
    return _scanProgressControllers[libraryId]!.stream;
  }

  @override
  Future<ScanJob> getScanJob(String jobId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/api/scan-jobs/$jobId');
      return ScanJob.fromJson(response);
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to get scan job');
    }
  }

  @override
  Future<void> cancelScanJob(String jobId) async {
    try {
      await _apiClient.post('/api/scan-jobs/$jobId/cancel');
    } catch (e) {
      throw _handleLibraryError(e, 'Failed to cancel scan job');
    }
  }

  /// Start watching scan progress for a scan job
  void _startWatchingScanProgress(ScanJob scanJob) {
    final libraryId = scanJob.libraryId;
    
    // Don't start if already watching
    if (_scanPollingTimers.containsKey(libraryId)) {
      return;
    }

    // Create controller if it doesn't exist
    if (!_scanProgressControllers.containsKey(libraryId)) {
      _scanProgressControllers[libraryId] = StreamController<ScanProgress>.broadcast();
    }

    final controller = _scanProgressControllers[libraryId]!;
    
    // Emit initial progress
    controller.add(ScanProgress.fromScanJob(scanJob));

    // Start polling for updates
    _scanPollingTimers[libraryId] = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        final updatedJob = await getScanJob(scanJob.id);
        final progress = ScanProgress.fromScanJob(updatedJob);
        
        controller.add(progress);
        
        // Stop polling if job is completed or failed
        if (updatedJob.status == 'completed' || updatedJob.status == 'failed') {
          timer.cancel();
          _scanPollingTimers.remove(libraryId);
          
          // Keep controller open for a bit in case there are late subscribers
          Timer(const Duration(seconds: 30), () {
            controller.close();
            _scanProgressControllers.remove(libraryId);
          });
        }
      } catch (e) {
        // Emit error progress
        controller.add(ScanProgress(
          jobId: scanJob.id,
          libraryId: libraryId,
          status: 'error',
          progress: 0,
          timestamp: DateTime.now(),
          error: e.toString(),
        ));
        
        // Stop polling on error
        timer.cancel();
        _scanPollingTimers.remove(libraryId);
      }
    });
  }

  /// Stop watching scan progress for a library
  void _stopWatchingScanProgress(String libraryId) {
    _scanPollingTimers[libraryId]?.cancel();
    _scanPollingTimers.remove(libraryId);
    
    _scanProgressControllers[libraryId]?.close();
    _scanProgressControllers.remove(libraryId);
  }

  /// Handle library-specific errors
  ApiException _handleLibraryError(Object error, String context) {
    if (error is ApiException) {
      // Add context to existing API exception
      return ApiException(
        error.error.copyWith(
          message: '${error.error.message} ($context)',
        ),
        error.originalMessage,
      );
    }

    // Create new API exception for other errors
    return ApiException(
      ApiError(
        message: '$context: ${error.toString()}',
        code: 'LIBRARY_ERROR',
        timestamp: DateTime.now(),
      ),
      error.toString(),
    );
  }

  /// Clean up resources
  void dispose() {
    // Cancel all timers
    for (final timer in _scanPollingTimers.values) {
      timer.cancel();
    }
    _scanPollingTimers.clear();
    
    // Close all controllers
    for (final controller in _scanProgressControllers.values) {
      controller.close();
    }
    _scanProgressControllers.clear();
  }
}

/// Mock implementation for testing
class MockLibraryApiService implements LibraryApiService {
  final List<Library> _libraries = [];
  final Map<String, ScanJob> _scanJobs = {};
  final Map<String, StreamController<ScanProgress>> _scanProgressControllers = {};

  @override
  Future<List<Library>> getLibraries() async {
    return List.from(_libraries);
  }

  @override
  Future<Library> addLibrary(CreateLibraryRequest request) async {
    final library = Library(
      id: 'mock-library-${_libraries.length + 1}',
      ownerId: 'mock-user-id',
      name: request.name,
      type: request.type,
      config: request.config,
      createdAt: DateTime.now(),
    );
    
    _libraries.add(library);
    return library;
  }

  @override
  Future<Library> getLibrary(String libraryId) async {
    final library = _libraries.firstWhere(
      (lib) => lib.id == libraryId,
      orElse: () => throw ApiException(
        ApiError(
          message: 'Library not found',
          code: 'LIBRARY_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      ),
    );
    return library;
  }

  @override
  Future<ScanJob> scanLibrary(String libraryId) async {
    // Verify library exists
    await getLibrary(libraryId);
    
    final scanJob = ScanJob(
      id: 'mock-scan-job-${_scanJobs.length + 1}',
      libraryId: libraryId,
      status: 'running',
      progress: 0,
      createdAt: DateTime.now(),
    );
    
    _scanJobs[scanJob.id] = scanJob;
    
    // Simulate scan progress
    _simulateScanProgress(scanJob);
    
    return scanJob;
  }

  @override
  Future<void> deleteLibrary(String libraryId) async {
    _libraries.removeWhere((lib) => lib.id == libraryId);
    
    // Clean up scan jobs for this library
    _scanJobs.removeWhere((_, job) => job.libraryId == libraryId);
    
    // Clean up progress controllers
    _scanProgressControllers[libraryId]?.close();
    _scanProgressControllers.remove(libraryId);
  }

  @override
  Stream<ScanProgress> watchScanProgress(String libraryId) {
    if (!_scanProgressControllers.containsKey(libraryId)) {
      _scanProgressControllers[libraryId] = StreamController<ScanProgress>.broadcast();
    }
    
    return _scanProgressControllers[libraryId]!.stream;
  }

  @override
  Future<ScanJob> getScanJob(String jobId) async {
    final scanJob = _scanJobs[jobId];
    if (scanJob == null) {
      throw ApiException(
        ApiError(
          message: 'Scan job not found',
          code: 'SCAN_JOB_NOT_FOUND',
          status: 404,
          timestamp: DateTime.now(),
        ),
      );
    }
    return scanJob;
  }

  @override
  Future<void> cancelScanJob(String jobId) async {
    final scanJob = _scanJobs[jobId];
    if (scanJob != null) {
      _scanJobs[jobId] = scanJob.copyWith(
        status: 'cancelled',
        completedAt: DateTime.now(),
      );
    }
  }

  /// Simulate scan progress for testing
  void _simulateScanProgress(ScanJob scanJob) {
    if (!_scanProgressControllers.containsKey(scanJob.libraryId)) {
      _scanProgressControllers[scanJob.libraryId] = StreamController<ScanProgress>.broadcast();
    }
    
    final controller = _scanProgressControllers[scanJob.libraryId]!;
    var currentProgress = 0;
    
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      // Check if controller is still open
      if (controller.isClosed) {
        timer.cancel();
        return;
      }
      
      currentProgress += 20;
      
      final updatedJob = scanJob.copyWith(
        progress: currentProgress,
        status: currentProgress >= 100 ? 'completed' : 'running',
        completedAt: currentProgress >= 100 ? DateTime.now() : null,
      );
      
      _scanJobs[scanJob.id] = updatedJob;
      
      try {
        controller.add(ScanProgress.fromScanJob(updatedJob));
      } catch (e) {
        // Controller might be closed, stop the timer
        timer.cancel();
        return;
      }
      
      if (currentProgress >= 100) {
        timer.cancel();
      }
    });
  }

  void dispose() {
    for (final controller in _scanProgressControllers.values) {
      controller.close();
    }
    _scanProgressControllers.clear();
  }
}