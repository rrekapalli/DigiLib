import 'dart:async';
import '../models/entities/library.dart';
import '../models/api/create_library_request.dart';
import '../models/api/scan_job.dart';
import 'library_api_service.dart';
import '../database/repositories/library_repository.dart';
import '../network/connectivity_service.dart';
import 'job_queue_service.dart';

/// Service for managing libraries with offline support
abstract class LibraryService {
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
  
  /// Refresh libraries from server
  Future<void> refreshLibraries();
  
  /// Get cached libraries (offline)
  Future<List<Library>> getCachedLibraries();
  
  /// Sync pending library operations
  Future<void> syncPendingOperations();
}

/// Implementation of LibraryService with offline support
class LibraryServiceImpl implements LibraryService {
  final LibraryApiService _apiService;
  final LibraryRepository _repository;
  final ConnectivityService _connectivityService;
  final JobQueueService _jobQueueService;

  LibraryServiceImpl(
    this._apiService,
    this._repository,
    this._connectivityService,
    this._jobQueueService,
  );

  @override
  Future<List<Library>> getLibraries() async {
    try {
      if (await _connectivityService.checkConnectivity()) {
        // Online: fetch from API and cache
        final libraries = await _apiService.getLibraries();
        
        // Cache libraries locally
        for (final library in libraries) {
          await _repository.save(library);
        }
        
        return libraries;
      } else {
        // Offline: return cached libraries
        return await getCachedLibraries();
      }
    } catch (e) {
      // Fallback to cached data on error
      return await getCachedLibraries();
    }
  }

  @override
  Future<Library> addLibrary(CreateLibraryRequest request) async {
    try {
      if (await _connectivityService.checkConnectivity()) {
        // Online: create via API
        final library = await _apiService.addLibrary(request);
        
        // Cache the new library
        await _repository.save(library);
        
        return library;
      } else {
        // Offline: queue the operation
        await _jobQueueService.addJob(
          JobType.createLibrary,
          {
            'request': request.toJson(),
          },
        );
        
        // Create a temporary library for immediate UI feedback
        final tempLibrary = Library(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          name: request.name,
          type: request.type,
          config: request.config,
          createdAt: DateTime.now(),
        );
        
        await _repository.save(tempLibrary);
        return tempLibrary;
      }
    } catch (e) {
      // Queue for retry if online operation fails
      await _jobQueueService.addJob(
        JobType.createLibrary,
        {
          'request': request.toJson(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<Library> getLibrary(String libraryId) async {
    try {
      if (await _connectivityService.checkConnectivity()) {
        // Online: fetch from API
        final library = await _apiService.getLibrary(libraryId);
        
        // Cache the library
        await _repository.save(library);
        
        return library;
      } else {
        // Offline: return cached library
        final library = await _repository.findById(libraryId);
        if (library == null) {
          throw Exception('Library not found in cache');
        }
        return library;
      }
    } catch (e) {
      // Fallback to cached data
      final library = await _repository.findById(libraryId);
      if (library == null) {
        rethrow;
      }
      return library;
    }
  }

  @override
  Future<ScanJob> scanLibrary(String libraryId) async {
    try {
      if (await _connectivityService.checkConnectivity()) {
        // Online: start scan via API
        return await _apiService.scanLibrary(libraryId);
      } else {
        // Offline: queue the scan operation
        await _jobQueueService.addJob(
          JobType.scanLibrary,
          {
            'library_id': libraryId,
          },
        );
        
        // Return a mock scan job for immediate feedback
        return ScanJob(
          id: 'queued_${DateTime.now().millisecondsSinceEpoch}',
          libraryId: libraryId,
          status: 'queued',
          progress: 0,
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      // Queue for retry
      await _jobQueueService.addJob(
        JobType.scanLibrary,
        {
          'library_id': libraryId,
        },
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteLibrary(String libraryId) async {
    try {
      if (await _connectivityService.checkConnectivity()) {
        // Online: delete via API
        await _apiService.deleteLibrary(libraryId);
        
        // Remove from local cache
        await _repository.delete(libraryId);
      } else {
        // Offline: queue the deletion
        await _jobQueueService.addJob(
          JobType.deleteLibrary,
          {
            'library_id': libraryId,
          },
        );
        
        // Mark as deleted locally (soft delete)
        final library = await _repository.findById(libraryId);
        if (library != null) {
          // In a real implementation, we might add a 'deleted' flag
          // For now, we'll remove it from cache
          await _repository.delete(libraryId);
        }
      }
    } catch (e) {
      // Queue for retry
      await _jobQueueService.addJob(
        JobType.deleteLibrary,
        {
          'library_id': libraryId,
        },
      );
      rethrow;
    }
  }

  @override
  Stream<ScanProgress> watchScanProgress(String libraryId) {
    return _apiService.watchScanProgress(libraryId);
  }

  @override
  Future<ScanJob> getScanJob(String jobId) async {
    return await _apiService.getScanJob(jobId);
  }

  @override
  Future<void> cancelScanJob(String jobId) async {
    return await _apiService.cancelScanJob(jobId);
  }

  @override
  Future<void> refreshLibraries() async {
    if (await _connectivityService.checkConnectivity()) {
      final libraries = await _apiService.getLibraries();
      
      // Update local cache
      for (final library in libraries) {
        await _repository.save(library);
      }
    }
  }

  @override
  Future<List<Library>> getCachedLibraries() async {
    return await _repository.findAll();
  }

  @override
  Future<void> syncPendingOperations() async {
    if (!await _connectivityService.checkConnectivity()) {
      return;
    }

    // Process pending library operations from job queue
    final pendingJobs = await _jobQueueService.getPendingJobs();

    for (final job in pendingJobs) {
      // Only process library-related jobs
      if (![JobType.createLibrary, JobType.deleteLibrary, JobType.scanLibrary].contains(job.type)) {
        continue;
      }
      
      try {
        switch (job.type) {
          case JobType.createLibrary:
            final requestData = job.payload['request'] as Map<String, dynamic>;
            final request = CreateLibraryRequest.fromJson(requestData);
            await _apiService.addLibrary(request);
            break;
            
          case JobType.deleteLibrary:
            final libraryId = job.payload['library_id'] as String;
            await _apiService.deleteLibrary(libraryId);
            break;
            
          case JobType.scanLibrary:
            final libraryId = job.payload['library_id'] as String;
            await _apiService.scanLibrary(libraryId);
            break;
            
          default:
            continue;
        }
        
        // Mark job as completed
        await _jobQueueService.completeJob(job.id);
        
      } catch (e) {
        // Mark job as failed
        await _jobQueueService.failJob(job.id, e.toString());
      }
    }
  }
}